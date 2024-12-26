/**
 * 取得使用者狀態
 * @param {string} userId LINE 使用者 ID
 * @returns {Object} 使用者狀態
 */
function getState(userId) {
  const cache = CacheService.getUserCache();
  const state = cache.get(userId);
  return state ? JSON.parse(state) : {
    form: {
      path: null,
      params: {},
      waitingFor: null
    }
  };
}

/**
 * 儲存使用者狀態
 * @param {string} userId LINE 使用者 ID
 * @param {Object} state 使用者狀態
 */
function setState(userId, state) {
  const cache = CacheService.getUserCache();
  cache.put(userId, JSON.stringify(state), 21600); // 6小時
}

/**
 * 清除使用者狀態
 * @param {string} userId LINE 使用者 ID
 */
function clearState(userId) {
  const cache = CacheService.getUserCache();
  cache.remove(userId);
} 