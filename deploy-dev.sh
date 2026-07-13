#!/bin/bash

# Script de deploy otimizado para o Chatwoot
set -e

echo "🚀 Iniciando deploy do Chatwoot em modo DEVELOPMENT..."

# Verifica se o pnpm está instalado
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm não está instalado. Instale o pnpm e tente novamente."
    exit 1
fi

# Verifica se o Ruby está instalado (opcional - só necessário para testes/linting local)
HAS_RUBY=false
HAS_BUNDLE=false
if command -v ruby &> /dev/null; then
    HAS_RUBY=true
    if command -v bundle &> /dev/null; then
        HAS_BUNDLE=true
    fi
fi

if [ "$HAS_RUBY" = false ] || [ "$HAS_BUNDLE" = false ]; then
    echo "⚠️  Ruby/Bundle não encontrado localmente. O build será feito apenas via Docker."
    echo "💡 Para executar testes/linting localmente, instale Ruby e Bundler."
    SKIP_RUBY_OPS=true
else
    SKIP_RUBY_OPS=false
fi

# Verifica se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Inicie o Docker e tente novamente."
    exit 1
fi

# Carrega variáveis do .env se existir
if [ -f .env ]; then
    echo "📄 Carregando variáveis do arquivo .env..."
    set -a
    source .env
    set +a
    echo "✅ Variáveis do .env carregadas!"
fi

# Configurações
DOCKER_USERNAME="ottiv"
DOCKER_TOKEN="${DOCKER_TOKEN:-}"  # Deve ser fornecido via variável de ambiente ou .env
IMAGE_NAME="chatwoot-dev"

# Valida se o DOCKER_TOKEN foi fornecido
if [ -z "$DOCKER_TOKEN" ]; then
    echo "❌ DOCKER_TOKEN não foi fornecido!"
    echo "💡 Configure a variável DOCKER_TOKEN no arquivo .env ou como variável de ambiente."
    exit 1
fi

# Lê a versão do .env, variável de ambiente ou usa "latest" como padrão
TAG="${VERSION:-latest}"
FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$TAG"
DOCKERFILE_PATH="docker/Dockerfile"

echo "🏷️  Versão da imagem: $TAG"
echo "📦 Nome completo da imagem: $FULL_IMAGE_NAME"

# Instala dependências Ruby apenas se disponível
if [ "$SKIP_RUBY_OPS" = false ]; then
    echo "📦 Instalando dependências Ruby..."
    bundle install

    if [ $? -ne 0 ]; then
        echo "❌ Erro na instalação das dependências Ruby!"
        exit 1
    fi

    echo "✅ Dependências Ruby instaladas com sucesso!"
else
    echo "⏭️  Pulando instalação de dependências Ruby (não disponível localmente)"
fi

echo "📦 Instalando dependências Node.js..."
pnpm install

if [ $? -ne 0 ]; then
    echo "❌ Erro na instalação das dependências Node.js!"
    exit 1
fi

echo "✅ Dependências Node.js instaladas com sucesso!"

# Verifica se deve executar testes (opcional)
if [ "${RUN_TESTS:-false}" = "true" ] && [ "$SKIP_RUBY_OPS" = false ]; then
    echo "🧪 Executando testes Ruby..."
    bundle exec rspec --format documentation

    if [ $? -ne 0 ]; then
        echo "❌ Erro nos testes Ruby!"
        exit 1
    fi

    echo "✅ Testes Ruby concluídos com sucesso!"
elif [ "${RUN_TESTS:-false}" = "true" ] && [ "$SKIP_RUBY_OPS" = true ]; then
    echo "⏭️  Pulando testes Ruby (Ruby não disponível localmente)"
fi

# Verifica se deve executar linting Ruby
if [ "${RUN_RUBOCOP:-true}" = "true" ] && [ "$SKIP_RUBY_OPS" = false ]; then
    echo "🔍 Executando linting Ruby (RuboCop)..."
    bundle exec rubocop -a

    if [ $? -ne 0 ]; then
        echo "⚠️  Avisos no linting Ruby encontrados, mas continuando..."
    else
        echo "✅ Linting Ruby concluído com sucesso!"
    fi
elif [ "${RUN_RUBOCOP:-true}" = "true" ] && [ "$SKIP_RUBY_OPS" = true ]; then
    echo "⏭️  Pulando linting Ruby (Ruby não disponível localmente)"
fi

# Verifica se deve executar linting JavaScript
if [ "${RUN_ESLINT:-true}" = "true" ]; then
    echo "🔍 Executando linting JavaScript..."
    pnpm run eslint || true

    if [ $? -ne 0 ]; then
        echo "⚠️  Avisos no linting JavaScript encontrados, mas continuando..."
    else
        echo "✅ Linting JavaScript concluído com sucesso!"
    fi
fi

# Nota: Em modo development, o build do frontend NÃO é feito durante o build da imagem
# O Vite dev server será usado em tempo de execução para servir os assets
echo "ℹ️  Modo DEVELOPMENT: Assets serão servidos via Vite dev server em tempo de execução"

# Login no DockerHub
echo "🔑 Fazendo login no DockerHub..."
echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin

if [ $? -ne 0 ]; then
    echo "❌ Erro no login do DockerHub!"
    exit 1
fi

echo "✅ Login no DockerHub realizado com sucesso!"

# Remove containers e imagens antigas (opcional)
echo "🧹 Limpando containers e imagens antigas..."
docker compose -f docker-compose.auttus.yaml down --remove-orphans 2>/dev/null || true
docker rmi $IMAGE_NAME:$TAG 2>/dev/null || true
docker rmi $FULL_IMAGE_NAME 2>/dev/null || true

# Build da imagem Docker em modo development
echo "🔨 Construindo imagem Docker em modo DEVELOPMENT..."
docker build -f $DOCKERFILE_PATH \
  --build-arg RAILS_ENV=development \
  --build-arg BUNDLE_WITHOUT="" \
  --build-arg EXECJS_RUNTIME="Node" \
  --build-arg RAILS_SERVE_STATIC_FILES="false" \
  -t $FULL_IMAGE_NAME .

# Verifica se o build foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "✅ Build da imagem Docker concluído com sucesso!"
    echo "📦 Imagem criada: $FULL_IMAGE_NAME"

    # Push da imagem para o DockerHub
    echo "📤 Enviando imagem para o DockerHub..."
    docker push $FULL_IMAGE_NAME

    if [ $? -eq 0 ]; then
        echo "✅ Deploy em modo DEVELOPMENT concluído com sucesso!"
        echo "📦 Imagem: $FULL_IMAGE_NAME"
        echo "🌐 Disponível em: https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME"
        echo ""
        echo "⚠️  IMPORTANTE: Esta é uma imagem de DESENVOLVIMENTO"
        echo "   - Assets NÃO são pré-compilados (Vite dev server será usado)"
        echo "   - Gems de development/test estão incluídas"
        echo "   - Node.js e ferramentas de build estão disponíveis"
        echo ""
        echo "🚀 No servidor remoto (primeira vez após remover volume /app):"
        echo "   # 1) Remova o volume antigo que sombreava o código (obrigatório uma vez):"
        echo "   docker service scale chatwoot_dev_chatwoot_dev=0 chatwoot_dev_chatwoot_dev_worker=0 chatwoot_dev_vite-dev=0"
        echo "   docker volume ls | grep chatwoot_dev_app"
        echo "   docker volume rm <nome_do_volume_chatwoot_dev_app>"
        echo "   # 2) Redeploy do stack (usa docker-compose-dev.yaml SEM montar /app):"
        echo "   export VERSION=$TAG"
        echo "   docker stack deploy -c docker-compose-dev.yaml chatwoot_dev"
        echo ""
        echo "🔄 Para só trocar a imagem depois disso:"
        echo "   docker service update --with-registry-auth --image $FULL_IMAGE_NAME chatwoot_dev_chatwoot_dev"
        echo "   docker service update --with-registry-auth --image $FULL_IMAGE_NAME chatwoot_dev_chatwoot_dev_worker"
        echo ""
        echo "📊 Logs: docker service logs -f chatwoot_dev_chatwoot_dev"
        echo "🔎 Confirme o fix no container: grep -n '::Ottiv::Core' /app/app/ottiv/core/controllers/api/v1/accounts/finance_negotiations_controller.rb"
        echo ""
        echo "ℹ️  O startup roda db:chatwoot_prepare (inclui migrate)."
        echo "   NÃO defina VERSION no env do container Rails — só para tag da imagem."
        echo ""
        echo "🔍 Para verificar a qualidade do código:"
        echo "   bundle exec rubocop"
        echo "   pnpm run eslint"
    else
        echo "❌ Erro durante o push para o DockerHub!"
        exit 1
    fi
else
    echo "❌ Erro durante o build da imagem Docker!"
    exit 1
fi

# Logout do DockerHub por segurança
echo "🔒 Fazendo logout do DockerHub..."
docker logout
echo "✅ Deploy finalizado!"

