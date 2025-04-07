require 'json'
require 'line-bot-api'
require 'aws-sdk-dynamodb'
require_relative 'message_handler'

def handler(event:, context:)
  # Initialize LINE client
  line_client = Line::Bot::Client.new do |config|
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_access_token = ENV['LINE_CHANNEL_ACCESS_TOKEN']
  end

  # Initialize DynamoDB client
  dynamodb = Aws::DynamoDB::Client.new
  table_name = ENV['DYNAMODB_TABLE']

  # Initialize MessageHandler
  message_handler = MessageHandler.new(line_client, dynamodb, table_name)

  begin
    # Parse request body
    body = JSON.parse(event['body'])
    
    # Verify signature
    signature = event.dig('headers', 'x-line-signature')
    unless signature
      return {
        statusCode: 400,
        body: JSON.generate(message: 'Missing signature')
      }
    end

    unless line_client.validate_signature(event['body'], signature)
      return {
        statusCode: 400,
        body: JSON.generate(message: 'Invalid signature')
      }
    end

    # Process each event
    body['events'].each do |event_data|
      if event_data['type'] == 'message' && event_data['message']['type'] == 'text'
        message_handler.handle_message(event_data)
      end
    end

    {
      statusCode: 200,
      body: JSON.generate(message: 'OK')
    }
  rescue JSON::ParserError => e
    {
      statusCode: 400,
      body: JSON.generate(message: 'Invalid request body')
    }
  rescue Line::Bot::API::Error => e
    {
      statusCode: 500,
      body: JSON.generate(message: "LINE API Error: #{e.message}")
    }
  rescue Aws::DynamoDB::Errors::ServiceError => e
    {
      statusCode: 500,
      body: JSON.generate(message: "DynamoDB Error: #{e.message}")
    }
  rescue StandardError => e
    {
      statusCode: 500,
      body: JSON.generate(message: "Internal Server Error: #{e.message}")
    }
  end
end