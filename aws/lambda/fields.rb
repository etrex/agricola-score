module Fields
  class Field
    attr_reader :key, :name, :validator, :question, :answer_options

    def initialize(options)
      @key = options[:key]
      @name = options[:name]
      @validator = options[:validator]
      @question = options[:question]
      @answer_options = options[:answer_options]
    end

    def prompt
      {
        type: 'text',
        text: @question,
        quickReply: {
          items: @answer_options.map { |option|
            {
              type: 'action',
              action: {
                type: 'message',
                label: option,
                text: option
              }
            }
          }
        }
      }
    end

    def validate(input)
      input.match?(/#{@validator}/)
    end
  end

  # 數字選項陣列
  NUM_0_TO_12 = %w[0 1 2 3 4 5 6 7 8 9 10 11 12]
  NUM_2_TO_14 = %w[2 3 4 5 6 7 8 9 10 11 12 13 14]

  # 遊戲欄位定義
  FIELDS = [
    Field.new(
      key: 'field',
      name: '田數',
      validator: '^\d{1,2}$',
      question: '您耕了幾片田?',
      answer_options: %w[0 1 2 3 4 5]
    ),
    Field.new(
      key: 'pasture',
      name: '柵欄圈地數',
      validator: '^\d{1}$',
      question: '您蓋出幾圈柵欄圈地?',
      answer_options: %w[0 1 2 3 4 5]
    ),
    Field.new(
      key: 'grain',
      name: '小麥數',
      validator: '^\d{1,2}$',
      question: '您有幾個小麥?(手上的以及田裡的)',
      answer_options: %w[0 1 2 3 4 5 6 7 8]
    ),
    Field.new(
      key: 'vegetable',
      name: '蔬菜數',
      validator: '^\d{1,2}$',
      question: '您有幾個蔬菜?(手上的以及田裡的)',
      answer_options: %w[0 1 2 3 4]
    ),
    Field.new(
      key: 'sheep',
      name: '羊數',
      validator: '^\d{1,2}$',
      question: '您養了幾頭羊?',
      answer_options: %w[0 1 2 3 4 5 6 7 8]
    ),
    Field.new(
      key: 'wildBoar',
      name: '豬數',
      validator: '^\d{1,2}$',
      question: '您養了幾頭豬?',
      answer_options: %w[0 1 2 3 4 5 6 7]
    ),
    Field.new(
      key: 'cattle',
      name: '牛數',
      validator: '^\d{1,2}$',
      question: '您養了幾頭牛?',
      answer_options: %w[0 1 2 3 4 5 6]
    ),
    Field.new(
      key: 'emptyFarmyard',
      name: '空地數',
      validator: '^\d{1,2}$',
      question: '您有幾片未使用的空地?',
      answer_options: NUM_0_TO_12
    ),
    Field.new(
      key: 'fencedStable',
      name: '柵欄圈地內馬廄數',
      validator: '^[01234]$',
      question: '您蓋了幾間在柵欄圈地內的馬廄?',
      answer_options: %w[0 1 2 3 4]
    ),
    Field.new(
      key: 'roomStyle',
      name: '房間類型',
      validator: '(木|磚|石)屋',
      question: '您住在哪種房子? (木屋, 磚屋, 石屋)',
      answer_options: %w[木屋 磚屋 石屋]
    ),
    Field.new(
      key: 'room',
      name: '房間數',
      validator: '^\d{1,2}$',
      question: '您家有幾間房間? (包含一開始的兩間)',
      answer_options: NUM_2_TO_14
    ),
    Field.new(
      key: 'family',
      name: '人口數',
      validator: '^[2345]$',
      question: '您家有幾個人?',
      answer_options: %w[2 3 4 5]
    ),
    Field.new(
      key: 'beggingCard',
      name: '乞討卡',
      validator: '^\d{1,2}$',
      question: '您拿到幾張乞討卡?',
      answer_options: NUM_0_TO_12
    ),
    Field.new(
      key: 'bonus',
      name: '主要發展卡的的總得分',
      validator: '^\d{1,2}$',
      question: '您在主要發展卡上的總得分是?',
      answer_options: NUM_0_TO_12
    ),
    Field.new(
      key: 'otherBonus',
      name: '職業卡和次要發展卡的總得分',
      validator: '^\d{1,2}$',
      question: '您在職業卡和次要發展卡上的總得分是?',
      answer_options: NUM_0_TO_12
    )
  ]
end