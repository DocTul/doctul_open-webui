#!/bin/bash

# ========================================
# OpenWebUI - Script de Parada Forçada
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Navegar para o diretório do script
cd "$(dirname "$0")"

log "🛑 Parando OpenWebUI de forma forçada..."

# Verificar se o container existe
if ! docker ps -a --format "table {{.Names}}" | grep -q "^openwebui$"; then
    warn "❌ Container 'openwebui' não encontrado"
    exit 0
fi

# Verificar se o container está rodando
if docker ps --format "table {{.Names}}" | grep -q "^openwebui$"; then
    info "🔍 Container encontrado - tentando parar..."
    
    # Tentar kill múltiplas vezes até o container aparecer como Exited
    MAX_ATTEMPTS=10
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        # Obter o PID atual do container a cada tentativa
        PID=$(docker inspect openwebui --format '{{.State.Pid}}' 2>/dev/null)
        
        if [ "$PID" != "0" ] && [ -n "$PID" ]; then
            info "� Tentativa $ATTEMPT/$MAX_ATTEMPTS - Obtendo PID atual: $PID"
            info "💀 Enviando kill -9 para PID $PID"
            sudo kill -9 $PID 2>/dev/null || true
        else
            warn "⚠️  PID não encontrado na tentativa $ATTEMPT - container pode ter parado"
            break
        fi
        
        # Aguardar 2 segundos
        sleep 2
        
        # Verificar se o container está como Exited
        STATUS=$(docker ps -a --filter "name=openwebui" --format "{{.Status}}" 2>/dev/null)
        if [[ "$STATUS" =~ ^Exited ]]; then
            info "✅ Container aparece como Exited: $STATUS"
            break
        fi
        
        # Verificar se o container ainda está rodando
        if ! docker ps --format "table {{.Names}}" | grep -q "^openwebui$"; then
            info "✅ Container não está mais na lista de containers rodando"
            break
        fi
        
        warn "⏳ Container ainda rodando - tentativa $ATTEMPT falhou"
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
        error "❌ Falha após $MAX_ATTEMPTS tentativas - tentando docker stop forçado"
        docker stop openwebui --time=0 2>/dev/null || true
        sleep 3
    fi
    
    info "✅ Processo de parada concluído"
else
    info "⚠️  Container não está rodando"
fi

# Verificar status final e remover o container
FINAL_STATUS=$(docker ps -a --filter "name=openwebui" --format "{{.Status}}" 2>/dev/null)
info "📊 Status final do container: $FINAL_STATUS"

# Remover o container
info "🗑️  Removendo container..."
if docker rm openwebui 2>/dev/null; then
    info "✅ Container removido com sucesso"
else
    warn "⚠️  Container já foi removido ou erro na remoção"
    # Tentar remoção forçada
    if docker rm -f openwebui 2>/dev/null; then
        info "✅ Container removido com força"
    else
        error "❌ Falha na remoção do container"
    fi
fi

# Limpeza adicional (opcional)
read -p "Deseja fazer limpeza geral do Docker? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "🧹 Fazendo limpeza geral..."
    docker system prune -f
    info "✅ Limpeza concluída"
fi

log "🎉 OpenWebUI parado e removido com sucesso!"
echo
info "📝 Para reiniciar: ./start.sh"
