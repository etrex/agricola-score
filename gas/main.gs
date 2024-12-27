/**
 * 處理 OPTIONS 請求（CORS 預檢請求）
 * @returns {Object}
 */
function doOptions() {
  return createCorsResponse('').setMimeType(ContentService.MimeType.TEXT);
}

/**
 * 建立帶有 CORS 標頭的回應
 * @param {string} content 回應內容
 * @param {string} [mimeType=JSON] 回應的 MIME 類型
 * @returns {Object} 回應物件
 */
function createCorsResponse(content, mimeType = ContentService.MimeType.JSON) {
  return ContentService.createTextOutput(content)
    .setMimeType(mimeType)
    .setHeader('Access-Control-Allow-Origin', '*')
    .setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    .setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

/**
 * 建立 JSONP 回應
 * @param {Object} data 回應資料
 * @param {string} callback 回調函數名稱
 * @returns {Object} 回應物件
 */
function createJsonpResponse(data, callback) {
  return ContentService.createTextOutput()
    .setMimeType(ContentService.MimeType.JAVASCRIPT)
    .setContent(`${callback}(${JSON.stringify(data)})`);
}

/**
 * 解析 LINE 事件
 * @param {string} contents 請求內容
 * @returns {Object} LINE 事件物件
 */
function parseLineEvent(contents) {
  const data = JSON.parse(contents);
  if (!data.events || !data.events[0]) {
    throw new Error('Invalid LINE event format');
  }
  return data.events[0];
}

/**
 * 建立按鈕
 * @param {string} text 按鈕文字
 * @returns {Object} 按鈕物件
 */
function button(text) {
  return {
    type: 'button',
    action: {
      type: 'message',
      label: text,
      text: text,
    },
    style: 'primary',
    color: '#225588',
    margin: 'md',
  };
}

/**
 * 建立歡迎訊息
 * @returns {Object} Flex Message 物件
 */
function greeting() {
  const text = '歡迎來到農家樂分數計算機，請點擊按鈕開始算分數：';
  const bubble = {
    type: 'bubble',
    body: {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'text',
          text: text,
          wrap: true,
        },
        button('幫我算分數'),
        button('推薦給好友'),
      ],
    },
  };
  return {
    type: 'flex',
    altText: text,
    contents: bubble
  };
}

/**
 * 處理訊息並產生回應
 * @param {Object} event LINE 事件物件
 * @returns {Object} 處理結果
 */
function processMessage(event) {
  // 處理 follow/join 事件
  if (event.type === 'follow' || event.type === 'join') {
    if (event.replyToken !== 'test-reply-token') {
      sendLineMessage(event.replyToken, [greeting()]);
      return { success: true };
    } else {
      return {
        success: true,
        messages: [greeting()]
      };
    }
  }

  // 只處理文字訊息
  if (event.type !== 'message' || event.message.type !== 'text') {
    console.log('Non-text message received');
    return { success: true };
  }

  const userId = event.source.userId;
  const message = event.message.text;
  
  // 取得使用者狀態
  const state = getState(userId);
  console.log('User state:', state);
  
  // 處理訊息
  const response = handleMessage(state, message, userId);
  console.log('Handler response:', response);
  
  // 根據是否為測試模式返回不同結果
  if (event.replyToken !== 'test-reply-token') {
    sendLineMessage(event.replyToken, [response]);
    return { success: true };
  } else {
    return {
      success: true,
      messages: [response]
    };
  }
}

/**
 * 處理錯誤並產生錯誤回應
 * @param {Error} error 錯誤物件
 * @param {boolean} isJsonP 是否為 JSONP 回應
 * @param {string} [callback] JSONP 回調函數名稱
 * @returns {Object} 錯誤回應
 */
function handleError(error, isJsonP, callback) {
  console.error('處理請求失敗:', error.stack);
  const errorResponse = { 
    error: error.message,
    stack: error.stack
  };
  
  return isJsonP
    ? createJsonpResponse(errorResponse, callback)
    : createCorsResponse(JSON.stringify(errorResponse));
}

/**
 * 處理 POST 請求
 * @param {Object} e 請求事件物件
 * @returns {Object}
 */
function doPost(e) {
  console.log('Received POST data:', e.postData.contents);
  const event = parseLineEvent(e.postData.contents);
  try {    
    const result = processMessage(event);
    return createCorsResponse(JSON.stringify(result));
  } catch (error) {
    sendLineMessage(event.replyToken, [
      {type: "text", text: error.message},
      {type: "text", text: error.stack}
    ]);
    return handleError(error, false);
  }
}

/**
 * 處理 GET 請求（用於 JSONP）
 */
function doGet(e) {
  try {
    if (!e.parameter.payload) {
      throw new Error('No payload provided');
    }
    
    const event = parseLineEvent(e.parameter.payload);
    const result = processMessage(event);
    return createJsonpResponse(result, e.parameter.callback);
  } catch (error) {
    return handleError(error, true, e.parameter.callback);
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
  // 初始化 state.form 如果不存在
  state.form = state.form || { params: {} };

  // 如果是一般訊息，也顯示歡迎訊息
  if (message === '*') {
    return greeting();
  }

  // 如果是推薦給好友的請求
  if (message === '推薦給好友') {
    return greeting();
  }

  // 如果是修改特定欄位的請求
  const fieldUpdateValidator = /玩家數|田數|柵欄圈地數|小麥數|蔬菜數|羊數|豬數|牛數|空地數|柵欄圈地內馬廄數|房間數|房間類型|人口數|乞討卡|主要發展卡的的總得分|職業卡和次要發展卡的總得分/;
  if (fieldUpdateValidator.test(message)) {
    const field = fields.find(f => f.name === message);
    if (field) {
      // 清除該欄位的值
      delete state.form.params[field.key];
      // 設定下一個要等待輸入的欄位
      state.form.waitingFor = field.key;
      setState(userId, state);
      return field.prompt();
    }
  }

  // 如果是新的對話或重新開始
  if (message === '幫我算分數' || !state.form.waitingFor) {
    state.form = {
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
    
    // 如果所有欄位都已填寫，顯示結果
    if (Object.keys(state.form.params).length === fields.length) {
      const result = calculateResult(state.form.params);
      setState(userId, state);
      return result;
    }
    
    // 找到下一個未填寫的欄位
    const nextField = fields.find(f => !state.form.params[f.key]);
    if (nextField) {
      state.form.waitingFor = nextField.key;
      setState(userId, state);
      return nextField.prompt();
    } else {
      // 所有欄位都已填寫，顯示結果
      const result = calculateResult(state.form.params);
      setState(userId, state);
      return result;
    }
  }
  
  // 答案無效，重新問同一個問題
  return currentField.prompt();
} 