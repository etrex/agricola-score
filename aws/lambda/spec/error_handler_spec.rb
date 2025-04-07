require 'spec_helper'

RSpec.describe ErrorHandler do
  describe '.handle_error' do
    let(:context) { { event: { type: 'test' } } }

    before do
      allow(Time).to receive(:now).and_return(Time.at(1234567890))
      allow(SecureRandom).to receive(:hex).and_return('abcd1234')
    end

    context 'with LineError' do
      let(:error) { ErrorHandler::LineError.new('LINE API error') }

      it 'returns appropriate error response' do
        response = described_class.handle_error(error, context)
        expect(response[:statusCode]).to eq(400)
        expect(JSON.parse(response[:body])['error']).to eq('LINE API Error')
      end
    end

    context 'with DynamoDBError' do
      let(:error) { ErrorHandler::DynamoDBError.new('Database error') }

      it 'returns appropriate error response' do
        response = described_class.handle_error(error, context)
        expect(response[:statusCode]).to eq(500)
        expect(JSON.parse(response[:body])['error']).to eq('Database Error')
      end
    end

    context 'with ValidationError' do
      let(:error) { ErrorHandler::ValidationError.new('Invalid input') }

      it 'returns appropriate error response' do
        response = described_class.handle_error(error, context)
        expect(response[:statusCode]).to eq(400)
        expect(JSON.parse(response[:body])['error']).to eq('Validation Error')
      end
    end

    context 'with unexpected error' do
      let(:error) { StandardError.new('Unexpected error') }

      it 'returns internal server error response' do
        response = described_class.handle_error(error, context)
        expect(response[:statusCode]).to eq(500)
        expect(JSON.parse(response[:body])['error']).to eq('Internal Server Error')
      end
    end
  end
end