#!/bin/bash

echo "🚀 SETUP COMPLETO - REDE COMPARTILHADA CORRIGIDA"
echo "================================================="
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

    # Criar cliente openwebui
    echo "🔧 Criando cliente 'openwebui'..."
    curl -s -X POST http://localhost:9090/admin/realms/openwebui/clients \
      -H "Authorization: Bearer $token" \
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

echo "📋 CORREÇÃO DE REDE APLICADA:"
echo "   ✅ Ambos os containers usarão 'openwebui-network'"
echo "   ✅ Rede será criada automaticamente com driver bridge"
echo "   ✅ Comunicação interna via hostname 'keycloak:8080'"
echo ""
echo "📋 PROCESSO COMPLETO:"
echo "   1. Parar containers existentes"
echo "   2. Remover redes antigas"
echo "   3. Subir Keycloak (criará a network correta)"
echo "   4. Configurar realm e cliente"
echo "   5. Obter Client Secret"
echo "   6. Atualizar docker-compose.yml"
echo "   7. Subir OpenWebUI na MESMA rede"
echo ""

# Limpar containers e redes existentes
echo "🧹 Limpando configuração anterior..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose.keycloak.yml down 2>/dev/null || true

# Remover redes antigas se existirem
docker network rm doctul_open-webui_openwebui-network 2>/dev/null || true
docker network rm openwebui-network 2>/dev/null || true

# Etapa 1: Subir Keycloak (criará a network automaticamente)
echo "🔐 Subindo Keycloak..."
docker-compose -f docker-compose.keycloak.yml up -d

# Aguardar rede ser criada
sleep 3

# Verificar se a rede foi criada
echo "🔍 Verificando rede criada..."
docker network ls | grep openwebui

# Etapa 2: Aguardar e configurar Keycloak
if wait_for_keycloak; then
    if configure_keycloak; then
        # Etapa 3: Atualizar compose
        update_compose_with_secret
        
        # Etapa 4: Subir OpenWebUI na MESMA rede
        echo "🚀 Subindo OpenWebUI na mesma rede..."
        docker-compose up --build -d
        
        # Aguardar container subir
        sleep 5
        
        # Verificar containers na mesma rede
        echo ""
        echo "🔍 VERIFICAÇÃO DE REDE:"
        echo "📡 Redes ativas:"
        docker network ls | grep openwebui
        
        echo ""
        echo "📦 Containers na rede 'openwebui-network':"
        docker network inspect $(docker network ls | grep openwebui | awk '{print $1}') | grep -A 5 "Containers"
        
        echo ""
        echo "🧪 TESTE DE CONECTIVIDADE:"
        echo "   Testando comunicação OpenWebUI → Keycloak..."
        docker exec openwebui curl -s http://keycloak:8080/health && echo "✅ Comunicação OK!" || echo "❌ Falha na comunicação"
        
        echo ""
        echo "🎉 SETUP COMPLETO FINALIZADO!"
        echo ""
        echo "📋 INFORMAÇÕES IMPORTANTES:"
        echo "   🌐 OpenWebUI: http://localhost:3000"
        echo "   🔐 Keycloak Admin: http://localhost:9090/admin/"
        echo "   👤 Admin Keycloak: admin/admin123"
        echo "   🔑 Client Secret: $CLIENT_SECRET"
        echo "   🌐 Rede compartilhada: openwebui-network"
        echo ""
        echo "🎯 PRÓXIMOS PASSOS:"
        echo "   1. Acesse OpenWebUI e crie usuário admin local"
        echo "   2. Teste o botão 'Continue with Keycloak Login'"
        echo "   3. Verifique que ambos compartilham a mesma rede"
        
    else
        echo "❌ Erro na configuração do Keycloak"
        exit 1
    fi
else
    echo "❌ Erro ao inicializar Keycloak"
    exit 1
fi
