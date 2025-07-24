#!/bin/bash

echo "🔑 Configuração rápida do Keycloak para OpenWebUI..."

# Aguardar Keycloak estar pronto
echo "⏳ Aguardando Keycloak..."
sleep 5

# Obter token de admin
echo "🔐 Obtendo token de admin..."
TOKEN=$(curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "❌ Erro ao obter token. Verificando Keycloak..."
    exit 1
fi

echo "✅ Token obtido!"

# Criar realm openwebui
echo "🏰 Criando realm openwebui..."
curl -s -X POST http://localhost:9090/admin/realms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "openwebui",
    "displayName": "OpenWebUI",
    "enabled": true,
    "registrationAllowed": true,
    "loginWithEmailAllowed": true,
    "resetPasswordAllowed": true
  }'

# Criar cliente openwebui
echo "🔧 Criando cliente openwebui..."
curl -s -X POST http://localhost:9090/admin/realms/openwebui/clients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "openwebui",
    "name": "OpenWebUI Client",
    "enabled": true,
    "publicClient": false,
    "directAccessGrantsEnabled": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "serviceAccountsEnabled": true,
    "protocol": "openid-connect",
    "redirectUris": ["http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"],
    "attributes": {
      "post.logout.redirect.uris": "http://localhost:3000"
    }
  }'

# Obter ID do cliente
CLIENT_ID=$(curl -s -X GET "http://localhost:9090/admin/realms/openwebui/clients?clientId=openwebui" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null)

# Obter secret do cliente
SECRET=$(curl -s -X GET "http://localhost:9090/admin/realms/openwebui/clients/$CLIENT_ID/client-secret" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['value'])" 2>/dev/null)

echo "🔑 Client Secret: $SECRET"

# Criar grupos
echo "👥 Criando grupos..."
curl -s -X POST http://localhost:9090/admin/realms/openwebui/groups \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "admin", "attributes": {"role": ["admin"]}}'

curl -s -X POST http://localhost:9090/admin/realms/openwebui/groups \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "user", "attributes": {"role": ["user"]}}'

echo "✅ Keycloak configurado!"
echo "🌐 Acesse: http://localhost:9090/admin/"
echo "🔑 Login: admin/admin"
echo "📋 Realm: openwebui"
echo "🔧 Client: openwebui"
echo "🔐 Secret: $SECRET"
