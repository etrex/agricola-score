# Agricola Score Bot

農家樂計分機器人是一個基於 LINE Messaging API 的機器人，用於協助玩家記錄和追蹤農家樂桌遊的分數。

## 功能特點

- 即時計分：逐項輸入分數，自動計算總分
- 分數驗證：確保輸入分數在合理範圍內
- 歷史記錄：查看過去的遊戲分數
- 臨時保存：計分過程中自動保存，一小時內可以繼續輸入
- 永久保存：完成計分後可永久保存記錄

## 技術架構

- AWS Lambda (Ruby 2.7)
- Amazon API Gateway
- Amazon DynamoDB
- AWS CDK (JavaScript)
- LINE Messaging API

## 安裝與設置

1. 安裝必要工具：
   ```bash
   # 安裝 AWS CDK
   npm install -g aws-cdk
   
   # 安裝 Ruby 相關工具
   gem install bundler
   ```

2. 設置環境變數：
   ```bash
   # 在 AWS Systems Manager Parameter Store 中設置以下參數：
   /agricola-score/line-channel-secret
   /agricola-score/line-channel-access-token
   ```

3. 部署應用：
   ```bash
   # 開發環境
   ./deploy.sh dev
   
   # 生產環境
   ./deploy.sh prod
   ```

## 開發指南

1. 本地開發：
   ```bash
   # 安裝相依套件
   cd lambda
   bundle install
   
   # 執行測試
   bundle exec rspec
   ```

2. CDK 開發：
   ```bash
   cd cdk
   npm install
   
   # 檢視變更
   cdk diff
   ```

## 使用說明

機器人指令：
1. 開始計分 - 開始新的計分
2. [數字]分 - 輸入分數
3. 保存 - 永久保存分數
4. 查詢歷史 - 查看歷史分數
5. 說明 - 顯示說明

## 監控與維護

- CloudWatch 監控：
  - API Gateway 存取日誌
  - Lambda 函數日誌
  - DynamoDB 操作監控
- CloudWatch Alarms：
  - Lambda 錯誤
  - API Gateway 5xx 錯誤
  - DynamoDB 限流

## 貢獻指南

1. Fork 專案
2. 建立功能分支
3. 提交變更
4. 發送 Pull Request

## 授權

MIT License



## 本機測試

```
sam build
sam local start-api --env-vars env.json --docker-network host
```

```
curl -X POST \
  http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -H "x-line-signature: local-signature" \
  -d '{
    "events": [
      {
        "type": "message",
        "replyToken": "test-reply-token",
        "source": {
          "userId": "test-user-id",
          "type": "user"
        },
        "timestamp": 1612345678901,
        "message": {
          "type": "text",
          "id": "test-message-id",
          "text": "1"
        }
      }
    ]
  }'
```

## 雲端測試

```
sam sync --stack-name agricola-score --watch
```