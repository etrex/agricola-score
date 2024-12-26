/**
 * 取得 LINE Channel Access Token
 * @returns {string}
 */
function getChannelAccessToken() {
  return PropertiesService.getScriptProperties().getProperty('LINE_CHANNEL_ACCESS_TOKEN');
}

/**
 * 發送 LINE 訊息
 * @param {string} replyToken 回覆 Token
 * @param {Object[]} messages 訊息陣列
 */
function sendLineMessage(replyToken, messages) {
  const url = 'https://api.line.me/v2/bot/message/reply';
  const options = {
    'method': 'post',
    'headers': {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + getChannelAccessToken()
    },
    'payload': JSON.stringify({
      'replyToken': replyToken,
      'messages': messages
    })
  };
  
  try {
    UrlFetchApp.fetch(url, options);
  } catch (error) {
    console.error('發送 LINE 訊息失敗:', error);
    throw error;
  }
} 