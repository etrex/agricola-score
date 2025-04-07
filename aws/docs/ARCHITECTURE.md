# 農家樂計分機器人 AWS 架構

## 開發工具
- AWS CDK with JavaScript
- 使用 JavaScript 版本的 AWS CDK 來管理和部署 AWS 資源
- 利用 CDK 的 Infrastructure as Code 來維護基礎設施
- Lambda 函數使用 Ruby 開發

## 系統架構

```
LINE Platform --> API Gateway --> Lambda --> DynamoDB
                     |              |          |
                     v              v          v
                CloudWatch     CloudWatch   CloudWatch
                   Logs          Logs        Logs
```

## 元件說明

### 1. API Gateway
- 功能：提供 HTTPS 端點接收 LINE Webhook
- 設定：
  - 路徑: `/webhook`
  - 方法: POST
  - 安全性: LINE 簽名驗證
  - 流量控制: 每秒 100 請求
  - CORS: 啟用

### 2. Lambda
- 功能：處理 LINE 訊息和計分邏輯
- 規格：
  - 運行環境: Ruby 2.7
  - Lambda Layer: 管理 Ruby Gems
    - aws-sdk-dynamodb
    - line-bot-api
    - dotenv
  - 記憶體: 128MB
  - 超時: 10 秒
  - 並行執行: 預設值

### 3. DynamoDB
- 功能：儲存使用者狀態和計分紀錄
- 表格設計：
  ```
  Table: AgricolaUserStates
  - Partition Key: userId (String)
  - Sort Key: sessionId (String)
  - Attributes:
    - state (Map)         # 計分狀態
    - type (String)       # 'TEMP' 或 'SAVED'
    - score (Number)      # 分數
    - playerCount (Number)# 玩家人數
    - playerName (String) # 玩家名稱（選填）
    - createdAt (Number)  # 建立時間
    - updatedAt (Number)  # 更新時間
    - expiresAt (Number)  # TTL 時間戳（僅用於 type='TEMP' 的記錄）
  ```
- 設定：
  - 讀寫容量: On-demand
  - TTL:
    - 啟用在 expiresAt 欄位
    - 設置方式：
      - TEMP 記錄：設置 6 小時的 expiresAt
      - SAVED 記錄：不設置 expiresAt 欄位
    - 更新策略：
      - 每次使用者操作時重設 TEMP 記錄的 TTL
      - 使用 ConditionExpression 確保記錄存在
      - 如果記錄不存在，通知用戶重新開始計分
    - 資料清理：
      - DynamoDB 會自動刪除有 expiresAt 且過期的記錄
      - 因為 SAVED 記錄不設置 expiresAt，所以不會被刪除
  - GSI: 
    - UserScoreIndex (userId, createdAt) # 查詢使用者的歷史紀錄
    - SavedScoreIndex (type, createdAt) # 查詢所有永久保存的分數

## 使用者互動流程

1. 開始計分
   ```
   使用者: 「開始計分」
   機器人: 詢問玩家人數
   使用者: 輸入人數
   機器人: 開始引導計分流程
   ```

2. 計分過程
   ```
   機器人: 依序詢問各項分數
   使用者: 依序輸入分數
   機器人: 即時計算總分

   [每次使用者有任何操作時：
    1. 更新 updatedAt
    2. 重設 6 小時 TTL
    3. 如果記錄不存在，通知用戶重新開始]
   ```

3. 完成計分
   ```
   機器人: 顯示最終分數
   機器人: 詢問是否要保存分數
   使用者: 可選擇：
          1.「保存分數」- 永久保存
          2.「重新計算」- 保持臨時狀態
          3.「結束」- 放棄計分
   ```

4. 查看歷史
   ```
   使用者: 「查看歷史」
   機器人: 顯示該使用者的已保存分數
   ```

## 資料流

1. 臨時計分流程
   ```
   使用者 -> LINE -> API Gateway -> Lambda
   Lambda -> DynamoDB (寫入 TEMP 記錄，設定 TTL)
   ```

2. 保存分數流程
   ```
   使用者要求保存 -> Lambda
   Lambda -> DynamoDB (更新現有記錄)
     1. 將 type 改為 'SAVED'
     2. 移除 expiresAt 屬性
     3. 更新 updatedAt
   ```

3. 查詢歷史
   ```
   使用者查詢 -> Lambda
   Lambda -> DynamoDB (使用 GSI 查詢)
   Lambda -> LINE (返回歷史記錄)
   ```

## 監控與日誌

- CloudWatch Logs
  - API Gateway 存取日誌
  - Lambda 執行日誌
  - DynamoDB 操作日誌

## 安全性

1. API Gateway
   - LINE 簽名驗證
   - 請求限制
   - HTTPS 加密

2. Lambda
   - IAM 角色最小權限
   - 環境變數加密
   - VPC 設定 (如需要)

3. DynamoDB
   - 加密儲存
   - 存取限制

## 成本估算 (月)

1. API Gateway
   - 免費額度: 100萬次請求
   - 預估使用: < 100萬次請求
   - 成本: $0

2. Lambda
   - 免費額度: 100萬次請求
   - 預估使用: < 100萬次請求
   - 成本: $0

3. DynamoDB
   - 免費額度: 25 WCU/RCU
   - 預估使用: < 25 WCU/RCU
   - 成本: $0

總預估月成本: $0 (在免費額度內)

## 部署流程

1. 基礎設施部署 (使用 Serverless Framework)
   - API Gateway 設定
   - Lambda 函數
   - DynamoDB 表格

2. 應用程式部署
   - 程式碼打包
   - 環境變數設定
   - 部署確認

3. LINE Bot 設定
   - Webhook URL 更新
   - 功能測試

## 備份策略

1. 程式碼
   - GitHub 儲存庫

2. 資料
   - DynamoDB 時間點復原
   - 定期快照 (可選)