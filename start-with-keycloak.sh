#!/bin/bash

echo "🚀 Iniciando OpenWebUI + Keycloak..."

# Iniciar Keycloak
echo "🔐 Iniciando Keycloak..."
docker-compose -f docker-compose.keycloak.yml up -d

sleep 5

# Iniciar OpenWebUI
echo "🌐 Iniciando OpenWebUI..."
./start.sh

echo "✅ Tudo iniciado!"
echo ""
echo "🔗 URLs:"
echo "   OpenWebUI: http://localhost:3000"
echo "   Keycloak Admin: http://localhost:9090"
echo ""
echo "📋 Próximos passos:"
echo "   1. Configure o Keycloak seguindo KEYCLOAK_SETUP.md"
echo "   2. Atualize OAUTH_CLIENT_SECRET no docker-compose.yml"
echo "   3. Reinicie o OpenWebUI"
