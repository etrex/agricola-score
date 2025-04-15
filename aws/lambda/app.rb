require 'json'
require 'line-bot-api'
require 'aws-sdk-dynamodb'
require 'aws-sdk-ssm'
require_relative 'message_handler'
require_relative 'local_line_client' if ENV['AWS_SAM_LOCAL'] == 'true'

def initialize_local_clients
  line_client = LocalLineClient.new(
    channel_secret: 'local-dev',
    channel_token: 'local-dev'
  )

  dynamodb = Aws::DynamoDB::Client.new(
    endpoint: 'http://host.docker.internal:8000',
    region: 'us-east-1',
    access_key_id: 'dummy',
    secret_access_key: 'dummy'
  )

  [line_client, dynamodb]
end

def initialize_production_clients
  ssm = Aws::SSM::Client.new
  channel_secret = ssm.get_parameter(name: ENV['LINE_CHANNEL_SECRET_NAME'], with_decryption: true).parameter.value
  channel_token = ssm.get_parameter(name: ENV['LINE_CHANNEL_ACCESS_TOKEN_NAME'], with_decryption: true).parameter.value

  line_client = Line::Bot::Client.new(
    channel_secret: channel_secret,
    channel_token: channel_token
  )

  dynamodb = Aws::DynamoDB::Client.new

  [line_client, dynamodb]
end

def initialize_clients
  if ENV['AWS_SAM_LOCAL'] == 'true'
    initialize_local_clients
  else
    initialize_production_clients
  end
end

def valid_signature?(event, line_client)
  signature = event.dig('headers', 'x-line-signature') || event.dig('headers', 'X-Line-Signature')
  return false unless signature
  line_client.validate_signature(event['body'], signature)
end

def process_events(event, message_handler)
  body = JSON.parse(event['body'])
  body['events'].each do |event_data|
    if event_data['type'] == 'message' && event_data['message']['type'] == 'text'
      message_handler.handle_message(event_data)
    end
  end
end

def invalid_signature_response
  {
    statusCode: 400,
    body: JSON.generate(message: 'Invalid signature')
  }
end

def success_response
  {
    statusCode: 200,
    body: JSON.generate(message: 'OK')
  }
end

def error_response(error)
  {
    statusCode: 500,
    body: JSON.generate({
      message: 'Error processing request',
      error: error.message,
      backtrace: error.backtrace&.first
    })
  }
end

def handler(event:, context:)
  line_client, dynamodb = initialize_clients
  message_handler = MessageHandler.new(line_client, dynamodb, ENV['DYNAMODB_TABLE'])

  return invalid_signature_response unless valid_signature?(event, line_client)
  process_events(event, message_handler)
  success_response
rescue => e
  error_response(e)
end