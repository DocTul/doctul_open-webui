# OpenWebUI - Configuração: Acesso Direto (Sem Login)

## 🎯 Configuração Atual

**WEBUI_AUTH=false**: Acesso direto ao prompt sem necessidade de login ou registro.

### ✅ Características
- **Acesso instantâneo**: Usuários vão direto ao prompt
- **Sem barreiras**: Nenhum login, registro ou autenticação
- **Simplicidade máxima**: Ideal para demos, testes rápidos ou ambientes controlados
- **Funcionalidade completa**: Todos os recursos do OpenWebUI disponíveis

### ⚠️ Importante
- **Todos são admin**: Com `WEBUI_AUTH=false`, todos acessam com permissões de administrador
- **Sem controle de acesso**: Qualquer pessoa pode usar todas as funcionalidades
- **Sem auditoria**: Não há controle de quem fez o quê

## 🚀 Como Usar

### Acesso
1. **URL**: http://localhost:3000
2. **Login**: NÃO necessário
3. **Resultado**: Vai direto para o chat/prompt

### Comandos
```bash
# Iniciar
./start.sh

# Ver logs
docker-compose logs -f

# Parar
docker-compose down

# Reiniciar
docker-compose restart
```

## 🔧 Configurações Técnicas

```yaml
# docker-compose.yml
environment:
  - WEBUI_AUTH=false           # Desabilita autenticação
  - ENABLE_SIGNUP=false        # Desabilita registro
  - ENABLE_LOGIN_FORM=false    # Remove formulário de login
  - ENABLE_API_KEY=false       # Desabilita API keys
  - DEFAULT_USER_ROLE=user     # Sem efeito quando AUTH=false
```

## 🌐 APIs Externas Configuradas

- **API Principal**: localhost:8001 (modelos de chat)
- **API Embedding**: localhost:8002 (RAG/documentos)
- **Ollama**: DESABILITADO

## 🎯 Esta Configuração é Ideal Para:

### ✅ Cenários Apropriados
- **Demos e apresentações**
- **Ambiente de desenvolvimento/testes**
- **Uso interno em rede controlada**
- **Prototipagem rápida**
- **Acesso público controlado (kiosks, etc.)**

### ❌ NÃO Recomendado Para
- **Produção na internet**
- **Dados sensíveis**
- **Múltiplos usuários que precisam de separação**
- **Compliance/auditoria necessária**

## 🔒 Para Ambientes de Produção

Se precisar de controle de acesso, use uma das alternativas:

### Opção A: Login Simples
```yaml
- WEBUI_AUTH=true
- DEFAULT_USER_ROLE=user
```

### Opção B: Proxy de Autenticação
Use nginx, traefik ou outro proxy para autenticação externa.

### Opção C: OAuth/LDAP
```yaml
- ENABLE_OAUTH_SIGNUP=true
- OAUTH_PROVIDERS=google,github
```

## 📋 Status

- **Implementado**: ✅ Funcionando
- **Testado**: ✅ Acesso direto confirmado
- **Documentado**: ✅ Este arquivo
- **Pronto para uso**: ✅ Execute `./start.sh`

---

**Acesso**: http://localhost:3000 (direto ao prompt, sem login)
