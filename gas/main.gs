/**
 * 處理 OPTIONS 請求（CORS 預檢請求）
 * @returns {Object}
 */
function doOptions() {
  return ContentService.createTextOutput('')
    .setMimeType(ContentService.MimeType.TEXT)
    .setHeader('Access-Control-Allow-Origin', '*')
    .setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    .setHeader('Access-Control-Allow-Headers', 'Content-Type')
    .setHeader('Access-Control-Max-Age', '86400');
}

/**
 * 處理 POST 請求
 * @param {Object} e 請求事件物件
 * @returns {Object}
 */
function doPost(e) {
  // 設定 CORS 標頭
  const output = ContentService.createTextOutput();
  output.setMimeType(ContentService.MimeType.JSON);
  output.setHeader('Access-Control-Allow-Origin', '*');
  
  try {
    // 解析請求內容
    const data = JSON.parse(e.postData.contents);
    const event = data.events[0];
    
    // 只處理文字訊息
    if (event.type !== 'message' || event.message.type !== 'text') {
      return output.setContent(JSON.stringify({ success: true }));
    }

    const userId = event.source.userId;
    const message = event.message.text;
    
    // 取得使用者狀態
    const state = getState(userId);
    
    // 處理訊息
    const response = handleMessage(state, message, userId);
    
    // 發送 LINE 訊息
    if (event.replyToken !== 'test-reply-token') {
      sendLineMessage(event.replyToken, [response]);
      return output.setContent(JSON.stringify({ success: true }));
    } else {
      // 測試模式：直接回傳訊息內容
      return output.setContent(JSON.stringify({
        success: true,
        messages: [response]
      }));
    }
  } catch (error) {
    console.error('處理請求失敗:', error);
    return output.setContent(JSON.stringify({ error: error.message }));
  }
}

/**
 * 處理使用者訊息
 * @param {Object} state 使用者狀態
 * @param {string} message 使用者訊息
 * @param {string} userId 使用者 ID
 * @returns {Object} LINE 訊息物件
 */
function handleMessage(state, message, userId) {
  // 如果是新的對話或重新開始
  if (message === '開始計分' || !state.form.waitingFor) {
    state.form = {
      path: null,
      params: {},
      waitingFor: fields[0].key
    };
    setState(userId, state);
    return fields[0].prompt();
  }
  
  // 驗證當前問題的答案
  const currentField = fields.find(f => f.key === state.form.waitingFor);
  if (currentField && currentField.validate(message)) {
    // 儲存答案
    state.form.params[currentField.key] = message;
    
    // 找下一個問題
    const currentIndex = fields.findIndex(f => f.key === state.form.waitingFor);
    if (currentIndex >= fields.length - 1) {
      // 所有問題都回答完了，計算結果
      const result = calculateResult(state.form.params);
      clearState(userId);
      return result;
    }
    
    // 進入下一個問題
    state.form.waitingFor = fields[currentIndex + 1].key;
    setState(userId, state);
    return fields[currentIndex + 1].prompt();
  }
  
  // 答案無效，重新問同一個問題
  return currentField.prompt();
}

/**
 * 處理 GET 請求（用於 JSONP）
 */
function doGet(e) {
  const output = ContentService.createTextOutput();
  output.setMimeType(ContentService.MimeType.JAVASCRIPT);
  
  try {
    if (!e.parameter.payload) {
      throw new Error('No payload provided');
    }
    
    const data = JSON.parse(e.parameter.payload);
    const event = data.events[0];
    
    // 只處理文字訊息
    if (event.type !== 'message' || event.message.type !== 'text') {
      const response = { success: true };
      return output.setContent(`${e.parameter.callback}(${JSON.stringify(response)})`);
    }

    const userId = event.source.userId;
    const message = event.message.text;
    
    // 取得使用者狀態
    const state = getState(userId);
    
    // 處理訊息
    const response = handleMessage(state, message, userId);
    
    // 測試模式回傳
    const result = {
      success: true,
      messages: [response]
    };
    
    return output.setContent(`${e.parameter.callback}(${JSON.stringify(result)})`);
  } catch (error) {
    console.error('處理請求失敗:', error);
    const errorResponse = { error: error.message };
    return output.setContent(`${e.parameter.callback}(${JSON.stringify(errorResponse)})`);
  }
} 