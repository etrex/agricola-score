module ScoreCategories
  CATEGORIES = {
    # 田地分數
    'fields' => {
      name: '田地',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 牧場分數
    'pastures' => {
      name: '牧場',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 穀物分數
    'grains' => {
      name: '穀物',
      max_score: 3,
      validation: ->(score) { score >= 0 && score <= 3 }
    },
    # 蔬菜分數
    'vegetables' => {
      name: '蔬菜',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 羊群分數
    'sheep' => {
      name: '羊',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 野豬群分數
    'wild_boars' => {
      name: '野豬',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 牛群分數
    'cattle' => {
      name: '牛',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 未使用空間分數
    'unused_spaces' => {
      name: '未使用空間',
      max_score: 0,
      validation: ->(score) { score <= 0 }
    },
    # 圍欄柵欄分數
    'fenced_stables' => {
      name: '圍欄柵欄',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 穀物分數
    'grain_tokens' => {
      name: '穀物標記',
      max_score: 3,
      validation: ->(score) { score >= 0 && score <= 3 }
    },
    # 蔬菜分數
    'vegetable_tokens' => {
      name: '蔬菜標記',
      max_score: 4,
      validation: ->(score) { score >= 0 && score <= 4 }
    },
    # 家庭成員分數
    'family_members' => {
      name: '家庭成員',
      max_score: 15,
      validation: ->(score) { score >= 0 && score <= 15 }
    },
    # 房間分數
    'house_tiles' => {
      name: '房間',
      max_score: nil,
      validation: ->(score) { score >= 0 }
    },
    # 卡片分數
    'card_points' => {
      name: '卡片',
      max_score: nil,
      validation: ->(score) { score >= 0 }
    },
    # 額外分數
    'bonus_points' => {
      name: '額外分數',
      max_score: nil,
      validation: ->(score) { score >= 0 }
    }
  }.freeze

  def self.validate_score(category, score)
    return false unless CATEGORIES[category]
    CATEGORIES[category][:validation].call(score)
  end

  def self.get_category_name(category)
    CATEGORIES[category]&.[](:name)
  end

  def self.calculate_total_score(scores)
    scores.sum { |_, score| score.to_i }
  end
end