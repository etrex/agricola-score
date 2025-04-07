# 農家樂計分機器人開發任務清單

## 1. 基礎設置
- [x] 建立 GitHub Repository
- [x] 初始化 Ruby 專案
  - [x] 建立 'Gemfile'
  - [x] 設定 Ruby 版本
- [x] 設置 AWS CDK
  - [x] 安裝 AWS CDK CLI (`npm install -g aws-cdk`)
  - [x] 初始化 JavaScript CDK 專案 (`cdk init app --language javascript`)
  - [x] 安裝必要的 npm 套件
    - [x] `aws-cdk-lib`
    - [x] `@aws-sdk/client-dynamodb`
    - [x] `@line/bot-sdk`
  - [x] 設定 Stack 基本配置

## 2. AWS 資源設置
### API Gateway
- [x] 建立 API Gateway 設定
  - [x] 設定 `/webhook` 路徑
  - [x] 配置 POST 方法
  - [x] 設定流量限制（100 req/s）
  - [x] 配置 CORS
  - [x] 設定 LINE 簽名驗證中間件

### Lambda
- [x] 建立主要 Lambda 函數
  - [x] 設定 Ruby 2.7 運行環境
  - [x] 配置環境變數
    - [x] LINE_CHANNEL_SECRET
    - [x] LINE_CHANNEL_ACCESS_TOKEN
    - [x] DYNAMODB_TABLE
  - [x] 設定 IAM 角色和權限
  - [x] 實作 LINE 訊息處理器
  - [x] 建立 Lambda Layer 管理 Ruby Gems

### DynamoDB
- [x] 建立 AgricolaUserStates 表格
  - [x] 設定主鍵（userId + sessionId）
  - [x] 建立 GSI
    - [x] UserScoreIndex (userId, createdAt)
    - [x] SavedScoreIndex (type, createdAt)
  - [x] 配置 TTL
    - [x] 啟用 expiresAt 欄位
  - [x] 設定 On-demand 容量模式

## 3. 核心功能實作
### 計分系統
- [x] 實作開始計分功能
  - [x] 建立臨時記錄
  - [x] 設定 TTL
- [x] 實作計分過程
  - [x] 分數輸入和驗證
  - [x] 計算總分
  - [x] 更新記錄和 TTL
- [x] 實作保存功能
  - [x] 移除 expiresAt
  - [x] 更新記錄類型

### 查詢功能
- [x] 實作歷史記錄查詢
  - [x] 查詢使用者歷史分數
  - [x] 查詢所有永久保存分數
- [x] 實作分數統計
  - [x] 計算平均分數
  - [x] 顯示最高分

## 4. 安全性和監控
- [x] 設定 CloudWatch 監控
  - [x] API Gateway 日誌
  - [x] Lambda 日誌
  - [x] DynamoDB 日誌
- [x] 實作錯誤處理
  - [x] LINE 訊息處理錯誤
  - [x] DynamoDB 操作錯誤
  - [x] TTL 相關錯誤

## 5. 測試
- [x] 單元測試
  - [x] Lambda 處理器測試
  - [x] DynamoDB 操作測試
- [x] 整合測試
  - [x] LINE 訊息流程測試
  - [x] 計分流程測試
  - [x] TTL 功能測試

## 6. 部署
- [x] 設定部署流程
  - [x] 建立部署腳本
  - [x] 設定環境變數
- [x] 執行部署
  - [x] 部署到開發環境
  - [x] 部署到生產環境

## 7. 文檔
- [x] 更新 README
  - [x] 安裝說明
  - [x] 使用說明
  - [x] API 文檔
- [x] 維護文檔
  - [x] 架構說明
  - [x] 故障排除指南