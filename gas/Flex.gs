/**
 * 生成分數顯示用的 Flex Message
 * @param {Object} scores 各項目分數
 * @param {number} total 總分
 * @returns {Object} LINE Flex Message
 */
function generateFlexMessage(scores, total, params) {
  const scoreItems = Object.entries(scores).map(([key, score]) => {
    const field = fields.find(f => f.key === key);
    const userInput = params[key];
    return {
      type: 'box',
      layout: 'horizontal',
      contents: [
        {
          type: 'text',
          text: field.name,
          size: 'md',
          color: '#555555',
          flex: 6,
          weight: 'regular'
        },
        {
          type: 'text',
          text: userInput,
          size: 'md',
          color: '#1DB446',
          align: 'end',
          weight: 'regular',
          flex: 3
        },
        {
          type: 'button',
          action: {
            type: 'message',
            label: '修改',
            text: field.name
          },
          style: 'link',
          height: 'sm',
          flex: 0
        }
      ],
      margin: 'lg'
    };
  });

  return {
    type: 'flex',
    altText: '農家樂分數計算結果',
    contents: {
      type: 'bubble',
      size: 'giga',
      header: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'text',
            text: '分數計算結果',
            weight: 'bold',
            color: '#1DB446',
            size: 'xl',
            align: 'center'
          }
        ],
        backgroundColor: '#f6f6f6',
        paddingTop: 'lg',
        paddingBottom: 'lg'
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'box',
            layout: 'vertical',
            spacing: 'none',
            contents: scoreItems,
            margin: 'none'
          },
          {
            type: 'separator',
            margin: 'xxl',
            color: '#cccccc'
          },
          {
            type: 'box',
            layout: 'horizontal',
            margin: 'xl',
            contents: [
              {
                type: 'text',
                text: '總分',
                size: 'xl',
                weight: 'bold',
                flex: 6,
                color: '#555555'
              },
              {
                type: 'text',
                text: total.toString(),
                size: 'xl',
                weight: 'bold',
                color: total >= 0 ? '#1DB446' : '#DD0000',
                align: 'end',
                flex: 3
              }
            ]
          }
        ]
      },
      footer: {
        type: 'box',
        layout: 'vertical',
        spacing: 'sm',
        contents: [
          {
            type: 'button',
            style: 'primary',
            color: '#1DB446',
            action: {
              type: 'message',
              label: '再算一次',
              text: '幫我算分數'
            }
          },
          {
            type: 'button',
            style: 'secondary',
            action: {
              type: 'message',
              label: '推薦給好友',
              text: '推薦給好友'
            }
          }
        ],
        paddingAll: 'lg'
      },
      styles: {
        header: {
          separator: false
        },
        footer: {
          separator: true
        }
      }
    }
  };
} 