#!/bin/bash

# ========================================
# OpenWebUI - Configuração Original com APIs Externas
# ========================================

set -e

# Navegar para o diretório do script
cd "$(dirname "$0")"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log "🚀 Iniciando OpenWebUI com APIs Externas..."
info "📋 Usando arquitetura original (monolítica) - única forma que funciona"

# Verificar APIs externas (opcional)
if curl -s -f "http://localhost:8001/v1/models" > /dev/null 2>&1; then
    info "✅ API principal (8001) está rodando"
else
    warn "⚠️  API principal (8001) não detectada - configure antes de usar"
fi

if curl -s -X POST "http://localhost:8002/v1/embeddings" \
    -H "Content-Type: application/json" \
    -d '{"model": "test", "input": ["test"]}' > /dev/null 2>&1; then
    info "✅ API embedding (8002) está rodando"
else
    warn "⚠️  API embedding (8002) não detectada - configure antes de usar RAG"
fi

# Determinar comando Docker Compose
if docker-compose version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Build e Start
log "🔨 Construindo OpenWebUI..."
$DOCKER_COMPOSE -f docker-compose.yml build

log "🌟 Iniciando OpenWebUI..."
$DOCKER_COMPOSE -f docker-compose.yml up -d

# Aguardar
log "⏳ Aguardando OpenWebUI ficar pronto..."
sleep 15

# Verificar
for i in {1..30}; do
    if curl -s -f "http://localhost:3000" > /dev/null 2>&1; then
        info "✅ OpenWebUI está rodando!"
        break
    elif [[ $i -eq 30 ]]; then
        warn "❌ OpenWebUI demorou para responder"
    else
        sleep 2
    fi
done

# Informações finais
log "🎉 OpenWebUI iniciado!"
echo
info "🌐 Acesse: http://localhost:3000"
info "📊 Logs: $DOCKER_COMPOSE -f docker-compose.yml logs -f"
info "⏹️  Parar: $DOCKER_COMPOSE -f docker-compose.yml down"
echo
info "🔧 Configuração:"
info "   • OpenWebUI completo na porta 3000"
info "   • API externa principal: localhost:8001"
info "   • API externa embedding: localhost:8002"
info "   • Ollama: DESABILITADO"
info "   • Autenticação: HABILITADA (Keycloak + Acesso direto)"
echo
info "🚀 ACESSO HÍBRIDO:"
info "   👤 URL: http://localhost:3000"
info "   🔐 Login Keycloak: Clique em 'Keycloak Login' (grupos: admin/user/viewer)"
info "   👥 Acesso direto: Disponível como usuário limitado"
warn "💡 Configure o Keycloak seguindo KEYCLOAK_SETUP.md para login com grupos"
