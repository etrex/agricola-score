# 農家樂計分機器人（Rust 版）

把原本 AWS Lambda（Ruby）+ DynamoDB 的 LINE Bot 改寫成單一 Rust 執行檔 + SQLite（WAL），
跑在 GCP Compute Engine（e2-micro，免費額度）上。

## 架構

```
LINE --HTTPS--> Caddy（自動憑證）--> agricola-score（axum, 127.0.0.1:8080）--> SQLite（WAL）
```

| 檔案 | 對應原本的 Ruby |
|---|---|
| `src/fields.rs` | `aws/lambda/fields.rb` |
| `src/calculator.rs` | `aws/lambda/calculator.rb` |
| `src/flex.rs` | `aws/lambda/flex.rb`、`greeting` |
| `src/handler.rs` | `aws/lambda/message_handler.rb`、`test_handler.rb` |
| `src/store.rs` | DynamoDB `agricola-score` 資料表 |
| `src/line.rs` | LINE 簽章驗證與 reply |

`score_processor.rb`、`score_categories.rb`、`error_handler.rb` 在原版沒有被任何程式引用（死碼），沒有移植。

## 環境變數

| 名稱 | 說明 | 預設 |
|---|---|---|
| `LINE_CHANNEL_SECRET` | 必填 | |
| `LINE_CHANNEL_ACCESS_TOKEN` | 必填 | |
| `DB_PATH` | SQLite 檔案 | `agricola.db` |
| `BIND_ADDR` | 監聽位址 | `127.0.0.1:8080` |
| `LINE_API_BASE` | 測試時指向假的 LINE API | `https://api.line.me` |

## 指令

```sh
cargo test                                        # 單元測試
cargo run -- serve                                # 啟動伺服器（/webhook, /healthz）
cargo run -- import-dynamodb scan.json            # 匯入 `aws dynamodb scan` 的輸出
echo '{...}' | cargo run -- calc                  # 除錯：由答案算出 Flex 訊息
```

## 資料表

```sql
scores(user_id, session_id, state /*JSON*/, updated_at, expires_at /*NULL=永久*/, type /*TEMP|SAVED*/)
PRIMARY KEY (user_id, session_id)
```

`session_id = 'current'` 是使用者目前的對話狀態（24 小時過期），其餘是保存的分數（以時間戳為 id）。
`state` 的 JSON 格式與 DynamoDB 版完全相同，所以舊資料可直接匯入。
DynamoDB 的 TTL 改成：讀取時忽略已過期資料，並每小時清除一次。

## 與 Ruby 版行為上的差異

- 房型驗證沿用原版（只要訊息「包含」木屋／磚屋／石屋就通過）。原版遇到不是剛好三種的房型字串、
  或房間數 ≥ 15 時會丟例外而 500；Rust 版房間數用公式計算（磚屋 n、石屋 2n），未知房型不計分。
- 已過期但 DynamoDB 尚未清掉的暫存狀態，原版仍會讀到；Rust 版視為不存在。
- 其餘行為以 400 組隨機輸入與原版 `Calculator` 比對，Flex 訊息 JSON 完全一致。

## 部署

見 `deploy/`：`install.sh`（在 VM 上執行）、`agricola-score.service`、`Caddyfile`、`backup.sh`（每日備份，保留 14 份）。
