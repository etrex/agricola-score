#!/bin/bash

# 您的 Webhook URL
WEBHOOK_URL="您的 GAS Webhook URL"

# 測試訊息
generate_test_payload() {
  cat << EOF
{
  "events": [{
    "type": "message",
    "replyToken": "test-reply-token",
    "source": {
      "userId": "test-user-id",
      "type": "user"
    },
    "message": {
      "type": "text",
      "text": "$1"
    }
  }]
}
EOF
}

# 發送測試請求
send_test_message() {
  local payload=$(generate_test_payload "$1")
  
  curl -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

# 測試案例
echo "測試開始計分..."
send_test_message "開始計分"

echo -e "\n等待 3 秒..."
sleep 3

echo "測試回答問題..."
send_test_message "2" 