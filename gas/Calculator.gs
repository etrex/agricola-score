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
 * 計算得分
 * @param {Object} params 所有欄位的值
 * @returns {Object} 計算結果
 */
function calculateResult(params) {
  let scores = {};
  let total = 0;
  
  // 計算每個項目的分數
  Object.keys(params).forEach(key => {
    let value = params[key];
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
    
    scores[key] = score;
    total += score;
  });
  
  return generateFlexMessage(scores, total);
} 