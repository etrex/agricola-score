# 農家樂計算機

農家樂（Agricola）遊戲結束後，用來計算總分的 LINE Bot。

請掃描以下 QRCode 加入好友：

![](doc/qrcode.jpg)

## Screenshots

![](doc/1.png)
![](doc/2.png)

---

以下是給開發者的說明。

## 架構

單一 Rust 執行檔 + SQLite（WAL），跑在 GCP Compute Engine（e2-micro，免費額度）上。

```
LINE --HTTPS--> Caddy（自動憑證）--> agricola-score（axum, 127.0.0.1:8080）--> SQLite（WAL）
```

| 檔案 | 說明 |
|---|---|
| `src/fields.rs` | 15 個計分欄位、問題文字、輸入驗證 |
| `src/calculator.rs` | 計分表與總分計算 |
| `src/flex.rs` | LINE Flex 訊息（結果卡片、歡迎訊息） |
| `src/handler.rs` | 對話狀態機（開始、回答、修改、保存） |
| `src/store.rs` | SQLite 儲存層、DynamoDB 匯入 |
| `src/line.rs` | LINE 簽章驗證與 reply API |
| `src/main.rs` | HTTP 伺服器（`/webhook`、`/healthz`）與命令列 |
| `deploy/` | VM 部署：`install.sh`、systemd 服務、Caddyfile、每日備份 |
| `docs/` | 服務介紹網站（GitHub Pages，`agricola.kamigo.tw`） |

## 環境變數

| 名稱 | 說明 | 預設 |
|---|---|---|
| `LINE_CHANNEL_SECRET` | 必填 | |
| `LINE_CHANNEL_ACCESS_TOKEN` | 必填 | |
| `DB_PATH` | SQLite 檔案 | `agricola.db` |
| `BIND_ADDR` | 監聽位址 | `127.0.0.1:8080` |
| `LINE_API_BASE` | 測試時指向假的 LINE API | `https://api.line.me` |

## 開發

```sh
cargo test                                  # 單元測試
LINE_CHANNEL_SECRET=x LINE_CHANNEL_ACCESS_TOKEN=y cargo run -- serve
cargo run -- import-dynamodb scan.json      # 匯入 `aws dynamodb scan` 的輸出
echo '{...}' | cargo run -- calc            # 除錯：由答案算出 Flex 訊息
```

> `cargo test --release` 會因 `panic = "abort"` 而編譯失敗，請用 `cargo test`。

## 資料表

```sql
scores(user_id, session_id, state /*JSON*/, updated_at, expires_at /*NULL=永久*/, type /*TEMP|SAVED*/)
PRIMARY KEY (user_id, session_id)
```

`session_id = 'current'` 是使用者目前的對話狀態（24 小時過期，每小時清除一次），
其餘是保存的分數（以時間戳為 id）。`state` 的 JSON 格式與舊的 DynamoDB 版相同。

## 編譯與部署

VM 是 x86_64 Linux（Debian 12），在本機（例如 Apple Silicon）用 Docker 編譯：

```sh
docker run --rm --platform linux/amd64 \
  -v "$PWD":/work -w /work \
  -v agricola-cargo-registry:/usr/local/cargo/registry \
  -e CARGO_TARGET_DIR=/work/target-linux-amd64 \
  rust:1-bookworm cargo build --release
# 產出：target-linux-amd64/release/agricola-score
```

VM 只開放 80/443；SSH 只能經由 Google IAP：

```sh
gcloud compute scp --tunnel-through-iap --zone=us-west1-b --project=etrex-claude \
  target-linux-amd64/release/agricola-score agricola-score:~/agricola-score.bin
gcloud compute ssh --tunnel-through-iap --zone=us-west1-b --project=etrex-claude agricola-score \
  --command='sudo install -m 755 ~/agricola-score.bin /usr/local/bin/agricola-score && sudo systemctl restart agricola-score'
```

第一次安裝（建立使用者、systemd 服務、Caddy、備份）請看 `deploy/install.sh` 檔頭說明。

- Webhook：`https://agricola-bot.kamigo.tw/webhook`
- 備份：每日一份在 VM 的 `/var/backups/agricola-score/`，保留 14 份（`deploy/backup.sh`）

## 與舊版（AWS Lambda + Ruby）行為上的差異

- 房型驗證沿用原版（只要訊息「包含」木屋／磚屋／石屋就通過）。原版遇到不是剛好三種的房型字串、
  或房間數 ≥ 15 時會丟例外而 500；現在房間數用公式計算（磚屋 n、石屋 2n），未知房型不計分。
- 已過期但尚未清掉的暫存狀態視為不存在（舊版 DynamoDB 仍會讀到）。
- 其餘行為以 400 組隨機輸入與舊版 `Calculator` 比對，Flex 訊息 JSON 完全一致。
- 「推薦給好友」按鈕在舊版就沒有處理（會被當成目前問題的答案而無效），維持原樣。

舊的 AWS / GAS / Node（Bottender）實作已移除，仍可從 git 歷史找回（`9603ec2` 為最後一個包含它們的 commit）。
