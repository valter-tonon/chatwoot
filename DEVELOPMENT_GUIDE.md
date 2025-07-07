# O Guia Definitivo para o Desenvolvimento Local do Chatwoot com Docker

## Introdução

O Chatwoot se estabeleceu como uma peça fundamental no ecossistema de código aberto, oferecendo uma alternativa robusta e auto-hospedada a plataformas proprietárias de engajamento de clientes como Intercom, Zendesk e Salesforce Service Cloud. Construído sobre uma pilha de tecnologia moderna que inclui Ruby on Rails para o backend, Vue.js para o frontend, e PostgreSQL e Redis para persistência de dados e cache, respectivamente, o Chatwoot oferece uma plataforma escalável e multicanal. Sua extensibilidade, garantida por uma rica API REST e um sistema de webhooks, permite integrações profundas e personalizações complexas, tornando-o uma escolha atraente para empresas de todos os tamanhos.

Para desenvolvedores que desejam contribuir para este projeto de código aberto ou personalizar sua própria instância, o Docker surge como a ferramenta preferencial para criar um ambiente de desenvolvimento consistente e portátil. A containerização promete eliminar o clássico problema "funciona na minha máquina", encapsulando a aplicação e suas dependências. No entanto, a configuração de uma aplicação complexa como o Chatwoot, mesmo com Docker, está repleta de desafios e armadilhas que não são imediatamente óbvias na documentação oficial.

## Seção 1: Pré-requisitos Fundamentais e Preparação do Sistema

### Recomendações de Hardware e Sistema Operacional

As especificações mínimas para uma instância do Chatwoot são:
- 2 núcleos de CPU
- 4GB de RAM
- 20GB de armazenamento SSD

Para uma experiência de desenvolvimento fluida, recomenda-se:
- 4+ núcleos de CPU
- 8GB+ de RAM
- 50GB+ de armazenamento SSD

### Pré-requisito Crítico: Docker e Docker Compose

```bash
# Verificar versões instaladas
docker --version
docker compose version
```

### Instalação do Docker Específica do Sistema

#### Windows
A instalação deve ser feita através do Docker Desktop, com o backend WSL2 (Windows Subsystem for Linux 2) habilitado. O WSL2 oferece desempenho e compatibilidade significativamente superiores. Após a instalação, uma reinicialização do sistema é necessária.

#### macOS
Existem duas abordagens principais:
- Baixar o instalador diretamente do site do Docker
- Usar o gerenciador de pacotes Homebrew: `brew install --cask docker`

#### Linux (Ubuntu/Debian)
```bash
# Atualizar o índice de pacotes e instalar dependências
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Adicionar a chave GPG oficial do Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Configurar o repositório
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar o Docker Engine e o Compose Plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Seção 2: A Configuração Central do Ambiente de Desenvolvimento

### Aquisição do Código Fonte
```bash
# Navegue para um diretório de projetos de sua escolha
cd ~/projects

# Clone o repositório oficial do Chatwoot
git clone https://github.com/chatwoot/chatwoot.git

# Entre no diretório do projeto
cd chatwoot
```

### Desconstruindo os Arquivos de Configuração

Os arquivos principais são:
- `docker-compose.yaml`: Define a pilha de serviços para desenvolvimento
- `docker-compose.production.yaml`: Para implantações de produção (não usar para desenvolvimento)
- `.env.example`: Modelo para variáveis de ambiente

### Configuração Passo a Passo

1. Criar o arquivo .env:
```bash
cp .env.example .env
```

2. Editar o arquivo .env:
```bash
# Exemplo de edição no arquivo .env
POSTGRES_PASSWORD=umaSenhaMuitoForteParaPostgres
REDIS_PASSWORD=umaSenhaMuitoForteParaRedis
```

3. Sincronizar Senhas:
```yaml
# Exemplo de edição no arquivo docker-compose.yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: umaSenhaMuitoForteParaPostgres # <-- DEVE SER IGUAL AO .env
```

## Seção 3: Construindo e Iniciando a Pilha do Chatwoot

### O Processo de Build em Duas Fases

1. Construir a Imagem Base:
```bash
docker compose build base
```

2. Construir as Imagens da Aplicação:
```bash
docker compose build
```

### Inicialização do Banco de Dados
```bash
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

### Lançando a Pilha
```bash
docker compose up
```

### Verificando uma Inicialização Bem-sucedida

- Interface Web: http://localhost:3000
- MailHog: http://localhost:8025
- Status dos Contêineres: `docker compose ps`

## Seção 4: O Compêndio de Solução de Problemas do Desenvolvedor

### Tabela de Diagnóstico Rápido

| Fragmento da Mensagem de Erro / Sintoma | Causa(s) Provável(is) | Subseção do Relatório |
|----------------------------------------|----------------------|---------------------|
| pull access denied, repository does not exist | Uso do docker-compose.production.yaml para desenvolvimento | 4.A |
| Connection refused (para Postgres ou Redis) | Contêiner não está pronto; nome de serviço incorreto no .env | 4.B |
| FATAL: database "chatwoot_development" does not exist | O comando db:chatwoot_prepare foi pulado ou falhou | 4.B |
| listen tcp4... bind: cannot assign requested address | O Docker está tentando se vincular a um IP inexistente | 4.A |
| Address already in use - bind(2) for... port 3000 | Conflito de porta na máquina host | 4.A |
| ERR_OSSL_EVP_UNSUPPORTED | Incompatibilidade de versão do Node.js/OpenSSL | 4.B |

### Parte A: Falhas de Orquestração do Docker e Compose

#### Diagnóstico Sistemático de Falhas de Inicialização
```bash
docker compose ps
docker compose logs <nome-do-servico-com-falha>
```

#### Solucionando Erros de "Pull Access Denied"
```bash
# Limpa o cache de build do Docker
docker builder prune

# Reconstrói as imagens sem usar o cache
docker compose build --no-cache
```

#### Gerenciando Recursos do Docker
```bash
# Remove contêineres, redes e imagens não utilizados
docker system prune -f

# Remove volumes não utilizados (AVISO: isto apaga dados persistentes)
docker volume prune -f
```

### Parte B: Erros de Aplicação e Dependência

#### O Enigma da Conexão com o Banco de Dados
1. Verificar logs do PostgreSQL: `docker compose logs postgres`
2. Confirmar POSTGRES_HOST no .env está como "postgres"
3. Aguardar a inicialização completa do banco de dados

## Seção 5: Fluxo de Trabalho de Desenvolvimento Diário

### Comandos Essenciais

#### Interagindo com Sua Instância
```bash
# Console do Rails
docker compose exec rails bundle exec rails c

# Executar testes
docker compose run --rm rails bundle exec rspec

# Teste específico
docker compose run --rm rails bundle exec rspec spec/caminho/arquivo_spec.rb
```

### O Fluxo de Trabalho "Pull, Rebuild, Migrate"
```bash
git pull origin develop
docker compose down
docker compose build
docker compose run --rm rails bundle exec rails db:migrate
docker compose up
```

### Aproveitando o make para Eficiência
```bash
# Instalar/atualizar dependências
make burn

# Executar migrações
make db

# Iniciar servidor de desenvolvimento
make run

# Anexar depurador
make debug
```

## Canais de Ajuda Oficiais

- Comunidade Discord: Para suporte em tempo real e discussões com outros desenvolvedores e usuários.
- GitHub Issues: Para pesquisar relatórios de bugs existentes e criar novos relatórios detalhados.
- GitHub Discussions: Para perguntas mais amplas e sugestões de recursos.
- Documentação Oficial: A fonte primária e definitiva de informações. 