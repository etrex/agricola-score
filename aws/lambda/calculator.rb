class Calculator
  SCORE_TABLE = {
    field: [-1, -1, 1, 2, 3, 4, 4, 4, 4, 4],
    pasture: [-1, 1, 2, 3, 4, 4, 4, 4, 4],
    grain: [-1, 1, 1, 1, 2, 2, 3, 3, 4, 4],
    vegetable: [-1, 1, 2, 3, 4, 4, 4, 4, 4],
    sheep: [-1, 1, 1, 1, 2, 2, 3, 3, 4, 4],
    wildBoar: [-1, 1, 1, 2, 2, 3, 3, 4, 4],
    cattle: [-1, 1, 2, 2, 3, 3, 4, 4, 4],
    emptyFarmyard: -1,  # -1 point per empty farmyard
    fencedStable: 1,    # +1 point per fenced stable
    room木屋: [0] * 15,  # 木屋不加分
    room磚屋: (0..14).to_a,  # 磚屋每間+1分
    room石屋: (0..14).map { |n| n * 2 },  # 石屋每間+2分
    family: 3,          # +3 points per family member
    beggingCard: -3     # -3 points per begging card
  }.freeze

  DISPLAY_ORDER = %w[
    field
    pasture
    grain
    vegetable
    sheep
    wildBoar
    cattle
    emptyFarmyard
    fencedStable
    roomStyle
    family
    beggingCard
    bonus
    otherBonus
  ].freeze

  def self.calculate_score(key, value, params)
    case key
    when 'field', 'pasture', 'grain', 'vegetable', 'sheep', 'wildBoar', 'cattle'
      index = value.to_i
      table = SCORE_TABLE[key.to_sym]
      index < table.length ? table[index] : table.last
    when 'emptyFarmyard', 'fencedStable'
      value.to_i * SCORE_TABLE[key.to_sym]
    when 'roomStyle'
      room_count = params['room'].to_i
      SCORE_TABLE["room#{value}".to_sym][room_count]
    when 'room'
      0  # 房間數本身不計分，在 roomStyle 中計算
    when 'family', 'beggingCard'
      value.to_i * SCORE_TABLE[key.to_sym]
    when 'bonus', 'otherBonus'
      value.to_i
    else
      0
    end
  end

  def self.calculate_result(params)
    scores = {}
    total = 0

    DISPLAY_ORDER.each do |key|
      next unless params[key]
      score = calculate_score(key, params[key], params)
      scores[key] = score
      total += score
    end

    generate_result_message(scores, total, params)
  end

  def self.generate_result_message(scores, total, params)
    contents = []

    # 添加標題
    contents << {
      type: 'text',
      text: '農家樂計分結果',
      weight: 'bold',
      size: 'xl',
      margin: 'md'
    }

    # 添加各項分數
    DISPLAY_ORDER.each do |key|
      next unless scores[key]
      field = FIELDS.find { |f| f.key == key }
      next unless field

      contents << {
        type: 'box',
        layout: 'horizontal',
        margin: 'sm',
        contents: [
          {
            type: 'text',
            text: "#{field.name}:",
            size: 'sm',
            color: '#555555',
            flex: 2
          },
          {
            type: 'text',
            text: params[key].to_s,
            size: 'sm',
            color: '#111111',
            align: 'end',
            flex: 1
          },
          {
            type: 'text',
            text: scores[key].to_s,
            size: 'sm',
            color: scores[key] >= 0 ? '#22AA22' : '#AA2222',
            align: 'end',
            flex: 1
          }
        ]
      }
    end

    # 添加總分
    contents << {
      type: 'box',
      layout: 'horizontal',
      margin: 'md',
      contents: [
        {
          type: 'text',
          text: '總分:',
          size: 'lg',
          weight: 'bold',
          flex: 2
        },
        {
          type: 'text',
          text: total.to_s,
          size: 'lg',
          weight: 'bold',
          color: '#225588',
          align: 'end',
          flex: 2
        }
      ]
    }

    # 添加重新計算按鈕
    contents << {
      type: 'button',
      action: {
        type: 'message',
        label: '重新計算',
        text: '幫我算分數'
      },
      style: 'primary',
      color: '#225588',
      margin: 'md'
    }

    {
      type: 'flex',
      altText: "農家樂計分結果：#{total}分",
      contents: {
        type: 'bubble',
        body: {
          type: 'box',
          layout: 'vertical',
          contents: contents
        }
      }
    }
  end
end