#!/bin/bash

# ========================================
# Script de Verificação de Ambiente - OpenWebUI Separado
# ========================================

set -e

echo "🔍 Verificando ambiente para OpenWebUI separado..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar comando
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "   ✅ $1 ${GREEN}instalado${NC}"
        return 0
    else
        echo -e "   ❌ $1 ${RED}não encontrado${NC}"
        return 1
    fi
}

# Função para verificar porta
check_port() {
    local port=$1
    local service=$2
    if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        echo -e "   ⚠️  Porta $port ${YELLOW}ocupada${NC} ($service)"
        return 1
    else
        echo -e "   ✅ Porta $port ${GREEN}livre${NC} ($service)"
        return 0
    fi
}

# Função para verificar API
check_api() {
    local url=$1
    local name=$2
    if curl -s -f "$url" &> /dev/null; then
        echo -e "   ✅ $name ${GREEN}respondendo${NC}"
        return 0
    else
        echo -e "   ❌ $name ${RED}não respondendo${NC}"
        return 1
    fi
}

echo "📋 1. Verificando dependências..."
dependencies_ok=true

if ! check_command "docker"; then
    dependencies_ok=false
    echo "      Instale Docker: https://docs.docker.com/get-docker/"
fi

if ! check_command "docker-compose" && ! docker compose version &> /dev/null; then
    dependencies_ok=false
    echo "      Instale Docker Compose: https://docs.docker.com/compose/install/"
fi

if ! check_command "curl"; then
    dependencies_ok=false
    echo "      Instale curl: apt-get install curl (Ubuntu) ou yum install curl (CentOS)"
fi

if ! check_command "netstat"; then
    echo -e "   ⚠️  netstat ${YELLOW}não encontrado${NC} (opcional)"
    echo "      Para instalar: apt-get install net-tools"
fi

echo ""

echo "🔌 2. Verificando portas necessárias..."
ports_ok=true

if ! check_port "3000" "Frontend"; then
    ports_ok=false
fi

if ! check_port "8383" "Backend"; then
    ports_ok=false
fi

echo ""

echo "🌐 3. Verificando APIs externas..."
apis_ok=true

if ! check_api "http://0.0.0.0:8001/health" "API Principal (8001)"; then
    if ! check_api "http://0.0.0.0:8001/v1/models" "API Principal (8001) - endpoint alternativo"; then
        apis_ok=false
        echo "      Inicie sua API principal na porta 8001"
    fi
fi

if ! check_api "http://0.0.0.0:8002/health" "API Embedding (8002)"; then
    if ! check_api "http://0.0.0.0:8002/v1/models" "API Embedding (8002) - endpoint alternativo"; then
        apis_ok=false
        echo "      Inicie sua API de embedding na porta 8002"
    fi
fi

echo ""

echo "📁 4. Verificando arquivos de configuração..."
files_ok=true

required_files=(
    "docker-compose.separated.yml"
    "nginx-separated.conf"
    "Dockerfile.backend"
    "Dockerfile.frontend"
    "start-separated.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ✅ $file ${GREEN}encontrado${NC}"
    else
        echo -e "   ❌ $file ${RED}não encontrado${NC}"
        files_ok=false
    fi
done

if [ -f ".env.separated" ]; then
    echo -e "   ✅ .env.separated ${GREEN}encontrado${NC}"
else
    echo -e "   ⚠️  .env.separated ${YELLOW}não encontrado${NC} (será criado automaticamente)"
fi

echo ""

echo "🐳 5. Verificando Docker..."
docker_ok=true

if ! docker info &> /dev/null; then
    echo -e "   ❌ Docker daemon ${RED}não está rodando${NC}"
    docker_ok=false
    echo "      Inicie o Docker: sudo systemctl start docker"
else
    echo -e "   ✅ Docker daemon ${GREEN}rodando${NC}"
fi

# Verificar se usuário pode usar Docker sem sudo
if ! docker ps &> /dev/null; then
    echo -e "   ⚠️  Docker ${YELLOW}requer sudo${NC}"
    echo "      Para usar sem sudo: sudo usermod -aG docker \$USER && newgrp docker"
fi

echo ""

echo "📊 6. Resumo da verificação..."
echo ""

overall_ok=true

if [ "$dependencies_ok" = true ]; then
    echo -e "✅ Dependências: ${GREEN}OK${NC}"
else
    echo -e "❌ Dependências: ${RED}PROBLEMAS${NC}"
    overall_ok=false
fi

if [ "$ports_ok" = true ]; then
    echo -e "✅ Portas: ${GREEN}OK${NC}"
else
    echo -e "❌ Portas: ${RED}PROBLEMAS${NC}"
    overall_ok=false
fi

if [ "$apis_ok" = true ]; then
    echo -e "✅ APIs Externas: ${GREEN}OK${NC}"
else
    echo -e "❌ APIs Externas: ${RED}PROBLEMAS${NC}"
    overall_ok=false
fi

if [ "$files_ok" = true ]; then
    echo -e "✅ Arquivos: ${GREEN}OK${NC}"
else
    echo -e "❌ Arquivos: ${RED}PROBLEMAS${NC}"
    overall_ok=false
fi

if [ "$docker_ok" = true ]; then
    echo -e "✅ Docker: ${GREEN}OK${NC}"
else
    echo -e "❌ Docker: ${RED}PROBLEMAS${NC}"
    overall_ok=false
fi

echo ""

if [ "$overall_ok" = true ]; then
    echo -e "🎉 ${GREEN}Ambiente está pronto!${NC}"
    echo ""
    echo "Para iniciar o OpenWebUI, execute:"
    echo "   ./start-separated.sh"
else
    echo -e "⚠️  ${YELLOW}Ambiente precisa de ajustes${NC}"
    echo ""
    echo "Corrija os problemas acima antes de prosseguir."
    echo ""
    echo "📚 Recursos úteis:"
    echo "   - Docker: https://docs.docker.com/get-docker/"
    echo "   - Docker Compose: https://docs.docker.com/compose/install/"
    echo "   - OpenWebUI Docs: https://docs.openwebui.com/"
fi

echo ""
