class ErrorHandler
  class LineError < StandardError; end
  class DynamoDBError < StandardError; end
  class ValidationError < StandardError; end

  def self.handle_error(error, context = {})
    error_id = generate_error_id
    log_error(error, error_id, context)

    case error
    when LineError
      { statusCode: 400, body: JSON.generate(error: 'LINE API Error', message: error.message, error_id: error_id) }
    when DynamoDBError
      { statusCode: 500, body: JSON.generate(error: 'Database Error', message: 'Internal server error', error_id: error_id) }
    when ValidationError
      { statusCode: 400, body: JSON.generate(error: 'Validation Error', message: error.message, error_id: error_id) }
    else
      { statusCode: 500, body: JSON.generate(error: 'Internal Server Error', message: 'An unexpected error occurred', error_id: error_id) }
    end
  end

  private

  def self.generate_error_id
    "err_#{Time.now.to_i}_#{SecureRandom.hex(4)}"
  end

  def self.log_error(error, error_id, context)
    error_log = {
      error_id: error_id,
      error_class: error.class.name,
      error_message: error.message,
      backtrace: error.backtrace,
      context: context,
      timestamp: Time.now.iso8601
    }

    puts JSON.generate(error_log)
  end
end