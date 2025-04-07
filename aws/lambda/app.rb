require 'json'
require 'line-bot-api'
require 'aws-sdk-dynamodb'
require 'aws-sdk-ssm'
require_relative 'message_handler'

def handler(event:, context:)
  # Initialize SSM client
  ssm = Aws::SSM::Client.new

  # Get decrypted parameters
  channel_secret = ssm.get_parameter(name: ENV['LINE_CHANNEL_SECRET_NAME'], with_decryption: true).parameter.value
  channel_token = ssm.get_parameter(name: ENV['LINE_CHANNEL_ACCESS_TOKEN_NAME'], with_decryption: true).parameter.value

  # Initialize LINE client
  line_client = Line::Bot::Client.new(
    channel_secret: channel_secret,
    channel_token: channel_token
  )

  # Initialize DynamoDB client
  dynamodb = Aws::DynamoDB::Client.new
  table_name = ENV['DYNAMODB_TABLE']

  # Initialize MessageHandler
  message_handler = MessageHandler.new(line_client, dynamodb, table_name)

  # Log the event details
  puts "========== Request Details =========="
  puts "Headers: #{event['headers'].to_json}"
  puts "Body: #{event['body']}"
  puts "Signature: #{event.dig('headers', 'x-line-signature')}"
  puts "Channel Secret: #{ENV['LINE_CHANNEL_SECRET']}"
  puts "===================================="

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
rescue => e
  puts "Error: #{e.message}"
  puts "Error Backtrace: #{e.backtrace}"
  {
    statusCode: 500,
    body: JSON.generate(message: 'Invalid request body')
  }
end