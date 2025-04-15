require_relative 'fields'
require_relative 'calculator'
require_relative 'test_handler'

class MessageHandler
  def initialize(line_client, dynamodb_client, table_name)
    @line_client = line_client
    @dynamodb_client = dynamodb_client
    @table_name = table_name
    @test_handler = TestHandler.new(line_client)
  end

  def handle_message(event)
    user_id = event.dig('source', 'userId')
    message = event.dig('message', 'text')

    return unless user_id && message

    # 如果是測試指令，轉給 test_handler 處理
    if message == 'test'
      return @test_handler.handle_message(event)
    end

    state = get_state(user_id)
    state['userId'] = user_id unless state['userId']

    response = process_message(message, state)
    save_state(user_id, state)

    begin
      @line_client.reply_message(event['replyToken'], response)
    rescue Line::Bot::API::Error => e
      puts "LINE API Error: #{e.message}"
      raise
    rescue StandardError => e
      puts "Unexpected Error: #{e.message}"
      raise
    end
  end

  private

  def get_state(user_id)
    begin
      result = @dynamodb_client.get_item({
        table_name: @table_name,
        key: {
          'userId' => user_id,
          'sessionId' => 'current'
        }
      })
      result.item ? JSON.parse(result.item['state']) : { 'form' => {} }
    rescue Aws::DynamoDB::Errors::ServiceError => e
      puts "DynamoDB Error: #{e.message}"
      { 'form' => {} }
    end
  end

  def save_state(user_id, state)
    @dynamodb_client.put_item({
      table_name: @table_name,
      item: {
        'userId' => user_id,
        'sessionId' => 'current',
        'state' => state.to_json,
        'updatedAt' => Time.now.to_i,
        'expiresAt' => Time.now.to_i + 24 * 60 * 60,  # 24 hours TTL
        'type' => 'TEMP'
      }
    })
  rescue Aws::DynamoDB::Errors::ServiceError => e
    puts "DynamoDB Error: #{e.message}"
  end

  def save_score(user_id, state)
    @dynamodb_client.put_item({
      table_name: @table_name,
      item: {
        'userId' => user_id,
        'sessionId' => Time.now.to_i.to_s,
        'state' => state.to_json,
        'updatedAt' => Time.now.to_i,
        'expiresAt' => nil,
        'type' => 'SAVED'
      }
    })

    state['form'] = {
      'params' => {},
      'waitingFor' => Fields::FIELDS[0].key
    }

    { success: true, message: '分數已成功保存' }
  rescue Aws::DynamoDB::Errors::ServiceError => e
    puts "DynamoDB Error: #{e.message}"
    { success: false, message: '保存分數時發生錯誤' }
  end

  def process_message(message, state)
    # 處理歡迎訊息
    return greeting if message == '歡迎' || message == 'help'

    # 處理保存分數
    if message == '保存此分數'
      result = save_score(state['userId'], state)
      return {
        type: 'text',
        text: result[:message]
      }
    end

    # 處理開始計分
    if message == '幫我算分數' || !state['form']['waitingFor']
      state['form'] = {
        'params' => {},
        'waitingFor' => Fields::FIELDS[0].key
      }
      return Fields::FIELDS[0].prompt
    end

    # 處理修改請求
    field = Fields::FIELDS.find { |f| f.name == message }
    if field
      state['form']['params'].delete(field.key)
      state['form']['waitingFor'] = field.key
      return field.prompt
    end
    
    # 處理修改房子的特殊請求
    if message == '修改房子'
      state['form']['params'].delete('roomStyle')
      state['form']['params'].delete('room')
      state['form']['waitingFor'] = 'roomStyle'
      return Fields::FIELDS.find { |f| f.key == 'roomStyle' }.prompt
    end

    # 處理當前問題的答案
    current_field = Fields::FIELDS.find { |f| f.key == state['form']['waitingFor'] }
    if current_field&.validate(message)
      # 儲存答案
      state['form']['params'][current_field.key] = message

      # 如果所有欄位都已填寫，顯示結果
      if state['form']['params'].keys.length == Fields::FIELDS.length
        return Calculator.calculate_result(state['form']['params'])
      end

      # 找到下一個未填寫的欄位
      next_field = Fields::FIELDS.find { |f| !state['form']['params'][f.key] }
      if next_field
        state['form']['waitingFor'] = next_field.key
        return next_field.prompt
      else
        return Calculator.calculate_result(state['form']['params'])
      end
    end

    # 答案無效，重新問同一個問題
    current_field.prompt
  end

  def greeting
    {
      type: 'flex',
      altText: '歡迎來到農家樂分數計算機',
      contents: {
        type: 'bubble',
        body: {
          type: 'box',
          layout: 'vertical',
          contents: [
            {
              type: 'text',
              text: '歡迎來到農家樂分數計算機，請點擊按鈕開始算分數：',
              wrap: true
            },
            {
              type: 'button',
              action: {
                type: 'message',
                label: '開始計算',
                text: '幫我算分數'
              },
              style: 'primary',
              color: '#225588',
              margin: 'md'
            }
          ]
        }
      }
    }
  end
end