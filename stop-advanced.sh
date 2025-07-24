#!/bin/bash

# ========================================
# OpenWebUI - Script de Parada Avançada
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

log "🛑 Parando todos os containers OpenWebUI..."

# Encontrar todos os containers que contenham "openwebui" no nome
CONTAINERS=$(docker ps -a --filter "name=openwebui" --format "{{.Names}}" | grep -i openwebui || true)

if [ -z "$CONTAINERS" ]; then
    warn "❌ Nenhum container OpenWebUI encontrado"
    exit 0
fi

info "🔍 Containers encontrados:"
echo "$CONTAINERS" | while read container; do
    if [ -n "$container" ]; then
        echo "  - $container"
    fi
done

# Processar cada container
echo "$CONTAINERS" | while read container; do
    if [ -z "$container" ]; then
        continue
    fi
    
    info "🎯 Processando container: $container"
    
    # Verificar se está rodando
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        info "🔍 Container $container está rodando - tentando parar..."
        
        # Tentar kill múltiplas vezes até o container aparecer como Exited
        MAX_ATTEMPTS=10
        ATTEMPT=1
        
        while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
            # Obter o PID atual do container a cada tentativa
            PID=$(docker inspect "$container" --format '{{.State.Pid}}' 2>/dev/null)
            
            if [ "$PID" != "0" ] && [ -n "$PID" ]; then
                info "� Tentativa $ATTEMPT/$MAX_ATTEMPTS - Obtendo PID atual: $PID"
                info "💀 Enviando kill -9 para PID $PID do container $container"
                sudo kill -9 $PID 2>/dev/null || true
            else
                warn "⚠️  PID não encontrado para $container na tentativa $ATTEMPT"
                break
            fi
            
            # Aguardar 2 segundos
            sleep 2
            
            # Verificar se o container está como Exited
            STATUS=$(docker ps -a --filter "name=$container" --format "{{.Status}}" 2>/dev/null)
            if [[ "$STATUS" =~ ^Exited ]]; then
                info "✅ Container $container aparece como Exited: $STATUS"
                break
            fi
            
            # Verificar se o container ainda está rodando
            if ! docker ps --format "{{.Names}}" | grep -q "^$container$"; then
                info "✅ Container $container não está mais rodando"
                break
            fi
            
            warn "⏳ Container $container ainda rodando - tentativa $ATTEMPT falhou"
            ATTEMPT=$((ATTEMPT + 1))
        done
        
        if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
            error "❌ Falha após $MAX_ATTEMPTS tentativas - tentando docker stop forçado"
            docker stop "$container" --time=0 2>/dev/null || true
            sleep 3
        fi
        
        info "✅ Processo de parada do $container concluído"
        else
            warn "⚠️  PID não encontrado para $container - tentando docker stop"
            docker stop "$container" --time=0 2>/dev/null || true
            sleep 2
        fi
    else
        info "⚠️  Container $container não está rodando"
    fi
    
    # Verificar status final e remover o container
    FINAL_STATUS=$(docker ps -a --filter "name=$container" --format "{{.Status}}" 2>/dev/null)
    info "📊 Status final do container $container: $FINAL_STATUS"
    
    # Remover o container
    info "🗑️  Removendo container $container..."
    if docker rm "$container" 2>/dev/null; then
        info "✅ Container $container removido com sucesso"
    else
        warn "⚠️  Erro na remoção - tentando remoção forçada"
        if docker rm -f "$container" 2>/dev/null; then
            info "✅ Container $container removido com força"
        else
            error "❌ Falha na remoção do container $container"
        fi
    fi
done

# Limpeza adicional (opcional)
echo
read -p "Deseja fazer limpeza geral do Docker? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "🧹 Fazendo limpeza geral..."
    docker system prune -f
    info "✅ Limpeza concluída"
fi

log "🎉 Todos os containers OpenWebUI foram parados e removidos!"
echo
info "📝 Para reiniciar: ./start.sh ou ./start-with-keycloak.sh"
