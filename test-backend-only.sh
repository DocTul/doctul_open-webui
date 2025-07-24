#!/bin/bash

# ========================================
# Script de Teste - Apenas Backend OpenWebUI
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

log "🚀 Testando OpenWebUI Backend apenas..."

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

# Parar containers anteriores (se existirem)
log "🧹 Limpando containers anteriores..."
$DOCKER_COMPOSE -f docker-compose.simple.yml down --remove-orphans || true

# Build
log "🔨 Construindo backend..."
$DOCKER_COMPOSE -f docker-compose.simple.yml build --no-cache backend

# Start
log "🌟 Iniciando backend..."
$DOCKER_COMPOSE -f docker-compose.simple.yml up -d backend

# Aguardar
log "⏳ Aguardando backend ficar pronto..."
sleep 10

# Verificar
for i in {1..30}; do
    if curl -s -f "http://localhost:8383/health" > /dev/null 2>&1; then
        info "✅ Backend está rodando!"
        break
    elif [[ $i -eq 30 ]]; then
        warn "❌ Backend demorou para responder"
    else
        sleep 2
    fi
done

log "🎉 Teste concluído!"
info "🌐 Acesse: http://localhost:8383"
info "📊 Logs: $DOCKER_COMPOSE -f docker-compose.simple.yml logs -f"
