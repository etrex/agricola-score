//! SQLite（WAL）儲存層，取代 DynamoDB 的 agricola-score 資料表。
//!
//! 欄位對應：
//!   userId -> user_id, sessionId -> session_id, state -> state（JSON 字串）,
//!   updatedAt -> updated_at, expiresAt -> expires_at（NULL = 永久）, type -> type
//! 目前的使用者狀態存在 session_id = 'current'，保存的分數 session_id = 時間戳。

use std::path::Path;
use std::sync::{Mutex, MutexGuard};

use rusqlite::{params, Connection, OptionalExtension};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

/// 暫存狀態保留 24 小時（同原版）
pub const TEMP_TTL_SECS: i64 = 24 * 60 * 60;
pub const CURRENT: &str = "current";

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
pub struct Form {
    #[serde(default)]
    pub params: Map<String, Value>,
    #[serde(rename = "waitingFor", default)]
    pub waiting_for: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
pub struct State {
    #[serde(default)]
    pub form: Form,
    #[serde(rename = "userId", default, skip_serializing_if = "Option::is_none")]
    pub user_id: Option<String>,
}

pub struct Store {
    conn: Mutex<Connection>,
}

impl Store {
    pub fn open(path: impl AsRef<Path>) -> rusqlite::Result<Self> {
        Self::init(Connection::open(path)?)
    }

    #[cfg(test)]
    pub fn open_in_memory() -> rusqlite::Result<Self> {
        Self::init(Connection::open_in_memory()?)
    }

    fn init(conn: Connection) -> rusqlite::Result<Self> {
        // journal_mode 會回傳一列結果，所以用 query_row
        let _mode: String = conn.query_row("PRAGMA journal_mode = WAL", [], |r| r.get(0))?;
        conn.execute_batch(
            "PRAGMA synchronous = NORMAL;
             PRAGMA busy_timeout = 5000;
             CREATE TABLE IF NOT EXISTS scores (
                 user_id    TEXT    NOT NULL,
                 session_id TEXT    NOT NULL,
                 state      TEXT    NOT NULL,
                 updated_at INTEGER NOT NULL,
                 expires_at INTEGER,
                 type       TEXT    NOT NULL,
                 PRIMARY KEY (user_id, session_id)
             ) WITHOUT ROWID;
             CREATE INDEX IF NOT EXISTS scores_expires_at
                 ON scores (expires_at) WHERE expires_at IS NOT NULL;",
        )?;
        Ok(Store { conn: Mutex::new(conn) })
    }

    fn conn(&self) -> MutexGuard<'_, Connection> {
        self.conn.lock().unwrap_or_else(|e| e.into_inner())
    }

    /// 讀取使用者目前的狀態；不存在或已過期則回傳 None。
    pub fn get_state(&self, user_id: &str, now: i64) -> Result<Option<State>, String> {
        let row: Option<(String, Option<i64>)> = self
            .conn()
            .query_row(
                "SELECT state, expires_at FROM scores WHERE user_id = ?1 AND session_id = ?2",
                params![user_id, CURRENT],
                |r| Ok((r.get(0)?, r.get(1)?)),
            )
            .optional()
            .map_err(|e| e.to_string())?;
        match row {
            Some((_, Some(exp))) if exp <= now => Ok(None),
            Some((json, _)) => serde_json::from_str(&json).map(Some).map_err(|e| e.to_string()),
            None => Ok(None),
        }
    }

    pub fn save_state(&self, user_id: &str, state: &State, now: i64) -> Result<(), String> {
        let json = serde_json::to_string(state).map_err(|e| e.to_string())?;
        self.conn()
            .execute(
                "INSERT INTO scores (user_id, session_id, state, updated_at, expires_at, type)
                 VALUES (?1, ?2, ?3, ?4, ?5, 'TEMP')
                 ON CONFLICT (user_id, session_id) DO UPDATE SET
                     state = excluded.state, updated_at = excluded.updated_at,
                     expires_at = excluded.expires_at, type = 'TEMP'",
                params![user_id, CURRENT, json, now, now + TEMP_TTL_SECS],
            )
            .map(|_| ())
            .map_err(|e| e.to_string())
    }

    /// 永久保存一筆分數（session_id = 時間戳，同一秒重複保存會覆蓋，同原版）
    pub fn save_score(&self, user_id: &str, state: &State, now: i64) -> Result<(), String> {
        let json = serde_json::to_string(state).map_err(|e| e.to_string())?;
        self.conn()
            .execute(
                "INSERT OR REPLACE INTO scores (user_id, session_id, state, updated_at, expires_at, type)
                 VALUES (?1, ?2, ?3, ?4, NULL, 'SAVED')",
                params![user_id, now.to_string(), json, now],
            )
            .map(|_| ())
            .map_err(|e| e.to_string())
    }

    /// 取代 DynamoDB TTL：刪除已過期的暫存資料
    pub fn purge_expired(&self, now: i64) -> Result<usize, String> {
        self.conn()
            .execute("DELETE FROM scores WHERE expires_at IS NOT NULL AND expires_at <= ?1", params![now])
            .map_err(|e| e.to_string())
    }

    pub fn count(&self) -> Result<i64, String> {
        self.conn()
            .query_row("SELECT COUNT(*) FROM scores", [], |r| r.get(0))
            .map_err(|e| e.to_string())
    }

    /// 匯入 `aws dynamodb scan` 輸出的 JSON。回傳 (匯入筆數, 略過筆數)。
    pub fn import_dynamodb_json(&self, json: &str, now: i64) -> Result<(usize, usize), String> {
        let doc: Value = serde_json::from_str(json).map_err(|e| e.to_string())?;
        let items = doc.get("Items").and_then(Value::as_array).ok_or("找不到 Items 陣列")?;
        let (mut imported, mut skipped) = (0, 0);
        let mut conn = self.conn();
        let tx = conn.transaction().map_err(|e| e.to_string())?;
        for item in items {
            let s = |k: &str| item.get(k).and_then(|v| v.get("S")).and_then(Value::as_str);
            let n = |k: &str| {
                item.get(k)
                    .and_then(|v| v.get("N"))
                    .and_then(Value::as_str)
                    .and_then(|x| x.parse::<i64>().ok())
            };
            let (Some(user), Some(session), Some(state)) = (s("userId"), s("sessionId"), s("state")) else {
                skipped += 1;
                continue;
            };
            tx.execute(
                "INSERT OR REPLACE INTO scores (user_id, session_id, state, updated_at, expires_at, type)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
                params![user, session, state, n("updatedAt").unwrap_or(now), n("expiresAt"), s("type").unwrap_or("TEMP")],
            )
            .map_err(|e| e.to_string())?;
            imported += 1;
        }
        tx.commit().map_err(|e| e.to_string())?;
        Ok((imported, skipped))
    }
}
