class Llm::BaseAiService
  class << self
    def create_client
      provider = InstallationConfig.find_by(name: 'CAPTAIN_AI_PROVIDER')&.value || 'openai'
      
      case provider.downcase
      when 'openai'
        Llm::OpenAiService.new
      when 'deepseek'
        Llm::DeepSeekService.new
      when 'gemini'
        Llm::GeminiService.new
      else
        raise "Unsupported AI provider: #{provider}"
      end
    end
  end

  def initialize
    setup_client
    setup_model
  end
  
  def model
    @model
  end

  def chat(parameters:)
    raise NotImplementedError, "Subclasses must implement the 'chat' method"
  end

  def embeddings(parameters:)
    raise NotImplementedError, "Subclasses must implement the 'embeddings' method"
  end

  private

  def setup_client
    raise NotImplementedError, "Subclasses must implement the 'setup_client' method"
  end

  def setup_model
    raise NotImplementedError, "Subclasses must implement the 'setup_model' method"
  end

  def get_api_key(config_name)
    InstallationConfig.find_by!(name: config_name).value
  rescue ActiveRecord::RecordNotFound
    raise "#{config_name} not configured"
  end

  def get_model(config_name, default_model)
    InstallationConfig.find_by(name: config_name)&.value.presence || default_model
  end
end 