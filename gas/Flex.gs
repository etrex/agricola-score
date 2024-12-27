/**
 * 生成分數顯示用的 Flex Message
 * @param {Object} scores 各項目分數
 * @param {number} total 總分
 * @returns {Object} LINE Flex Message
 */
function generateFlexMessage(scores, total, params) {
  const scoreItems = Object.entries(scores).map(([key, score]) => {
    const field = fields.find(f => f.key === key);
    return {
      type: 'box',
      layout: 'horizontal',
      margin: 'lg',
      contents: [
        {
          type: 'text',
          text: `${field.name}: ${params[key]}`,
          size: 'sm',
          flex: 0
        },
        {
          type: 'text',
          text: '修改',
          action: {
            type: 'message',
            text: field.name
          },
          color: '#225588',
          margin: 'md',
          flex: 0
        }
      ]
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
                color: '#555555'
              },
              {
                type: 'text',
                text: total.toString(),
                size: 'xl',
                weight: 'bold',
                color: total >= 0 ? '#1DB446' : '#DD0000',
                align: 'end',
                margin: 'sm'
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