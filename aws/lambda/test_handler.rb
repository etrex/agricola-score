# frozen_string_literal: true

require_relative './flex'

class TestHandler
  def initialize(line_client)
    @line_client = line_client
  end

  def handle_message(event)
    return unless event['message']['text'] == 'test'

    require_relative 'calculator'

    # 測試用的資料
    params = {
      'field' => '3',
      'pasture' => '2',
      'grain' => '1',
      'vegetable' => '2',
      'sheep' => '4',
      'wildBoar' => '3',
      'cattle' => '2',
      'emptyFarmyard' => '1',
      'fencedStable' => '1',
      'roomStyle' => '石屋',
      'room' => '5',
      'family' => '3',
      'beggingCard' => '1',
      'bonus' => '2',
      'otherBonus' => '1'
    }

    # 使用 Calculator 計算分數
    scores = {}
    total = 0

    Calculator::DISPLAY_ORDER.each do |key|
      next unless params[key]
      score = Calculator.calculate_score(key, params[key], params)
      scores[key] = score
      total += score
    end

    begin
      puts "========== Test Response Details =========="
      response = Flex.generate_flex_message(scores, total, params)
      puts "Response: #{response.to_json}"
      puts "====================================="

      puts "========== Sending Test Response =========="
      result = @line_client.reply_message(event['replyToken'], response)
      puts "========== Test Response Sent ==========="
      puts "Result: #{result}"
    rescue Line::Bot::API::Error => e
      puts "LINE API Error: #{e.message}"
      puts "Error Class: #{e.class}"
      puts "Error Response: #{e.response}"
      puts "Error Response Body: #{e.response.body}" if e.response
      raise
    rescue StandardError => e
      puts "Unexpected Error: #{e.message}"
      puts "Error Class: #{e.class}"
      puts "Backtrace:"
      puts e.backtrace
      raise
    end
  end
end