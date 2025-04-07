require 'spec_helper'

RSpec.describe MessageHandler do
  let(:line_client) { instance_double(Line::Bot::Client) }
  let(:score_processor) { instance_double(ScoreProcessor) }
  let(:user_id) { 'test_user' }
  let(:reply_token) { 'test_reply_token' }
  
  subject { described_class.new(line_client, score_processor) }

  describe '#handle_message' do
    let(:event) do
      {
        'source' => { 'userId' => user_id },
        'replyToken' => reply_token,
        'message' => { 'text' => message_text }
      }
    end

    before do
      allow(line_client).to receive(:reply_message)
    end

    context 'when message is "開始計分"' do
      let(:message_text) { '開始計分' }
      let(:session_id) { 'new_session' }

      before do
        allow(score_processor).to receive(:start_scoring).and_return(session_id)
      end

      it 'starts a new scoring session' do
        expect(score_processor).to receive(:start_scoring).with(user_id)
        expect(line_client).to receive(:reply_message).with(
          reply_token,
          hash_including(type: 'text')
        )

        subject.handle_message(event)
      end
    end

    context 'when message is a score' do
      let(:message_text) { '3分' }
      let(:category) { 'fields' }
      let(:session_id) { 'current_session' }

      before do
        allow(score_processor).to receive(:get_current_session_id).and_return(session_id)
        allow(score_processor).to receive(:get_current_category).and_return(category)
        allow(score_processor).to receive(:update_score)
      end

      it 'updates the score' do
        expect(score_processor).to receive(:update_score).with(user_id, session_id, category, 3)
        expect(line_client).to receive(:reply_message).with(
          reply_token,
          hash_including(type: 'text')
        )

        subject.handle_message(event)
      end
    end

    context 'when message is "保存"' do
      let(:message_text) { '保存' }
      let(:session_id) { 'current_session' }

      before do
        allow(score_processor).to receive(:get_current_session_id).and_return(session_id)
        allow(score_processor).to receive(:get_current_scores).and_return({ 'fields' => 3 })
        allow(score_processor).to receive(:save_score)
      end

      it 'saves the current score' do
        expect(score_processor).to receive(:save_score).with(user_id, session_id)
        expect(line_client).to receive(:reply_message).with(
          reply_token,
          hash_including(type: 'text')
        )

        subject.handle_message(event)
      end
    end

    context 'when message is "查詢歷史"' do
      let(:message_text) { '查詢歷史' }

      before do
        allow(score_processor).to receive(:get_user_scores).and_return([
          { 'createdAt' => Time.now.to_i, 'total_score' => 45 }
        ])
      end

      it 'returns the score history' do
        expect(score_processor).to receive(:get_user_scores).with(user_id)
        expect(line_client).to receive(:reply_message).with(
          reply_token,
          hash_including(type: 'text')
        )

        subject.handle_message(event)
      end
    end
  end
end