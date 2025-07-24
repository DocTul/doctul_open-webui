#!/bin/bash

echo "🔧 Configurando Keycloak para OpenWebUI..."

# Aguardar um pouco para garantir que o Keycloak está pronto
sleep 3

# Função para obter token de admin
get_admin_token() {
    curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" | \
      python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('access_token', ''))" 2>/dev/null
}

echo "🔐 Obtendo token de administrador..."
TOKEN=$(get_admin_token)

if [ -z "$TOKEN" ]; then
    echo "❌ Erro: Não foi possível obter token do admin"
    echo "💡 Verificando credenciais do Keycloak..."
    
    # Tentar com senha padrão admin123
    TOKEN=$(curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=admin&password=admin123&grant_type=password&client_id=admin-cli" | \
      python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('access_token', ''))" 2>/dev/null)
fi

if [ -z "$TOKEN" ]; then
    echo "❌ Erro: Credenciais do admin não funcionaram"
    echo "📋 Configure manualmente:"
    echo "   1. Acesse: http://localhost:9090/admin/"
    echo "   2. Login com admin/admin ou admin/admin123"
    echo "   3. Siga o guia KEYCLOAK_SETUP.md"
    exit 1
fi

echo "✅ Token obtido com sucesso!"

# Criar realm openwebui
echo "🏰 Criando realm 'openwebui'..."
REALM_RESPONSE=$(curl -s -X POST http://localhost:9090/admin/realms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "openwebui",
    "displayName": "OpenWebUI Authentication",
    "enabled": true,
    "registrationAllowed": true,
    "loginWithEmailAllowed": true,
    "resetPasswordAllowed": true,
    "rememberMe": true,
    "verifyEmail": false,
    "loginTheme": "keycloak",
    "accountTheme": "keycloak",
    "adminTheme": "keycloak",
    "emailTheme": "keycloak"
  }' -w "%{http_code}")

if [[ "$REALM_RESPONSE" == *"201"* ]] || [[ "$REALM_RESPONSE" == *"409"* ]]; then
    echo "✅ Realm criado/existe"
else
    echo "⚠️  Realm response: $REALM_RESPONSE"
fi

# Criar cliente openwebui
echo "🔧 Criando cliente 'openwebui'..."
CLIENT_RESPONSE=$(curl -s -X POST http://localhost:9090/admin/realms/openwebui/clients \
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
    "baseUrl": "http://localhost:3000",
    "rootUrl": "http://localhost:3000",
    "adminUrl": "http://localhost:3000",
    "attributes": {
      "post.logout.redirect.uris": "http://localhost:3000"
    }
  }' -w "%{http_code}")

if [[ "$CLIENT_RESPONSE" == *"201"* ]] || [[ "$CLIENT_RESPONSE" == *"409"* ]]; then
    echo "✅ Cliente criado/existe"
else
    echo "⚠️  Cliente response: $CLIENT_RESPONSE"
fi

# Obter ID do cliente
echo "🔍 Obtendo dados do cliente..."
CLIENT_DATA=$(curl -s -X GET "http://localhost:9090/admin/realms/openwebui/clients?clientId=openwebui" \
  -H "Authorization: Bearer $TOKEN")

CLIENT_ID=$(echo "$CLIENT_DATA" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data else '')" 2>/dev/null)

if [ -n "$CLIENT_ID" ]; then
    # Obter secret do cliente
    SECRET_DATA=$(curl -s -X GET "http://localhost:9090/admin/realms/openwebui/clients/$CLIENT_ID/client-secret" \
      -H "Authorization: Bearer $TOKEN")
    
    CLIENT_SECRET=$(echo "$SECRET_DATA" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('value', ''))" 2>/dev/null)
    
    echo "🔑 CLIENT_SECRET: $CLIENT_SECRET"
else
    echo "❌ Erro ao obter ID do cliente"
fi

# Criar grupos
echo "👥 Criando grupos..."
curl -s -X POST http://localhost:9090/admin/realms/openwebui/groups \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "admin", "attributes": {"role": ["admin"]}}' > /dev/null

curl -s -X POST http://localhost:9090/admin/realms/openwebui/groups \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "user", "attributes": {"role": ["user"]}}' > /dev/null

echo "✅ Grupos criados!"

# Testar configuração
echo "🧪 Testando configuração..."
TEST_CONFIG=$(curl -s http://localhost:9090/realms/openwebui/.well-known/openid_configuration)
if [[ "$TEST_CONFIG" == *"authorization_endpoint"* ]]; then
    echo "✅ Configuração OpenID funcional!"
else
    echo "❌ Erro na configuração OpenID"
fi

echo ""
echo "🎉 Keycloak configurado com sucesso!"
echo ""
echo "📋 Informações importantes:"
echo "   🌐 Keycloak Admin: http://localhost:9090/admin/"
echo "   🔑 Login Admin: admin/admin (ou admin123)"
echo "   🏰 Realm: openwebui"
echo "   🔧 Client ID: openwebui"
if [ -n "$CLIENT_SECRET" ]; then
    echo "   🔐 Client Secret: $CLIENT_SECRET"
    echo ""
    echo "⚡ PRÓXIMO PASSO:"
    echo "   Atualize o docker-compose.yml com o Client Secret:"
    echo "   OAUTH_CLIENT_SECRET=$CLIENT_SECRET"
else
    echo "   🔐 Client Secret: Obter manualmente no admin"
fi
echo ""
echo "🔄 Depois execute: docker-compose restart openwebui"
