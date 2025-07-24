#!/bin/bash

# ========================================
# OpenWebUI - Verificador de Sistema
# ========================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

echo "🔍 Verificando estado do sistema OpenWebUI + Keycloak..."
echo

# 1. Verificar containers órfãos
info "1. Verificando containers órfãos..."
ORPHANS=$(docker ps -a --filter "name=openwebui" --format "{{.Names}}" | grep -v "^openwebui$" || true)
if [ -n "$ORPHANS" ]; then
    warn "Containers órfãos encontrados:"
    echo "$ORPHANS" | while read container; do
        if [ -n "$container" ]; then
            echo "  - $container"
        fi
    done
    echo
    read -p "Remover containers órfãos? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$ORPHANS" | while read container; do
            if [ -n "$container" ]; then
                info "Removendo $container..."
                docker rm -f "$container" 2>/dev/null || true
            fi
        done
        success "Containers órfãos removidos"
    fi
else
    success "Nenhum container órfão encontrado"
fi

echo

# 2. Verificar estado dos containers principais
info "2. Verificando containers principais..."

# Keycloak
if docker ps --format "{{.Names}}" | grep -q "^keycloak$"; then
    success "Keycloak: ✅ Rodando"
    KEYCLOAK_STATUS="running"
elif docker ps -a --format "{{.Names}}" | grep -q "^keycloak$"; then
    warn "Keycloak: ⏸️  Parado"
    KEYCLOAK_STATUS="stopped"
else
    warn "Keycloak: ❌ Não encontrado"
    KEYCLOAK_STATUS="missing"
fi

# OpenWebUI
if docker ps --format "{{.Names}}" | grep -q "^openwebui$"; then
    success "OpenWebUI: ✅ Rodando"
    OPENWEBUI_STATUS="running"
elif docker ps -a --format "{{.Names}}" | grep -q "^openwebui$"; then
    warn "OpenWebUI: ⏸️  Parado"
    OPENWEBUI_STATUS="stopped"
else
    warn "OpenWebUI: ❌ Não encontrado"
    OPENWEBUI_STATUS="missing"
fi

echo

# 3. Verificar configuração Keycloak
info "3. Verificando configuração Keycloak..."
if grep -q "OAUTH_CLIENT_SECRET=" docker-compose.yml && ! grep -q "OAUTH_CLIENT_SECRET=seu_client_secret_aqui" docker-compose.yml; then
    CLIENT_SECRET=$(grep "OAUTH_CLIENT_SECRET=" docker-compose.yml | cut -d'=' -f2 | tr -d ' "')
    if [ ${#CLIENT_SECRET} -gt 10 ]; then
        success "Client Secret: ✅ Configurado (${#CLIENT_SECRET} caracteres)"
        SECRET_STATUS="configured"
    else
        warn "Client Secret: ⚠️  Muito curto"
        SECRET_STATUS="invalid"
    fi
else
    warn "Client Secret: ❌ Não configurado"
    SECRET_STATUS="missing"
fi

echo

# 4. Verificar APIs externas
info "4. Verificando APIs externas..."
if curl -s http://localhost:8001/health > /dev/null 2>&1 || curl -s http://localhost:8001/v1/models > /dev/null 2>&1; then
    success "API Principal (8001): ✅ Disponível"
    API_8001="available"
else
    warn "API Principal (8001): ❌ Não disponível"
    API_8001="unavailable"
fi

if curl -s http://localhost:8002/health > /dev/null 2>&1 || curl -s http://localhost:8002/v1/models > /dev/null 2>&1; then
    success "API Embedding (8002): ✅ Disponível"
    API_8002="available"
else
    warn "API Embedding (8002): ❌ Não disponível"
    API_8002="unavailable"
fi

echo

# 5. Verificar rede Docker
info "5. Verificando rede Docker..."
if docker network ls | grep -q "openwebui-network"; then
    success "Rede openwebui-network: ✅ Criada"
    NETWORK_STATUS="exists"
else
    warn "Rede openwebui-network: ❌ Não encontrada"
    NETWORK_STATUS="missing"
fi

echo

# 6. Resumo e recomendações
echo "📊 RESUMO DO SISTEMA:"
echo "=================="

if [ "$KEYCLOAK_STATUS" = "running" ] && [ "$OPENWEBUI_STATUS" = "running" ] && [ "$SECRET_STATUS" = "configured" ]; then
    success "🎉 Sistema completamente funcional!"
    echo "   🌐 OpenWebUI: http://localhost:3000"
    echo "   🔐 Keycloak: http://localhost:9090"
    echo "   ✅ Integração SSO ativa"
elif [ "$OPENWEBUI_STATUS" = "running" ] && [ "$SECRET_STATUS" != "configured" ]; then
    warn "⚠️  OpenWebUI rodando SEM integração Keycloak"
    echo "   🌐 OpenWebUI: http://localhost:3000 (apenas acesso anônimo)"
    echo "   💡 Para ativar Keycloak: ./start-with-keycloak.sh"
elif [ "$KEYCLOAK_STATUS" = "running" ] && [ "$OPENWEBUI_STATUS" != "running" ]; then
    warn "⚠️  Keycloak rodando, OpenWebUI parado"
    echo "   💡 Para iniciar OpenWebUI: ./start.sh"
else
    warn "⚠️  Sistema não está rodando"
    echo "   💡 Para iniciar tudo: ./start-with-keycloak.sh"
fi

echo

echo "🛠️  COMANDOS ÚTEIS:"
echo "=================="
echo "• Iniciar sistema completo: ./start-with-keycloak.sh"
echo "• Iniciar apenas OpenWebUI: ./start.sh"
echo "• Parar tudo: ./stop-advanced.sh"
echo "• Configurar Client Secret: ./update-secret.sh SEU_SECRET"
echo "• Este diagnóstico: ./system-check.sh"

echo
