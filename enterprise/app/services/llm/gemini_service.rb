require 'net/http'
require 'json'

class Llm::GeminiService < Llm::BaseAiService
  DEFAULT_MODEL = 'gemini-2.0-flash'.freeze
  BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'.freeze

  def chat(parameters:)
    # Adaptar parâmetros do OpenAI para Gemini
    gemini_params = adapt_chat_parameters(parameters)
    
    uri = URI("#{BASE_URL}/models/#{@model}:generateContent?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = gemini_params.to_json

    response = http.request(request)
    
    if response.code == '200'
      adapt_gemini_response(JSON.parse(response.body))
    else
      raise "Gemini API Error: #{response.code} - #{response.body}"
    end
  end

  def embeddings(parameters:)
    # Gemini tem API de embeddings própria
    embed_params = adapt_embedding_parameters(parameters)
    
    uri = URI("#{BASE_URL}/models/text-embedding-004:embedContent?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = embed_params.to_json

    response = http.request(request)
    
    if response.code == '200'
      adapt_embedding_response(JSON.parse(response.body))
    else
      raise "Gemini Embedding API Error: #{response.code} - #{response.body}"
    end
  end

  private

  def setup_client
    @api_key = get_api_key('CAPTAIN_GEMINI_API_KEY')
  rescue StandardError => e
    raise "Failed to initialize Gemini client: #{e.message}"
  end

  def setup_model
    @model = get_model('CAPTAIN_GEMINI_MODEL', DEFAULT_MODEL)
  end

  def adapt_chat_parameters(params)
    # Converter formato OpenAI para Gemini
    messages = params[:messages] || []
    
    contents = messages.map do |msg|
      {
        role: msg[:role] == 'assistant' ? 'model' : 'user',
        parts: [{ text: msg[:content] }]
      }
    end

    {
      contents: contents,
      generationConfig: {
        temperature: params[:temperature] || 0.7,
        maxOutputTokens: params[:max_tokens] || 1000
      }
    }
  end

  def adapt_gemini_response(response)
    # Converter resposta Gemini para formato OpenAI
    content = response.dig('candidates', 0, 'content', 'parts', 0, 'text') || ''
    
    {
      'choices' => [
        {
          'message' => {
            'role' => 'assistant',
            'content' => content
          },
          'finish_reason' => 'stop'
        }
      ],
      'usage' => {
        'prompt_tokens' => response.dig('usageMetadata', 'promptTokenCount') || 0,
        'completion_tokens' => response.dig('usageMetadata', 'candidatesTokenCount') || 0,
        'total_tokens' => response.dig('usageMetadata', 'totalTokenCount') || 0
      }
    }
  end

  def adapt_embedding_parameters(params)
    {
      content: {
        parts: [{ text: params[:input] }]
      }
    }
  end

  def adapt_embedding_response(response)
    # Converter resposta de embedding Gemini para formato OpenAI
    embedding = response.dig('embedding', 'values') || []
    
    {
      'data' => [
        {
          'embedding' => embedding,
          'index' => 0
        }
      ],
      'usage' => {
        'total_tokens' => response.dig('usageMetadata', 'totalTokenCount') || 0
      }
    }
  end
end 