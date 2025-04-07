# frozen_string_literal: true

require_relative 'calculator'
require_relative 'fields'

class Flex
  DISPLAY_ORDER = Calculator::DISPLAY_ORDER
  FIELDS = ::Fields::FIELDS
  def self.generate_flex_message(scores, total, params)
    score_items = DISPLAY_ORDER.map do |key|
      next unless scores[key]
      
      field = FIELDS.find { |f| f.key == key }
      
      # 特別處理房子相關的欄位
      if key == 'roomStyle'
        room_count = params['room'].to_i
        house_score = scores[key]
        {
          type: 'box',
          layout: 'horizontal',
          margin: 'lg',
          contents: [
            {
              type: 'text',
              text: "房子: #{params[key]} #{params['room']}間",
              size: 'sm',
              flex: 1
            },
            {
              type: 'text',
              text: house_score.to_s,
              size: 'sm',
              color: house_score >= 0 ? '#1DB446' : '#DD0000',
              align: 'end',
              flex: 0
            },
            {
              type: 'text',
              text: '修改',
              action: {
                type: 'message',
                text: '修改房子'
              },
              color: '#225588',
              margin: 'md',
              flex: 0
            }
          ]
        }
      # 跳過房間數欄位，因為已經在房子類型中顯示
      elsif key == 'room'
        nil
      else
        next unless field

        {
          type: 'box',
          layout: 'horizontal',
          margin: 'lg',
          contents: [
            {
              type: 'text',
              text: "#{field.name}: #{params[key]}",
              size: 'sm',
              flex: 1
            },
            {
              type: 'text',
              text: scores[key].to_s,
              size: 'sm',
              color: scores[key] >= 0 ? '#1DB446' : '#DD0000',
              align: 'end',
              flex: 0
            },
            {
              type: 'text',
              text: '修改',
              action: {
                type: 'message',
                text: "修改#{field.name}"
              },
              color: '#225588',
              margin: 'md',
              flex: 0
            }
          ]
        }
      end
    end.compact

    {
      type: 'flex',
      altText: "分數計算結果：總分 #{total}",
      contents: {
        type: 'bubble',
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
              contents: score_items,
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
                  text: total.to_s,
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
    }
  end
end