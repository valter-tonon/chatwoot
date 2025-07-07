require 'net/http'
require 'json'

class Llm::DeepSeekService < Llm::BaseAiService
  DEFAULT_MODEL = 'deepseek-chat'.freeze
  BASE_URL = 'https://api.deepseek.com/v1'.freeze

  def chat(parameters:)
    # Adaptar parâmetros do OpenAI para DeepSeek
    deepseek_params = adapt_chat_parameters(parameters)
    
    uri = URI("#{BASE_URL}/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request.body = deepseek_params.to_json

    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "DeepSeek API Error: #{response.code} - #{response.body}"
    end
  end

  def embeddings(parameters:)
    # DeepSeek não tem API de embeddings nativa, usar OpenAI como fallback
    raise "DeepSeek doesn't support embeddings. Please use OpenAI for embedding features."
  end

  private

  def setup_client
    @api_key = get_api_key('CAPTAIN_DEEPSEEK_API_KEY')
  rescue StandardError => e
    raise "Failed to initialize DeepSeek client: #{e.message}"
  end

  def setup_model
    @model = get_model('CAPTAIN_DEEPSEEK_MODEL', DEFAULT_MODEL)
  end

  def model
    @model
  end

  def adapt_chat_parameters(params)
    adapted = params.dup
    adapted[:model] = @model
    
    # DeepSeek suporta parâmetros similares ao OpenAI
    # mas pode ter algumas diferenças na API
    adapted
  end
end 