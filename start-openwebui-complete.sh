#!/bin/bash

# ========================================
# Script Corrigido - OpenWebUI Completo
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

log "🚀 Iniciando OpenWebUI com arquitetura CORRETA..."
info "🔧 Usando build monolítico como o OpenWebUI foi projetado"

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

# ========================================
# Verificar APIs externas
# ========================================

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

# ========================================
# Parar configuração anterior
# ========================================

log "🧹 Parando configuração anterior (se existir)..."
$DOCKER_COMPOSE -f docker-compose.separated.yml down --remove-orphans || true

# ========================================
# Build e Start
# ========================================

log "🔨 Construindo OpenWebUI completo..."
$DOCKER_COMPOSE -f docker-compose.complete.yml build --no-cache

log "🌟 Iniciando OpenWebUI..."
$DOCKER_COMPOSE -f docker-compose.complete.yml up -d

# ========================================
# Verificações de saúde
# ========================================

log "⏳ Aguardando OpenWebUI ficar pronto..."
sleep 20

# Verificar aplicação
info "Verificando OpenWebUI..."
for i in {1..60}; do
    if curl -s -f "http://localhost:3000" > /dev/null 2>&1; then
        info "✅ OpenWebUI está rodando!"
        break
    elif [[ $i -eq 60 ]]; then
        warn "❌ OpenWebUI demorou para responder"
        info "Verificando logs..."
        $DOCKER_COMPOSE -f docker-compose.complete.yml logs --tail=20
    else
        sleep 3
    fi
done

# ========================================
# Informações finais
# ========================================

log "🎉 OpenWebUI iniciado com sucesso!"
echo
info "📱 Acesse a aplicação:"
info "   🌐 Interface: http://localhost:3000"
echo
info "📊 Para monitorar os logs:"
info "   $DOCKER_COMPOSE -f docker-compose.complete.yml logs -f"
echo
info "⏹️  Para parar:"
info "   $DOCKER_COMPOSE -f docker-compose.complete.yml down"
echo
info "🔧 Esta configuração:"
info "   • Usa o Dockerfile original do OpenWebUI"
info "   • Frontend + Backend integrados"
info "   • APIs externas nas portas 8001/8002"
info "   • Uma única aplicação na porta 3000"
echo

# Mostrar logs iniciais
log "📄 Mostrando logs iniciais..."
$DOCKER_COMPOSE -f docker-compose.complete.yml logs --tail=20
