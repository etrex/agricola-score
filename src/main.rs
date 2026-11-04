mod calculator;
mod fields;
mod flex;
mod handler;
mod line;
mod store;

use std::io::Read;
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use axum::body::Bytes;
use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde_json::{json, Value};

use store::Store;

struct App {
    store: Store,
    channel_secret: String,
    access_token: String,
    api_base: String,
}

fn now() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs() as i64).unwrap_or(0)
}

fn env(name: &str) -> Option<String> {
    std::env::var(name).ok().filter(|v| !v.is_empty())
}

fn db_path() -> String {
    env("DB_PATH").unwrap_or_else(|| "agricola.db".to_string())
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(String::as_str) {
        None | Some("serve") => serve().await,
        Some("import-dynamodb") => import(args.get(2)),
        Some("calc") => calc_from_stdin(),
        Some(other) => {
            eprintln!("用法: agricola-score [serve | import-dynamodb <scan.json> | calc]\n不認得的指令: {other}");
            std::process::exit(2);
        }
    }
}

/// 匯入 `aws dynamodb scan` 的輸出
fn import(path: Option<&String>) {
    let Some(path) = path else {
        eprintln!("用法: agricola-score import-dynamodb <scan.json>");
        std::process::exit(2);
    };
    let json = std::fs::read_to_string(path).unwrap_or_else(|e| fail(&format!("讀不到 {path}: {e}")));
    let store = Store::open(db_path()).unwrap_or_else(|e| fail(&format!("開不了資料庫: {e}")));
    match store.import_dynamodb_json(&json, now()) {
        Ok((imported, skipped)) => println!("匯入 {imported} 筆，略過 {skipped} 筆；資料庫目前共 {} 筆", store.count().unwrap_or(-1)),
        Err(e) => fail(&format!("匯入失敗: {e}")),
    }
}

/// 除錯用：stdin 讀 params JSON，輸出 Flex 訊息（拿來跟 Ruby 原版做差異比對）
fn calc_from_stdin() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).expect("read stdin");
    let params: Value = serde_json::from_str(&input).unwrap_or_else(|e| fail(&format!("JSON 格式錯誤: {e}")));
    let map = params.as_object().cloned().unwrap_or_else(|| fail("params 必須是 JSON object"));
    println!("{}", calculator::calculate_result(&map));
}

fn fail(msg: &str) -> ! {
    eprintln!("{msg}");
    std::process::exit(1)
}

async fn serve() {
    let channel_secret = env("LINE_CHANNEL_SECRET").unwrap_or_else(|| fail("缺少環境變數 LINE_CHANNEL_SECRET"));
    let access_token = env("LINE_CHANNEL_ACCESS_TOKEN").unwrap_or_else(|| fail("缺少環境變數 LINE_CHANNEL_ACCESS_TOKEN"));
    let api_base = env("LINE_API_BASE").unwrap_or_else(|| "https://api.line.me".to_string());
    let bind = env("BIND_ADDR").unwrap_or_else(|| "127.0.0.1:8080".to_string());

    let store = Store::open(db_path()).unwrap_or_else(|e| fail(&format!("開不了資料庫: {e}")));
    let app = Arc::new(App { store, channel_secret, access_token, api_base });

    // 取代 DynamoDB TTL：每小時清掉過期的暫存資料
    let purger = app.clone();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(Duration::from_secs(3600));
        loop {
            tick.tick().await;
            let p = purger.clone();
            let _ = tokio::task::spawn_blocking(move || match p.store.purge_expired(now()) {
                Ok(n) if n > 0 => println!("purged {n} expired rows"),
                Ok(_) => {}
                Err(e) => eprintln!("purge error: {e}"),
            })
            .await;
        }
    });

    let router = Router::new()
        .route("/", post(webhook))
        .route("/webhook", post(webhook))
        .route("/healthz", get(|| async { "ok" }))
        .with_state(app);

    let listener = tokio::net::TcpListener::bind(&bind).await.unwrap_or_else(|e| fail(&format!("無法監聽 {bind}: {e}")));
    println!("listening on {bind}");
    axum::serve(listener, router)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .unwrap_or_else(|e| fail(&format!("server error: {e}")));
}

async fn shutdown_signal() {
    use tokio::signal::unix::{signal, SignalKind};
    let mut term = signal(SignalKind::terminate()).expect("SIGTERM handler");
    tokio::select! {
        _ = tokio::signal::ctrl_c() => {},
        _ = term.recv() => {},
    }
    println!("shutting down");
}

async fn webhook(State(app): State<Arc<App>>, headers: HeaderMap, body: Bytes) -> (StatusCode, Json<Value>) {
    let signature = headers.get("x-line-signature").and_then(|v| v.to_str().ok()).unwrap_or("");
    if !line::verify_signature(&app.channel_secret, &body, signature) {
        return (StatusCode::BAD_REQUEST, Json(json!({ "message": "Invalid signature" })));
    }

    let a = app.clone();
    match tokio::task::spawn_blocking(move || process_events(&a, &body)).await {
        Ok(Ok(())) => (StatusCode::OK, Json(json!({ "message": "OK" }))),
        Ok(Err(e)) => {
            eprintln!("Error processing request: {e}");
            (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "message": "Error processing request", "error": e })))
        }
        Err(e) => {
            eprintln!("Task failed: {e}");
            (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "message": "Error processing request" })))
        }
    }
}

fn process_events(app: &App, body: &[u8]) -> Result<(), String> {
    let doc: Value = serde_json::from_slice(body).map_err(|e| format!("invalid JSON: {e}"))?;
    let events = doc.get("events").and_then(Value::as_array).ok_or("missing events")?;
    for ev in events {
        if ev["type"] != "message" || ev["message"]["type"] != "text" {
            continue;
        }
        let (Some(user_id), Some(text)) = (ev["source"]["userId"].as_str(), ev["message"]["text"].as_str()) else {
            continue;
        };
        let Some(reply_token) = ev["replyToken"].as_str() else {
            continue;
        };
        let response = handler::handle(&app.store, user_id, text, now());
        line::reply(&app.api_base, &app.access_token, reply_token, &response)?;
    }
    Ok(())
}
