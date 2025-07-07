# Integração de Múltiplos Provedores de IA no Captain

## Visão Geral

O Captain do Chatwoot foi estendido para suportar múltiplos provedores de IA, permitindo alternar entre OpenAI, DeepSeek e Google Gemini através de uma interface administrativa simples.

## Arquitetura

### Estrutura de Classes

```
Llm::BaseAiService (classe abstrata)
├── Llm::OpenAiService
├── Llm::DeepSeekService
└── Llm::GeminiService
```

### Classe Base (`enterprise/app/services/llm/base_ai_service.rb`)

A classe base fornece o método factory `create_client()` que seleciona automaticamente o provedor baseado na configuração:

```ruby
class Llm::BaseAiService
  def self.create_client
    case Rails.configuration.llm['ai_provider']
    when 'openai'
      Llm::OpenAiService.new
    when 'deepseek'
      Llm::DeepSeekService.new
    when 'gemini'
      Llm::GeminiService.new
    else
      Llm::OpenAiService.new
    end
  end
end
```

### Implementações dos Provedores

#### OpenAI (`enterprise/app/services/llm/open_ai_service.rb`)
- **Endpoint**: https://api.openai.com/v1
- **Modelo padrão**: gpt-4o-mini
- **Configuração**: `CAPTAIN_OPENAI_API_KEY`

#### DeepSeek (`enterprise/app/services/llm/deep_seek_service.rb`)
- **Endpoint**: https://api.deepseek.com/v1
- **Modelo padrão**: deepseek-chat
- **Configuração**: `CAPTAIN_DEEPSEEK_API_KEY`

#### Google Gemini (`enterprise/app/services/llm/gemini_service.rb`)
- **Endpoint**: https://generativelanguage.googleapis.com/v1beta
- **Modelo padrão**: gemini-2.0-flash-exp
- **Configuração**: `CAPTAIN_GEMINI_API_KEY`

## Configuração

### 1. Variáveis de Ambiente

Adicione as seguintes configurações no seu arquivo `.env`:

```bash
# Provedor de IA (openai, deepseek, gemini)
CAPTAIN_AI_PROVIDER=gemini

# OpenAI
CAPTAIN_OPENAI_API_KEY=sk-...
CAPTAIN_OPENAI_MODEL=gpt-4o-mini

# DeepSeek
CAPTAIN_DEEPSEEK_API_KEY=sk-...
CAPTAIN_DEEPSEEK_MODEL=deepseek-chat

# Google Gemini
CAPTAIN_GEMINI_API_KEY=AIzaSy...
CAPTAIN_GEMINI_MODEL=gemini-2.0-flash-exp
```

### 2. Configuração via Interface Web

1. Acesse o painel de super administrador
2. Navegue para `/super_admin/app_config?config=captain`
3. Selecione o provedor desejado no dropdown
4. Configure as credenciais específicas do provedor
5. Salve as configurações

### 3. Arquivo de Configuração

As configurações são definidas em `config/installation_config.yml`:

```yaml
captain:
  ai_provider:
    name: 'CAPTAIN_AI_PROVIDER'
    description: 'Provider for Captain AI service'
    value: 'openai'
    
  openai_api_key:
    name: 'CAPTAIN_OPENAI_API_KEY'
    description: 'API key for OpenAI'
    value: ''
    
  deepseek_api_key:
    name: 'CAPTAIN_DEEPSEEK_API_KEY'
    description: 'API key for DeepSeek'
    value: ''
    
  gemini_api_key:
    name: 'CAPTAIN_GEMINI_API_KEY'
    description: 'API key for Google Gemini'
    value: ''
```

## Uso

### Integração Automática

O sistema seleciona automaticamente o provedor configurado. Todos os serviços que usam IA (chat assistant, embedding, etc.) utilizam a nova arquitetura:

```ruby
# Em qualquer serviço que precisa de IA
client = Llm::BaseAiService.create_client
response = client.chat(messages: messages)
```

### Serviços Integrados

- **Captain::Llm::AssistantChatService**: Conversas do assistente
- **Captain::Llm::EmbeddingService**: Geração de embeddings
- **Captain::Copilot::ChatService**: Copilot do Captain

## Características Específicas dos Provedores

### OpenAI
- ✅ Suporte completo a chat completion
- ✅ Embeddings
- ✅ Streaming de respostas
- 💰 Custo por token

### DeepSeek
- ✅ API compatível com OpenAI
- ✅ Modelos especializados em código
- 💰 Custo competitivo
- 🌐 Endpoint: `https://api.deepseek.com/v1`

### Google Gemini
- ✅ Modelos avançados de última geração
- ✅ Suporte a múltiplas linguagens
- ⚠️ Parsing especial para respostas JSON em markdown
- 🆓 Tier gratuito generoso
- 🌐 Endpoint: `https://generativelanguage.googleapis.com/v1beta`

## Tratamento de Respostas

### Gemini - Parsing Especial

O Gemini às vezes retorna JSON envolvido em markdown. O sistema automaticamente detecta e limpa essas respostas:

```ruby
def parse_response(response)
  content = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
  
  # Remove markdown wrapping se presente
  if content&.start_with?('```json') && content&.end_with?('```')
    content = content.gsub(/^```json\n/, '').gsub(/\n```$/, '')
  end
  
  JSON.parse(content)
end
```

## Troubleshooting

### Problemas Comuns

1. **Erro "uninitialized constant"**
   - Verifique se todas as classes estão no namespace correto
   - Confirme que os arquivos estão no diretório `enterprise/app/services/llm/`

2. **API Key inválida**
   - Verifique se a chave está correta para o provedor selecionado
   - Confirme se o provedor está selecionado corretamente

3. **Erro de parsing JSON (Gemini)**
   - O sistema automaticamente trata respostas em markdown
   - Se persistir, verifique os logs para ver o formato da resposta

### Logs de Debug

Para debugar problemas, adicione logs nos serviços:

```ruby
Rails.logger.info "Using AI provider: #{Rails.configuration.llm['ai_provider']}"
Rails.logger.info "Response content: #{content}"
```

## Extensibilidade

### Adicionando Novos Provedores

1. **Crie a classe do serviço**:
```ruby
# enterprise/app/services/llm/novo_provedor_service.rb
class Llm::NovoProvedorService < Llm::BaseAiService
  def initialize
    # Configuração específica do provedor
  end
  
  def chat(messages:)
    # Implementação do chat
  end
end
```

2. **Atualize a classe base**:
```ruby
# Adicione o case no método create_client
when 'novo_provedor'
  Llm::NovoProvedorService.new
```

3. **Adicione configurações**:
```yaml
# config/installation_config.yml
novo_provedor_api_key:
  name: 'CAPTAIN_NOVO_PROVEDOR_API_KEY'
  description: 'API key for Novo Provedor'
  value: ''
```

4. **Atualize a interface administrativa**:
```erb
<!-- app/views/super_admin/app_configs/show.html.erb -->
<option value="novo_provedor">Novo Provedor</option>
```

## Testes

### Teste Manual via Playground

1. Acesse o Captain no Chatwoot
2. Envie uma mensagem de teste
3. Verifique se a resposta é gerada pelo provedor correto
4. Monitore os logs para confirmar o provedor usado

### Exemplo de Resposta de Teste

**Mensagem**: "Olá, você pode me ajudar?"

**Resposta Esperada (Gemini)**:
"Olá! Eu sou o Assistente Gemini, um assistente amigável e experiente do produto ConvertoChat. Para te ajudar da melhor forma, por favor, compartilhe sua pergunta sobre o ConvertoChat."

## Segurança

### Proteção de API Keys

- ✅ API keys são armazenadas como variáveis de ambiente
- ✅ Interface administrativa requer autenticação de super admin
- ✅ Logs não expõem credenciais sensíveis

### Validação de Entrada

- ✅ Validação de provedor selecionado
- ✅ Verificação de presença da API key
- ✅ Tratamento de erros de API

## Performance

### Considerações

- **OpenAI**: Latência moderada, alta qualidade
- **DeepSeek**: Latência baixa, boa para código
- **Gemini**: Latência variável, excelente para texto

### Monitoramento

Monitore métricas como:
- Tempo de resposta por provedor
- Taxa de erro por provedor
- Custo por requisição
- Volume de tokens consumidos

## Conclusão

A integração de múltiplos provedores de IA no Captain oferece flexibilidade para escolher o melhor provedor baseado em:

- **Custo**: DeepSeek < Gemini < OpenAI
- **Qualidade**: Varia por caso de uso
- **Latência**: Varia por provedor e região
- **Recursos**: Cada provedor tem especialidades

O sistema é extensível e permite fácil adição de novos provedores conforme necessário. 