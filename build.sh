#!/bin/bash

# Script de build local para o Chatwoot (sem deploy para DockerHub)
set -e

echo "🔨 Iniciando build do Chatwoot..."

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
IMAGE_NAME="chatwoot"
TAG="${VERSION:-latest}"
LOCAL_IMAGE_NAME="$IMAGE_NAME:$TAG"
DOCKERFILE_PATH="docker/Dockerfile"

echo "🏷️  Versão da imagem: $TAG"
echo "📦 Nome da imagem local: $LOCAL_IMAGE_NAME"

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

# Nota: O build do frontend é feito automaticamente durante o build da imagem Docker
# através do Vite Rails, não é necessário executar manualmente
echo "ℹ️  O build do frontend será feito automaticamente durante o build da imagem Docker"

# Remove containers e imagens antigas (opcional)
echo "🧹 Limpando containers e imagens antigas..."
docker compose -f docker-compose.auttus.yaml down --remove-orphans 2>/dev/null || true
docker rmi $LOCAL_IMAGE_NAME 2>/dev/null || true

# Build da imagem Docker
echo "🔨 Construindo imagem Docker..."
docker build -f $DOCKERFILE_PATH -t $LOCAL_IMAGE_NAME .

# Verifica se o build foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "✅ Build da imagem Docker concluído com sucesso!"
    echo "📦 Imagem criada: $LOCAL_IMAGE_NAME"
    echo ""
    echo "🚀 Para executar a aplicação usando docker-compose:"
    echo "   docker-compose -f docker-compose.auttus.yaml up -d"
    echo ""
    echo "📊 Para ver logs:"
    echo "   docker-compose -f docker-compose.auttus.yaml logs -f"
    echo ""
    echo "🔄 Para reconstruir e reiniciar:"
    echo "   docker-compose -f docker-compose.auttus.yaml up -d --build"
    echo ""
    echo "🔍 Para verificar a qualidade do código:"
    echo "   bundle exec rubocop"
    echo "   pnpm run eslint"
    echo ""
    echo "✅ Build finalizado!"
else
    echo "❌ Erro durante o build da imagem Docker!"
    exit 1
fi

