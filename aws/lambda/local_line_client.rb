class LocalLineClient
  def initialize(channel_secret:, channel_token:)
    @channel_secret = channel_secret
    @channel_token = channel_token
  end

  def validate_signature(body, signature)
    true # 本地開發時略過驗證
  end

  def reply_message(reply_token, messages)
    puts "\n========== LINE Message to be sent =========="
    puts "Reply Token: #{reply_token}"
    puts "Messages:"
    messages = [messages] unless messages.is_a?(Array)
    messages.each do |msg|
      puts JSON.pretty_generate(msg)
    end
    puts "==========================================\n"
    true
  end
end
