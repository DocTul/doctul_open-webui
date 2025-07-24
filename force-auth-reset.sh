#!/bin/bash

# Garantir que estamos no diretório correto do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔥 RESET COMPLETO - Forçando autenticação..."
echo "📂 Diretório de trabalho: $(pwd)"

# Obter PID do container OpenWebUI
OPENWEBUI_PID=$(docker inspect --format '{{.State.Pid}}' openwebui 2>/dev/null)

if [ -n "$OPENWEBUI_PID" ] && [ "$OPENWEBUI_PID" != "0" ]; then
    echo "📍 PID do OpenWebUI: $OPENWEBUI_PID"
    echo "🛑 Matando processo OpenWebUI..."
    sudo kill -9 $OPENWEBUI_PID
    sleep 2
else
    echo "⚠️  PID do OpenWebUI não encontrado"
fi

# Remover container OpenWebUI
echo "🗑️  Removendo container openwebui..."
docker rm -f openwebui 2>/dev/null || echo "Container openwebui não estava rodando"

# DESTRUIR COMPLETAMENTE todos os dados
echo "💣 DESTRUINDO TODOS OS DADOS PERSISTENTES..."
docker volume rm openwebui-data 2>/dev/null || echo "Volume openwebui-data já removido"
docker volume prune -f 2>/dev/null || echo "Volumes já limpos"

# Limpar imagem OpenWebUI
echo "🧹 Limpando imagem OpenWebUI..."
docker rmi doctul_open-webui-openwebui 2>/dev/null || echo "Imagem OpenWebUI já removida"

# Verificar se Keycloak ainda está rodando
if docker ps | grep -q keycloak; then
    echo "✅ Keycloak ainda está rodando (preservado)"
else
    echo "⚠️  Keycloak não está rodando!"
fi

# Criar configuração temporal forçada
echo "⚡ Criando configuração temporal para FORÇAR autenticação..."

# Backup do docker-compose original
cp docker-compose.yml docker-compose.yml.backup-$(date +%H%M%S)

# Criar configuração com WEBUI_AUTH forçado de múltiplas formas
cat > docker-compose-force-auth.yml << 'EOF'
services:
  openwebui:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: openwebui
    restart: unless-stopped
    volumes:
      - openwebui-data:/app/backend/data
    ports:
      - "3000:8080"
    environment:
      # MÚLTIPLAS FORMAS DE FORÇAR WEBUI_AUTH=true
      - WEBUI_AUTH=true
      - WEBUI_AUTH_REQUIRED=true
      - ENABLE_SIGNUP=true
      - ENABLE_LOGIN_FORM=true
      - ENABLE_LOGIN=true
      - DEFAULT_USER_ROLE=user
      - WEBUI_SECRET_KEY=force-auth-secret-key-12345
      
      # Keycloak OAuth
      - ENABLE_OAUTH_SIGNUP=true
      - OAUTH_CLIENT_ID=open-webui
      - OAUTH_CLIENT_SECRET=aPFWLGOeT2u5PuWq1T0u1K2p9FmB4bVp
      - OPENID_PROVIDER_URL=http://keycloak:8080/realms/openwebui/.well-known/openid-configuration
      - OAUTH_PROVIDER_NAME=Keycloak Login
      - OPENID_REDIRECT_URI=http://localhost:3000/oauth/oidc/callback
      - ENABLE_OAUTH_GROUP_MANAGEMENT=true
      - ENABLE_OAUTH_GROUP_CREATION=true
      - OAUTH_GROUPS_CLAIM=groups
      
      # APIs externas
      - ENABLE_OLLAMA_API=false
      - ENABLE_OPENAI_API=true
      - OPENAI_API_BASE_URL=http://host.docker.internal:8001/v1
      - OPENAI_API_BASE_URLS=http://host.docker.internal:8001/v1
      - OPENAI_API_KEY=none
      - OPENAI_API_KEYS=none
      
      # RAG/Embedding
      - RAG_EMBEDDING_ENGINE=openai
      - RAG_EMBEDDING_MODEL=intfloat/multilingual-e5-base
      - RAG_OPENAI_API_BASE_URL=http://host.docker.internal:8002/v1
      - RAG_OPENAI_API_KEY=none
      - RAG_EMBEDDING_BATCH_SIZE=32
      
      # Configurações básicas
      - PORT=8080
      - DATA_DIR=/app/backend/data
      - DOCKER=true
      - GLOBAL_LOG_LEVEL=INFO
      - RAG_LOG_LEVEL=DEBUG
      - OPENAI_LOG_LEVEL=DEBUG
      - MODELS_LOG_LEVEL=INFO
      
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - openwebui-network

volumes:
  openwebui-data:
    name: openwebui-data

networks:
  openwebui-network:
    driver: bridge
    name: openwebui-network
EOF

echo "🚀 Recriando OpenWebUI com configuração FORÇADA..."
docker-compose -f docker-compose-force-auth.yml up -d --build openwebui

echo "⏳ Aguardando OpenWebUI inicializar completamente..."
sleep 20

# Verificar se subiu
if docker ps | grep -q openwebui; then
    echo "✅ OpenWebUI recriado com configuração FORÇADA!"
    
    # Verificar variáveis de ambiente
    echo "🔍 Verificando WEBUI_AUTH..."
    WEBUI_AUTH_VALUE=$(docker exec openwebui env | grep "WEBUI_AUTH=" | cut -d'=' -f2)
    echo "   WEBUI_AUTH = $WEBUI_AUTH_VALUE"
    
    echo ""
    echo "🌐 Acesse: http://localhost:3000"
    echo "🔐 COM ESTA CONFIGURAÇÃO DEVE aparecer tela de login!"
    echo ""
    echo "📋 TESTE AGORA:"
    echo "   1. Abra uma aba PRIVADA/INCÓGNITA"
    echo "   2. Acesse http://localhost:3000"
    echo "   3. DEVE aparecer tela de cadastro OU botão Keycloak"
else
    echo "❌ Falha ao recriar OpenWebUI"
fi
