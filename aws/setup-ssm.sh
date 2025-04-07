#!/bin/bash
set -e

# 定義參數名稱
SECRET_PARAM="/agricola-score/line-channel-secret"
TOKEN_PARAM="/agricola-score/line-channel-access-token"

# 函數：從 SSM 取得參數
get_parameter() {
  local param_name=$1
  aws ssm get-parameter \
    --name "$param_name" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text 2>/dev/null || echo ""
}

# 取得目前的設定
current_secret=$(get_parameter "$SECRET_PARAM")
current_token=$(get_parameter "$TOKEN_PARAM")

echo "目前的 LINE Bot 設定："
if [ -n "$current_secret" ] && [ -n "$current_token" ]; then
  echo "Channel Secret: ${current_secret:0:5}..."
  echo "Channel Access Token: ${current_token:0:5}..."
else
  echo "尚未設定"
fi

echo
echo -n "是否要修改設定？(y/n) "
read -r should_modify

if [ "$should_modify" != "y" ]; then
  echo "保持目前設定"
  exit 0
fi

# 讀取新的設定
echo
echo "請輸入新的設定："

# 讀取 Channel Secret
echo -n "Channel Secret [保持原值請直接按 Enter]: "
read -r channel_secret
channel_secret=${channel_secret:-$current_secret}

if [ -z "$channel_secret" ]; then
  echo "Error: Channel Secret 不能為空"
  exit 1
fi

# 讀取 Channel Access Token
echo -n "Channel Access Token [保持原值請直接按 Enter]: "
read -r channel_token
channel_token=${channel_token:-$current_token}

if [ -z "$channel_token" ]; then
  echo "Error: Channel Access Token 不能為空"
  exit 1
fi

# 確認新設定
echo
echo "新的設定："
echo "Channel Secret: ${channel_secret:0:5}..."
echo "Channel Access Token: ${channel_token:0:5}..."
echo

echo -n "確認儲存這些設定到 AWS SSM Parameter Store? (y/n) "
read -r confirm

if [ "$confirm" != "y" ]; then
  echo "取消儲存設定"
  exit 1
fi

# 儲存到 SSM Parameter Store
echo "正在儲存到 SSM Parameter Store..."

aws ssm put-parameter \
  --name "$SECRET_PARAM" \
  --value "$channel_secret" \
  --type "SecureString" \
  --overwrite

aws ssm put-parameter \
  --name "$TOKEN_PARAM" \
  --value "$channel_token" \
  --type "SecureString" \
  --overwrite

echo "✅ 成功儲存 LINE Bot 設定到 SSM Parameter Store"