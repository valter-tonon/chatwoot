require 'openai'

class Llm::OpenAiService < Llm::BaseAiService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze

  def chat(parameters:)
    @client.chat(parameters: parameters)
  end

  def embeddings(parameters:)
    @client.embeddings(parameters: parameters)
  end

  private

  def setup_client
    @client = OpenAI::Client.new(
      access_token: get_api_key('CAPTAIN_OPEN_AI_API_KEY'),
      log_errors: Rails.env.development?
    )
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  def setup_model
    @model = get_model('CAPTAIN_OPEN_AI_MODEL', DEFAULT_MODEL)
  end
end 