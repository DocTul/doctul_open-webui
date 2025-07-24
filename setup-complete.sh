#!/bin/bash

echo "🚀 SETUP COMPLETO - OpenWebUI + Keycloak (Sequência Correta)"
echo "=================================================================="
echo ""

# Função para aguardar Keycloak estar pronto
wait_for_keycloak() {
    echo "⏳ Aguardando Keycloak inicializar..."
    local count=0
    while ! curl -s http://localhost:9090/health > /dev/null 2>&1; do
        if [ $count -ge 60 ]; then
            echo "❌ Timeout aguardando Keycloak"
            return 1
        fi
        echo "   Tentativa $((count+1))/60..."
        sleep 5
        ((count++))
    done
    echo "✅ Keycloak pronto!"
    return 0
}

# Função para configurar Keycloak via API
configure_keycloak() {
    echo "🔧 Configurando Keycloak..."
    
    # Obter token de admin
    echo "🔐 Obtendo token de admin..."
    local token=$(curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=admin&password=admin123&grant_type=password&client_id=admin-cli" | \
      python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('access_token', ''))" 2>/dev/null)

    if [ -z "$token" ]; then
        echo "❌ Erro ao obter token de admin"
        return 1
    fi
    
    echo "✅ Token obtido!"
    
    # Criar realm openwebui
    echo "🏰 Criando realm 'openwebui'..."
    curl -s -X POST http://localhost:9090/admin/realms \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{
        "realm": "openwebui",
        "displayName": "OpenWebUI Authentication",
        "enabled": true,
        "registrationAllowed": true,
        "loginWithEmailAllowed": true,
        "resetPasswordAllowed": true,
        "rememberMe": true,
        "verifyEmail": false
      }' > /dev/null

    # Criar cliente open-webui (conforme documentação oficial)
    echo "🔧 Criando cliente 'open-webui'..."
    curl -s -X POST http://localhost:9090/admin/realms/openwebui/clients \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{
        "clientId": "open-webui",
        "name": "OpenWebUI Client",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "",
        "standardFlowEnabled": true,
        "directAccessGrantsEnabled": false,
        "implicitFlowEnabled": false,
        "serviceAccountsEnabled": false,
        "publicClient": false,
        "protocol": "openid-connect",
        "redirectUris": ["http://localhost:3000/oauth/oidc/callback"],
        "webOrigins": ["http://localhost:3000"]
        "rootUrl": "http://localhost:3000"
      }' > /dev/null

    # Obter Client Secret
    echo "🔍 Obtendo Client Secret..."
    local client_data=$(curl -s -X GET "http://localhost:9090/admin/realms/openwebui/clients?clientId=openwebui" \
      -H "Authorization: Bearer $token")
    
    local client_id=$(echo "$client_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data else '')" 2>/dev/null)
    
    if [ -n "$client_id" ]; then
        local secret_data=$(curl -s -X GET "http://localhost:9090/admin/realms/openwebui/clients/$client_id/client-secret" \
          -H "Authorization: Bearer $token")
        
        CLIENT_SECRET=$(echo "$secret_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('value', ''))" 2>/dev/null)
        
        if [ -n "$CLIENT_SECRET" ]; then
            echo "✅ Client Secret obtido: $CLIENT_SECRET"
            return 0
        fi
    fi
    
    echo "❌ Erro ao obter Client Secret"
    return 1
}

# Função para atualizar docker-compose.yml com o secret
update_compose_with_secret() {
    echo "📝 Atualizando docker-compose.yml com Client Secret..."
    
    # Backup do arquivo original
    cp docker-compose.yml docker-compose.yml.backup
    
    # Atualizar CLIENT_ID para 'openwebui' (não 'open-webui')
    sed -i 's/OAUTH_CLIENT_ID=open-webui/OAUTH_CLIENT_ID=openwebui/' docker-compose.yml
    
    # Atualizar o Client Secret
    sed -i "s/OAUTH_CLIENT_SECRET=.*/OAUTH_CLIENT_SECRET=$CLIENT_SECRET/" docker-compose.yml
    
    echo "✅ docker-compose.yml atualizado!"
    echo "   🔧 Client ID: openwebui"
    echo "   🔐 Client Secret: $CLIENT_SECRET"
}

# ==========================================
# EXECUÇÃO DO PROCESSO COMPLETO
# ==========================================

echo "📋 PROCESSO COMPLETO:"
echo "   1. Subir Keycloak (criará a network)"
echo "   2. Configurar realm e cliente"
echo "   3. Obter Client Secret"
echo "   4. Atualizar docker-compose.yml"
echo "   5. Subir OpenWebUI configurado"
echo ""

# Etapa 1: Subir Keycloak (criará a network automaticamente)
echo "🔐 Subindo Keycloak..."
docker-compose -f docker-compose.keycloak.yml up -d

# Etapa 3: Aguardar e configurar Keycloak
if wait_for_keycloak; then
    if configure_keycloak; then
        # Etapa 4: Atualizar compose
        update_compose_with_secret
        
        # Etapa 5: Subir OpenWebUI
        echo "🚀 Subindo OpenWebUI com configuração completa..."
        docker-compose up --build -d
        
        echo ""
        echo "🎉 SETUP COMPLETO FINALIZADO!"
        echo ""
        echo "📋 INFORMAÇÕES IMPORTANTES:"
        echo "   🌐 OpenWebUI: http://localhost:3000"
        echo "   🔐 Keycloak Admin: http://localhost:9090/admin/"
        echo "   👤 Admin Keycloak: admin/admin123"
        echo "   🔑 Client Secret: $CLIENT_SECRET"
        echo ""
        echo "🎯 PRÓXIMOS PASSOS:"
        echo "   1. Acesse OpenWebUI e crie usuário admin local"
        echo "   2. Teste o botão 'Continue with Keycloak Login'"
        echo "   3. Configure usuários no Keycloak se necessário"
        
    else
        echo "❌ Erro na configuração do Keycloak"
        exit 1
    fi
else
    echo "❌ Erro ao inicializar Keycloak"
    exit 1
fi
