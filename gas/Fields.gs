/**
 * 數字選項陣列
 */
const num0To12 = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
const num2To14 = ['2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14'];

/**
 * 遊戲欄位定義
 */
const fields = [
  new Field({
    key: 'field',
    name: '田數',
    validator: '^\\d{1,2}$',
    question: '您耕了幾片田?',
    answerOptions: ['0', '1', '2', '3', '4', '5']
  }),
  new Field({
    key: 'pasture',
    name: '柵欄圈地數',
    validator: '^\\d{1}$',
    question: '您蓋出幾圈柵欄圈地?',
    answerOptions: ['0', '1', '2', '3', '4', '5']
  }),
  new Field({
    key: 'grain',
    name: '小麥數',
    validator: '^\\d{1,2}$',
    question: '您有幾個小麥?(手上的以及田裡的)',
    answerOptions: ['0', '1', '2', '3', '4', '5', '6', '7', '8']
  }),
  new Field({
    key: 'vegetable',
    name: '蔬菜數',
    validator: '^\\d{1,2}$',
    question: '您有幾個蔬菜?(手上的以及田裡的)',
    answerOptions: ['0', '1', '2', '3', '4']
  }),
  new Field({
    key: 'sheep',
    name: '羊數',
    validator: '^\\d{1,2}$',
    question: '您養了幾頭羊?',
    answerOptions: ['0', '1', '2', '3', '4', '5', '6', '7', '8']
  }),
  new Field({
    key: 'wildBoar',
    name: '豬數',
    validator: '^\\d{1,2}$',
    question: '您養了幾頭豬?',
    answerOptions: ['0', '1', '2', '3', '4', '5', '6', '7']
  }),
  new Field({
    key: 'cattle',
    name: '牛數',
    validator: '^\\d{1,2}$',
    question: '您養了幾頭牛?',
    answerOptions: ['0', '1', '2', '3', '4', '5', '6']
  }),
  new Field({
    key: 'emptyFarmyard',
    name: '空地數',
    validator: '^\\d{1,2}$',
    question: '您有幾片未使用的空地?',
    answerOptions: num0To12
  }),
  new Field({
    key: 'fencedStable',
    name: '柵欄圈地內馬廄數',
    validator: '^[01234]$',
    question: '您蓋了幾間在柵欄圈地內的馬廄?',
    answerOptions: ['0', '1', '2', '3', '4']
  }),
  new Field({
    key: 'roomStyle',
    name: '房間類型',
    validator: '(木|磚|石)屋',
    question: '您住在哪種房子? (木屋, 磚屋, 石屋)',
    answerOptions: ['木屋', '磚屋', '石屋']
  }),
  new Field({
    key: 'room',
    name: '房間數',
    validator: '^\\d{1,2}$',
    question: '您家有幾間房間? (包含一開始的兩間)',
    answerOptions: num2To14
  }),
  new Field({
    key: 'family',
    name: '人口數',
    validator: '^[2345]$',
    question: '您家有幾個人?',
    answerOptions: ['2', '3', '4', '5']
  }),
  new Field({
    key: 'beggingCard',
    name: '乞討卡',
    validator: '^\\d{1,2}$',
    question: '您拿到幾張乞討卡?',
    answerOptions: num0To12
  }),
  new Field({
    key: 'bonus',
    name: '主要發展卡的的總得分',
    validator: '^\\d{1,2}$',
    question: '您在主要發展卡上的總得分是?',
    answerOptions: num0To12
  }),
  new Field({
    key: 'otherBonus',
    name: '職業卡和次要發展卡的總得分',
    validator: '^\\d{1,2}$',
    question: '您在職業卡和次要發展卡上的總得分是?',
    answerOptions: num0To12
  })
]; 