#!/bin/bash

# Garantir que estamos no diretório correto do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔄 Resetando dados do OpenWebUI (preservando Keycloak)..."
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

# LIMPAR DADOS PERSISTENTES - AQUI ESTÁ A DIFERENÇA!
echo "🧹 Removendo dados persistentes do OpenWebUI..."
docker volume rm openwebui-data 2>/dev/null || echo "Volume openwebui-data não encontrado"

# Limpar imagem OpenWebUI
echo "🧹 Limpando imagem OpenWebUI antiga..."
docker rmi doctul_open-webui-openwebui 2>/dev/null || echo "Imagem OpenWebUI não encontrada"

# Verificar se Keycloak ainda está rodando
if docker ps | grep -q keycloak; then
    echo "✅ Keycloak ainda está rodando (preservado)"
else
    echo "⚠️  Keycloak não está rodando!"
fi

echo "🚀 Recriando OpenWebUI com dados limpos..."
docker-compose up -d --build openwebui

echo "⏳ Aguardando OpenWebUI inicializar..."
sleep 15

# Verificar se subiu
if docker ps | grep -q openwebui; then
    echo "✅ OpenWebUI resetado com sucesso!"
    echo "🌐 Acesse: http://localhost:3000"
    echo "🔐 Agora DEVE aparecer tela de cadastro do primeiro admin + botão Keycloak"
    echo ""
    echo "📋 INSTRUÇÕES:"
    echo "   1. Crie um usuário admin local (primeira vez)"
    echo "   2. Depois aparecerá o botão 'Keycloak Login'"
    echo "   3. Ou acesse em aba privada para ver direto o botão Keycloak"
else
    echo "❌ Falha ao resetar OpenWebUI"
fi
