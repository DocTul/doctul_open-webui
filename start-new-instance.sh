#!/bin/bash

# ========================================
# Script de Teste - Nova Instância OpenWebUI
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "🚀 Iniciando Nova Instância OpenWebUI Backend..."
info "📍 Esta versão usa PORTA 8384 para evitar conflitos"

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado."
fi

# Determinar comando do Docker Compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Verificar APIs externas
log "🔍 Verificando APIs externas..."

# Testar API principal
log "Testando API principal..."
if ! curl -s -f "http://localhost:8001/v1/models" > /dev/null 2>&1; then
    warn "API principal na porta 8001 não está respondendo."
    warn "Certifique-se de que o modelo principal esteja rodando em http://localhost:8001"
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Cancelado pelo usuário."
    fi
else
    info "✅ API principal respondeu corretamente!"
fi

# Testar API de embedding
log "Testando API de embedding..."
EMBEDDING_TEST=$(curl -s -X POST "http://localhost:8002/v1/embeddings" \
    -H "Content-Type: application/json" \
    -d '{"model": "test", "input": ["test"]}' 2>/dev/null)

if [[ $? -ne 0 ]] || [[ -z "$EMBEDDING_TEST" ]]; then
    warn "API de embedding na porta 8002 não está respondendo."
    warn "Certifique-se de que o modelo de embedding esteja rodando em http://localhost:8002"
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Cancelado pelo usuário."
    fi
else
    info "✅ API de embedding respondeu corretamente!"
fi

# Build
log "🔨 Construindo nova instância..."
$DOCKER_COMPOSE -f docker-compose.new.yml build --no-cache backend-new

# Start
log "🌟 Iniciando nova instância..."
$DOCKER_COMPOSE -f docker-compose.new.yml up -d backend-new

# Aguardar
log "⏳ Aguardando backend ficar pronto..."
sleep 15

# Verificar
info "Verificando nova instância..."
for i in {1..30}; do
    if curl -s -f "http://localhost:8384/health" > /dev/null 2>&1; then
        info "✅ Nova instância está rodando!"
        break
    elif [[ $i -eq 30 ]]; then
        warn "❌ Nova instância demorou para responder"
        info "Verificando logs..."
        $DOCKER_COMPOSE -f docker-compose.new.yml logs --tail=20 backend-new
    else
        sleep 2
    fi
done

log "🎉 Nova instância iniciada!"
echo
info "📱 Acesse a nova instância:"
info "   🌐 Interface: http://localhost:8384"
echo
info "📊 Para monitorar os logs:"
info "   $DOCKER_COMPOSE -f docker-compose.new.yml logs -f backend-new"
echo
info "⏹️  Para parar:"
info "   $DOCKER_COMPOSE -f docker-compose.new.yml down"
echo
info "🔧 Diferenças desta versão:"
info "   • Porta: 8384 (em vez de 8383)"
info "   • Container: openwebui-backend-new"
info "   • Volume: backend-data-new"
info "   • Rede: openwebui-network-new"
