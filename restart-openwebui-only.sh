#!/bin/bash

# Garantir que estamos no diretório correto do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔄 Reiniciando apenas OpenWebUI (preservando Keycloak)..."
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

# Remover container OpenWebUI (se existir)
echo "🗑️  Removendo container openwebui..."
docker rm -f openwebui 2>/dev/null || echo "Container openwebui não estava rodando"

# Limpar apenas imagens do OpenWebUI (não remove Keycloak)
echo "🧹 Limpando imagem OpenWebUI antiga..."
docker rmi doctul_open-webui-openwebui 2>/dev/null || echo "Imagem OpenWebUI não encontrada"

# Verificar se Keycloak ainda está rodando
if docker ps | grep -q keycloak; then
    echo "✅ Keycloak ainda está rodando (preservado)"
else
    echo "⚠️  Keycloak não está rodando!"
fi

echo "🚀 Recriando OpenWebUI com configurações OAuth..."
docker-compose up -d --build openwebui

echo "⏳ Aguardando OpenWebUI inicializar..."
sleep 10

# Verificar se subiu
if docker ps | grep -q openwebui; then
    echo "✅ OpenWebUI reiniciado com sucesso!"
    echo "🌐 Acesse: http://localhost:3000"
    echo "🔐 Agora deve aparecer o botão 'Keycloak Login'"
else
    echo "❌ Falha ao reiniciar OpenWebUI"
fi
