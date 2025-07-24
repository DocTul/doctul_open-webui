#!/bin/bash

# ========================================
# Atualizar Client Secret do Keycloak
# ========================================

if [ -z "$1" ]; then
    echo "❌ Uso: $0 <client-secret>"
    echo "📋 Exemplo: $0 abc123def456"
    echo ""
    echo "💡 Para obter o secret:"
    echo "   1. Acesse http://localhost:9090"
    echo "   2. Realm: openwebui"
    echo "   3. Clients → open-webui → Credentials"
    echo "   4. Copie o Secret"
    exit 1
fi

CLIENT_SECRET="$1"

echo "🔐 Atualizando Client Secret no docker-compose.yml..."

# Atualizar no docker-compose.yml
sed -i "s/OAUTH_CLIENT_SECRET=.*/OAUTH_CLIENT_SECRET=$CLIENT_SECRET/" docker-compose.yml

echo "✅ Client Secret atualizado!"
echo "🚀 Reinicie o OpenWebUI para aplicar:"
echo "   ./quick-stop.sh && ./start.sh"
