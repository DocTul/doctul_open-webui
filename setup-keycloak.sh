#!/bin/bash

# ========================================
# Setup Keycloak para OpenWebUI
# ========================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log "🔐 Configurando Keycloak para OpenWebUI..."

# Criar docker-compose para Keycloak
cat > docker-compose.keycloak.yml << 'EOF'
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    container_name: keycloak
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=admin123
      - KC_HOSTNAME_STRICT=false
      - KC_HOSTNAME_STRICT_HTTPS=false
      - KC_HTTP_ENABLED=true
    ports:
      - "9090:8080"
    command: 
      - start-dev
      - --http-port=8080
    volumes:
      - keycloak_data:/opt/keycloak/data
    networks:
      - openwebui-network

volumes:
  keycloak_data:

networks:
  openwebui-network:
    external: true
EOF

info "📁 Arquivo docker-compose.keycloak.yml criado"

# Instruções de configuração
cat > KEYCLOAK_SETUP.md << 'EOF'
# Configuração do Keycloak para OpenWebUI

## 1. Iniciar Keycloak
```bash
docker-compose -f docker-compose.keycloak.yml up -d
```

## 2. Acessar Admin Console
- URL: http://localhost:9090
- User: admin
- Password: admin123

## 3. Criar Realm 'openwebui'
1. Clique em "Add realm"
2. Nome: openwebui
3. Clique em "Create"

## 4. Criar Client 'open-webui'
1. Clients → Create client
2. Client ID: open-webui
3. Client protocol: openid-connect
4. Access Type: confidential
5. Valid Redirect URIs: http://localhost:3000/*
6. Root URL: http://localhost:3000

## 5. Obter Client Secret
1. Clients → open-webui → Credentials
2. Copiar o Secret
3. Atualizar OAUTH_CLIENT_SECRET no docker-compose.yml

## 6. Configurar URLs de acesso
- Admin Console (você): http://localhost:9090
- OpenWebUI acessa: http://keycloak:8080 (comunicação interna)
- Usuários acessam: http://localhost:3000

## 7. Criar Grupos e Usuários
### Grupos:
- admin (acesso total)
- user (acesso limitado)
- viewer (apenas visualização)

### Usuários de exemplo:
- admin@company.com → grupo admin
- user@company.com → grupo user

## 8. Configurar Group Mapper
1. Clients → open-webui → Client scopes → open-webui-dedicated
2. Mappers → Add builtin
3. Selecionar "groups"
4. Salvar

## 9. Testar
1. Acessar http://localhost:3000
2. Verá botão "Keycloak Login"
3. Login anônimo = user limitado
4. Login via Keycloak = permissões baseadas no grupo

## Vantagens da mesma rede Docker:
✅ Comunicação interna rápida (keycloak:8080)
✅ Sem problemas de conectividade
✅ Maior segurança (comunicação interna)
✅ Easier deployment
EOF

info "📚 Guia de configuração criado: KEYCLOAK_SETUP.md"

# Criar script de inicialização completa
cat > start-with-keycloak.sh << 'EOF'
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
EOF

chmod +x start-with-keycloak.sh

info "🚀 Script start-with-keycloak.sh criado"

log "🎉 Setup do Keycloak concluído!"
echo
info "📋 Próximos passos:"
info "   1. Execute: ./start-with-keycloak.sh"
info "   2. Siga o guia: KEYCLOAK_SETUP.md"
info "   3. Configure grupos e usuários no Keycloak"
echo
warn "💡 Depois da configuração você terá:"
warn "   • Acesso anônimo → usuário limitado"
warn "   • Login Keycloak → admin/user baseado no grupo"
warn "   • Signup controlado pelo Keycloak"
