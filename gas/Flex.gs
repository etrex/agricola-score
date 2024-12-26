/**
 * 生成分數顯示用的 Flex Message
 * @param {Object} scores 各項目分數
 * @param {number} total 總分
 * @returns {Object} LINE Flex Message
 */
function generateFlexMessage(scores, total) {
  const scoreItems = Object.entries(scores).map(([key, score]) => {
    const field = fields.find(f => f.key === key);
    return {
      type: 'box',
      layout: 'horizontal',
      contents: [
        {
          type: 'text',
          text: field.name,
          size: 'sm',
          color: '#555555',
          flex: 5
        },
        {
          type: 'text',
          text: score.toString(),
          size: 'sm',
          color: score >= 0 ? '#111111' : '#DD0000',
          align: 'end',
          flex: 2
        }
      ]
    };
  });

  return {
    type: 'flex',
    altText: '農家樂分數計算結果',
    contents: {
      type: 'bubble',
      body: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'text',
            text: '分數計算結果',
            weight: 'bold',
            color: '#1DB446',
            size: 'lg'
          },
          {
            type: 'separator',
            margin: 'xxl'
          },
          {
            type: 'box',
            layout: 'vertical',
            margin: 'xxl',
            spacing: 'sm',
            contents: scoreItems
          },
          {
            type: 'separator',
            margin: 'xxl'
          },
          {
            type: 'box',
            layout: 'horizontal',
            margin: 'md',
            contents: [
              {
                type: 'text',
                text: '總分',
                size: 'lg',
                weight: 'bold',
                flex: 5
              },
              {
                type: 'text',
                text: total.toString(),
                size: 'lg',
                weight: 'bold',
                color: total >= 0 ? '#111111' : '#DD0000',
                align: 'end',
                flex: 2
              }
            ]
          }
        ]
      },
      styles: {
        footer: {
          separator: true
        }
      }
    }
  };
} 