require 'spec_helper'

RSpec.describe ScoreProcessor do
  let(:dynamodb_client) { instance_double(Aws::DynamoDB::Client) }
  let(:table_name) { 'test_table' }
  let(:user_id) { 'test_user' }
  let(:session_id) { 'test_session' }
  
  subject { described_class.new(dynamodb_client, table_name) }

  describe '#start_scoring' do
    before do
      allow(dynamodb_client).to receive(:put_item)
      allow(Time).to receive(:now).and_return(Time.at(1234567890))
      allow(SecureRandom).to receive(:hex).and_return('abcd1234')
    end

    it 'creates a new scoring session' do
      expect(dynamodb_client).to receive(:put_item).with(
        hash_including(
          table_name: table_name,
          item: hash_including(
            userId: user_id,
            status: 'scoring',
            scores: {},
            type: 'temporary'
          )
        )
      )

      subject.start_scoring(user_id)
    end
  end

  describe '#update_score' do
    let(:category) { 'fields' }
    let(:score) { 3 }

    before do
      allow(dynamodb_client).to receive(:update_item)
    end

    it 'updates the score for a category' do
      expect(dynamodb_client).to receive(:update_item).with(
        hash_including(
          table_name: table_name,
          key: {
            userId: user_id,
            sessionId: session_id
          },
          update_expression: 'SET scores.#category = :score, currentCategory = :next_category',
          expression_attribute_names: {
            '#category' => category
          }
        )
      )

      subject.update_score(user_id, session_id, category, score)
    end
  end

  describe '#get_current_scores' do
    let(:scores) { { 'fields' => 3, 'pastures' => 2 } }

    before do
      allow(dynamodb_client).to receive(:get_item).and_return(
        instance_double(
          Aws::DynamoDB::Types::GetItemOutput,
          item: { 'scores' => scores }
        )
      )
    end

    it 'returns the current scores' do
      expect(subject.get_current_scores(user_id)).to eq(scores)
    end
  end

  describe '#save_score' do
    before do
      allow(dynamodb_client).to receive(:update_item)
      allow(subject).to receive(:get_current_scores).and_return({ 'fields' => 3, 'pastures' => 2 })
    end

    it 'saves the score permanently' do
      expect(dynamodb_client).to receive(:update_item).with(
        hash_including(
          table_name: table_name,
          key: {
            userId: user_id,
            sessionId: session_id
          },
          update_expression: 'REMOVE expiresAt SET type = :type, totalScore = :total'
        )
      )

      subject.save_score(user_id, session_id)
    end
  end
end