class Llm::ModelListService
  PROVIDERS = {
    'openai' => {
      url: 'https://api.openai.com/v1/models',
      key_config: 'CAPTAIN_OPEN_AI_API_KEY',
      auth: :bearer
    },
    'gemini' => {
      url: 'https://generativelanguage.googleapis.com/v1/models',
      key_config: 'CAPTAIN_GEMINI_API_KEY',
      auth: :query
    },
    'deepseek' => {
      url: 'https://api.deepseek.com/v1/models',
      key_config: 'CAPTAIN_DEEPSEEK_API_KEY',
      auth: :bearer
    }
  }.freeze

  OPENAI_CHAT_PREFIXES = %w[gpt- o1 o3 o4 chatgpt].freeze
  GEMINI_CHAT_METHODS = %w[generateContent].freeze

  def initialize(provider)
    @provider = provider
    @config = PROVIDERS[provider]
  end

  def perform
    return { error: 'Provider não suportado' } unless @config

    api_key = InstallationConfig.find_by(name: @config[:key_config])&.value
    return { error: 'API key não configurada' } unless api_key.present?

    models = fetch_models(api_key)
    { models: models }
  rescue StandardError => e
    Rails.logger.error("Llm::ModelListService error for #{@provider}: #{e.message}")
    { error: "Falha ao buscar modelos: #{e.message}" }
  end

  private

  def fetch_models(api_key)
    case @provider
    when 'gemini'
      fetch_gemini_models(api_key)
    when 'openai'
      fetch_openai_models(api_key)
    when 'deepseek'
      fetch_deepseek_models(api_key)
    else
      []
    end
  end

  def fetch_gemini_models(api_key)
    uri = URI("#{@config[:url]}?key=#{api_key}&pageSize=100")
    response = make_request(uri)
    data = JSON.parse(response.body)

    (data['models'] || [])
      .select { |m| (m['supportedGenerationMethods'] || []).any? { |method| GEMINI_CHAT_METHODS.include?(method) } }
      .map { |m| { id: m['name'].sub('models/', ''), name: m['displayName'] || m['name'].sub('models/', '') } }
      .sort_by { |m| m[:name] }
  end

  def fetch_openai_models(api_key)
    uri = URI(@config[:url])
    response = make_request(uri, bearer_token: api_key)
    data = JSON.parse(response.body)

    (data['data'] || [])
      .select { |m| OPENAI_CHAT_PREFIXES.any? { |prefix| m['id'].start_with?(prefix) } }
      .reject { |m| m['id'].include?('realtime') || m['id'].include?('audio') || m['id'].include?('instruct') }
      .map { |m| { id: m['id'], name: m['id'] } }
      .sort_by { |m| m[:name] }
  end

  def fetch_deepseek_models(api_key)
    uri = URI(@config[:url])
    response = make_request(uri, bearer_token: api_key)
    data = JSON.parse(response.body)

    (data['data'] || [])
      .map { |m| { id: m['id'], name: m['id'] } }
      .sort_by { |m| m[:name] }
  end

  def make_request(uri, bearer_token: nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{bearer_token}" if bearer_token

    response = http.request(request)
    raise "HTTP #{response.code}: #{response.body.truncate(200)}" unless response.is_a?(Net::HTTPSuccess)

    response
  end
end
