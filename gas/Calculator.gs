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
  room木屋: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  room磚屋: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
  room石屋: [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28],
  family: 3,         // +3 points per family member
  beggingCard: -3    // -3 points per begging card
};

/**
 * 顯示順序
 */
const displayOrder = [
  'field',           // 田數
  'pasture',         // 柵欄圈地數
  'grain',           // 小麥數
  'vegetable',       // 蔬菜數
  'sheep',           // 羊數
  'wildBoar',        // 豬數
  'cattle',          // 牛數
  'emptyFarmyard',   // 空地數
  'fencedStable',    // 柵欄圈地內馬廄數
  'roomStyle',       // 房子
  'family',          // 人口數
  'beggingCard',     // 乞討卡
  'bonus',           // 主要發展卡的總得分
  'otherBonus'       // 職業卡和次要發展卡的總得分
];

/**
 * 計算單個欄位的分數
 * @param {string} key 欄位的鍵值
 * @param {string} value 用戶輸入的值
 * @param {Object} params 所有參數
 * @returns {number} 計算後的分數
 */
function calculateScore(key, value, params) {
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
      const roomCount = parseInt(params['room']);
      score = scoreTable[`room${value}`][roomCount];
      break;
      
    case 'room':
      score = 0;
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

  // 按照顯示順序計算各項分數
  displayOrder.forEach(key => {
    if (key in params) {
      const score = calculateScore(key, params[key], params);
      scores[key] = score;
      total += score;
    }
  });

  // 生成結果訊息
  return generateFlexMessage(scores, total, params);
} 