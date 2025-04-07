require 'aws-sdk-dynamodb'
require_relative 'score_categories'

class ScoreProcessor
  def initialize(dynamodb_client, table_name)
    @dynamodb = dynamodb_client
    @table_name = table_name
    @current_sessions = {}
  end

  def start_scoring(user_id)
    session_id = generate_session_id
    expires_at = (Time.now + 3600).to_i # 1 hour TTL
    current_category = ScoreCategories::CATEGORIES.keys.first

    @dynamodb.put_item({
      table_name: @table_name,
      item: {
        userId: user_id,
        sessionId: session_id,
        status: 'scoring',
        scores: {},
        currentCategory: current_category,
        createdAt: Time.now.to_i,
        expiresAt: expires_at,
        type: 'temporary'
      }
    })

    @current_sessions[user_id] = session_id
    session_id
  end

  def update_score(user_id, session_id, category, score)
    next_category = get_next_category(category)

    @dynamodb.update_item({
      table_name: @table_name,
      key: {
        userId: user_id,
        sessionId: session_id
      },
      update_expression: 'SET scores.#category = :score, currentCategory = :next_category',
      expression_attribute_names: {
        '#category' => category
      },
      expression_attribute_values: {
        ':score' => score,
        ':next_category' => next_category
      }
    })
  end

  def save_score(user_id, session_id)
    scores = get_current_scores(user_id)
    total_score = ScoreCategories.calculate_total_score(scores)

    @dynamodb.update_item({
      table_name: @table_name,
      key: {
        userId: user_id,
        sessionId: session_id
      },
      update_expression: 'REMOVE expiresAt SET type = :type, totalScore = :total',
      expression_attribute_values: {
        ':type' => 'permanent',
        ':total' => total_score
      }
    })

    @current_sessions.delete(user_id)
  end

  def get_current_scores(user_id)
    session_id = get_current_session_id(user_id)
    return {} unless session_id

    result = @dynamodb.get_item({
      table_name: @table_name,
      key: {
        userId: user_id,
        sessionId: session_id
      }
    })

    result.item&.dig('scores') || {}
  end

  def get_current_category(user_id)
    session_id = get_current_session_id(user_id)
    return nil unless session_id

    result = @dynamodb.get_item({
      table_name: @table_name,
      key: {
        userId: user_id,
        sessionId: session_id
      }
    })

    result.item&.dig('currentCategory')
  end

  def get_current_session_id(user_id)
    @current_sessions[user_id]
  end

  def get_user_scores(user_id, limit = 5)
    result = @dynamodb.query({
      table_name: @table_name,
      index_name: 'UserScoreIndex',
      key_condition_expression: 'userId = :userId',
      expression_attribute_values: {
        ':userId' => user_id
      },
      scan_index_forward: false,
      limit: limit
    })

    result.items || []
  end

  def get_next_category(current_category)
    categories = ScoreCategories::CATEGORIES.keys
    current_index = categories.index(current_category)
    return nil unless current_index
    categories[current_index + 1]
  end

  private

  def generate_session_id
    "session_#{Time.now.to_i}_#{SecureRandom.hex(4)}"
  end
end