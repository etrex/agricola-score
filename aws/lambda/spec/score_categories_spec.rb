require 'spec_helper'

RSpec.describe ScoreCategories do
  describe '.validate_score' do
    context 'with fields category' do
      it 'validates valid scores' do
        expect(described_class.validate_score('fields', 0)).to be true
        expect(described_class.validate_score('fields', 2)).to be true
        expect(described_class.validate_score('fields', 4)).to be true
      end

      it 'invalidates invalid scores' do
        expect(described_class.validate_score('fields', -1)).to be false
        expect(described_class.validate_score('fields', 5)).to be false
      end
    end

    context 'with unused_spaces category' do
      it 'validates valid scores' do
        expect(described_class.validate_score('unused_spaces', 0)).to be true
        expect(described_class.validate_score('unused_spaces', -1)).to be true
        expect(described_class.validate_score('unused_spaces', -5)).to be true
      end

      it 'invalidates invalid scores' do
        expect(described_class.validate_score('unused_spaces', 1)).to be false
      end
    end
  end

  describe '.get_category_name' do
    it 'returns the correct category name' do
      expect(described_class.get_category_name('fields')).to eq('田地')
      expect(described_class.get_category_name('pastures')).to eq('牧場')
    end

    it 'returns nil for invalid category' do
      expect(described_class.get_category_name('invalid')).to be_nil
    end
  end

  describe '.calculate_total_score' do
    it 'calculates the total score correctly' do
      scores = {
        'fields' => 3,
        'pastures' => 2,
        'unused_spaces' => -2,
        'bonus_points' => 5
      }

      expect(described_class.calculate_total_score(scores)).to eq(8)
    end

    it 'handles empty scores' do
      expect(described_class.calculate_total_score({})).to eq(0)
    end
  end
end