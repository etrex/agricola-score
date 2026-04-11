#!/bin/bash
set -e

STACK_NAME="agricola-score"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 檢查必要的工具
command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed. Aborting." >&2; exit 1; }
command -v bundle >/dev/null 2>&1 || { echo "bundler is required but not installed. Aborting." >&2; exit 1; }

echo "Starting deployment..."

# 安裝 Ruby 依賴
echo "Installing Ruby dependencies..."
cd "$SCRIPT_DIR/lambda"
bundle config set --local deployment 'true'
bundle install --quiet
if [ $? -ne 0 ]; then
  echo "Failed to install Ruby dependencies"
  exit 1
fi

# 安裝 Node.js 依賴
echo "Installing Node.js dependencies..."
cd "$SCRIPT_DIR/cdk"
npm install --quiet
if [ $? -ne 0 ]; then
  echo "Failed to install Node.js dependencies"
  exit 1
fi

# 部署 CDK stack 並保存輸出
echo "Deploying stack $STACK_NAME..."
npx cdk deploy $STACK_NAME \
  --require-approval never \
  --outputs-file "$SCRIPT_DIR/cdk/outputs.json"

if [ $? -eq 0 ]; then
  echo "✅ Deployment completed successfully!"

  # 顯示輸出資訊
  if [ -f "$SCRIPT_DIR/cdk/outputs.json" ]; then
    echo "Stack outputs:"
    cat "$SCRIPT_DIR/cdk/outputs.json"
  fi

  # 取得 Function URL
  FUNCTION_URL=$(aws lambda get-function-url-config --function-name agricola-score-webhook-handler --query 'FunctionUrl' --output text 2>/dev/null)
  if [ -n "$FUNCTION_URL" ]; then
    echo
    echo "LINE Bot Webhook URL: $FUNCTION_URL"
    echo "請將此 URL 設定到 LINE Developers Console 的 Webhook URL 欄位"
  fi

  echo
  echo "⚠️  請測試以下項目："
  echo "1. 在 LINE Developers Console 設定 Webhook URL"
  echo "2. 使用「Verify」按鈕測試 Webhook"
  echo "3. 開啟「Use webhook」選項"
  echo "4. 在 LINE 中傳送「幫我算分數」測試機器人"
  echo "5. 檢查 CloudWatch 日誌"
else
  echo "❌ Deployment failed"
  exit 1
fi
