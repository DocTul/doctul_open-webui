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

## Configurações de Ambiente
No seu `docker-compose.yml`, configure o client Keycloak:

```yaml
environment:
  WEBUI_AUTH: "false"
  ENABLE_OAUTH_SIGNUP: "true"
  ENABLE_SIGNUP: "false"
  ENABLE_LOGIN_FORM: "false"
  OAUTH_CLIENT_ID: open-webui
  OAUTH_CLIENT_SECRET: <SECRET>
  OPENID_PROVIDER_URL: http://keycloak:8080/realms/openwebui/.well-known/openid-configuration
  OAUTH_GROUPS_CLAIM: "groups"
```

## Vantagens da mesma rede Docker:
✅ Comunicação interna rápida (keycloak:8080)
✅ Sem problemas de conectividade
✅ Maior segurança (comunicação interna)
✅ Easier deployment
