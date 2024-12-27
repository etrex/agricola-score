/**
 * 分數對照表
 */
const scoreTable = {
  field: [-1, -1, 1, 2, 3, 4, 4, 4, 4, 4],
  pasture: [-1, 1, 2, 3, 4, 4, 4, 4, 4],
  grain: [-1, 1, 1, 1, 2, 2, 3, 3, 4, 4],
  vegetable: [-1, 1, 2, 3, 4, 4, 4, 4, 4],
  sheep: [-1, 1, 1, 1, 2, 2, 3, 3, 4, 4],
  wildBoar: [-1, 1, 1, 2, 2, 3, 3, 4, 4],
  cattle: [-1, 1, 2, 2, 3, 3, 4, 4, 4],
  emptyFarmyard: -1,  // -1 point per empty farmyard
  fencedStable: 1,    // +1 point per fenced stable
  roomStyle: {
    '木屋': 0,
    '磚屋': 1,
    '石屋': 2
  },
  room: 0,           // points equal to number of rooms
  family: 3,         // +3 points per family member
  beggingCard: -3    // -3 points per begging card
};

/**
 * 計算單個欄位的分數
 * @param {string} key 欄位的鍵值
 * @param {string} value 用戶輸入的值
 * @returns {number} 計算後的分數
 */
function calculateScore(key, value) {
  let score = 0;
  
  switch (key) {
    case 'field':
    case 'pasture':
    case 'grain':
    case 'vegetable':
    case 'sheep':
    case 'wildBoar':
    case 'cattle':
      const index = parseInt(value);
      score = index < scoreTable[key].length ? scoreTable[key][index] : scoreTable[key][scoreTable[key].length - 1];
      break;
      
    case 'emptyFarmyard':
      score = parseInt(value) * scoreTable[key];
      break;
      
    case 'fencedStable':
      score = parseInt(value) * scoreTable[key];
      break;
      
    case 'roomStyle':
      score = scoreTable[key][value] || 0;
      break;
      
    case 'room':
      score = parseInt(value);
      break;
      
    case 'family':
      score = parseInt(value) * scoreTable[key];
      break;
      
    case 'beggingCard':
      score = parseInt(value) * scoreTable[key];
      break;
      
    case 'bonus':
    case 'otherBonus':
      score = parseInt(value);
      break;
  }
  
  return score;
}

/**
 * 計算分數結果
 * @param {Object} params 用戶輸入的參數
 * @returns {Object} Flex Message 物件
 */
function calculateResult(params) {
  const scores = {};
  let total = 0;

  // 計算各項分數
  Object.entries(params).forEach(([key, value]) => {
    const score = calculateScore(key, value);
    scores[key] = score;
    total += score;
  });

  // 生成結果訊息
  return generateFlexMessage(scores, total, params);
} 