/**
 * 表單欄位類別
 */
class Field {
  /**
   * @param {Object} config 欄位配置
   * @param {string} config.key 欄位鍵值
   * @param {string} config.name 欄位名稱
   * @param {string} config.validator 驗證規則（正則表達式字串）
   * @param {string} config.question 問題文字
   * @param {string[]} config.answerOptions 可選答案
   */
  constructor({ key, name, validator, question, answerOptions }) {
    this.key = key;
    this.name = name;
    this.validator = validator;
    this.question = question;
    this.answerOptions = answerOptions;
  }
  
  /**
   * 驗證答案是否符合規則
   * @param {string} value 使用者輸入值
   * @returns {boolean}
   */
  validate(value) {
    return new RegExp(this.validator).test(value);
  }
  
  /**
   * 產生 LINE 訊息物件
   * @returns {Object} LINE Message API 格式的訊息物件
   */
  prompt() {
    return {
      type: 'text',
      text: this.question,
      quickReply: {
        items: this.answerOptions.map(option => ({
          type: 'action',
          action: {
            type: 'message',
            label: option,
            text: option
          }
        }))
      }
    };
  }
} 