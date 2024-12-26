# 農家樂計分機器人 (Google Apps Script 版本)

這是農家樂計分機器人的 Google Apps Script 實作版本。

## 檔案結構

```
Field.gs      - Field 類別定義
Fields.gs     - 遊戲欄位定義
Cache.gs      - Cache Service 相關功能
Line.gs       - LINE API 相關功能
Calculator.gs - 分數計算邏輯
Flex.gs       - Flex Message 生成器
Main.gs       - 主要的程式進入點
```

## 部署步驟

1. 在 Google Apps Script 建立新專案
2. 建立上述 .gs 檔案，並複製對應的程式碼
3. 設定專案屬性：
   - LINE_CHANNEL_ACCESS_TOKEN
   - LINE_CHANNEL_SECRET
4. 部署為網頁應用程式：
   - 點擊「部署」>「新增部署作業」
   - 選擇「網頁應用程式」
   - 執行身分：「以我的身分執行」
   - 存取權：「任何人」
5. 在 LINE Developer Console 設定 Webhook URL

## 注意事項

- 確保已開啟必要的 Google Apps Script 服務
- Cache 服務的資料會在 6 小時後過期
- 所有檔案共享同一個全域範圍
- 每次修改程式碼後需要重新部署 