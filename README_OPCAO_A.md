# OpenWebUI - Configuração Opção A: Login Automático

## 🎯 Configuração Atual

**Opção A**: Sistema de login habilitado com usuários pré-configurados para acesso fácil.

### ✅ Vantagens
- **Segurança**: Acesso controlado por usuários específicos
- **Flexibilidade**: Admin e users com permissões diferentes
- **Facilidade**: Login rápido com credenciais pré-definidas
- **Auditoria**: Controle de quem acessa e faz o quê

## 🚀 Como Usar

### 1. Iniciar OpenWebUI
```bash
./start.sh
```

### 2. Configurar Usuários Padrão
```bash
./setup_users.sh
```

### 3. Acessar
- **URL**: http://localhost:3000
- **Login obrigatório**: Sim

## 👥 Usuários Criados

### 👨‍💼 Administrador
- **Email**: `admin@localhost`
- **Senha**: `admin123`
- **Permissões**: 
  - Gerenciar usuários
  - Configurar modelos
  - Acessar logs
  - Configurações avançadas

### 👤 Usuário Padrão
- **Email**: `user@localhost`
- **Senha**: `user123`
- **Permissões**:
  - Usar chat
  - Upload de documentos
  - Histórico pessoal
  - Funcionalidades básicas

## 🔧 Configurações Importantes

```yaml
# Autenticação habilitada
- WEBUI_AUTH=true

# Novos usuários são automaticamente 'user'
- DEFAULT_USER_ROLE=user

# Login expira em 24h
- JWT_EXPIRES_IN=86400

# Registro liberado para novos usuários
- ENABLE_SIGNUP=true
```

## 🛡️ Segurança

### ⚠️ Senhas Padrão
**IMPORTANTE**: As senhas `admin123` e `user123` são **apenas para demonstração**.

### 🔐 Para Produção
1. **Altere as senhas** após primeiro login
2. **Configure HTTPS** se expor na internet
3. **Desabilite ENABLE_SIGNUP** se não quiser novos registros
4. **Configure OAuth** ou LDAP para integração empresarial

## 📋 Comandos Úteis

```bash
# Reiniciar com nova configuração
./start.sh

# Ver logs
docker-compose logs -f

# Parar
docker-compose down

# Recriar usuários
./setup_users.sh

# Remover dados (reset completo)
docker-compose down -v
```

## 🔄 Alternativas

Se esta configuração não atender suas necessidades:

### Opção B: Acesso Público (Sem Login)
```yaml
- WEBUI_AUTH=false
```
⚠️ **Cuidado**: Todos acessam como admin

### Opção C: OAuth/LDAP
```yaml
- ENABLE_OAUTH_SIGNUP=true
- OAUTH_PROVIDERS=google,github
```

### Opção D: Proxy de Autenticação
Use nginx ou traefik para autenticação externa.

## 🎯 Esta Configuração é Ideal Para:

- ✅ **Equipes pequenas/médias**
- ✅ **Ambiente interno/VPN** 
- ✅ **Controle de acesso necessário**
- ✅ **Facilidade de uso importante**
- ✅ **Auditoria básica**

---

**Status**: ✅ Implementado e funcional  
**Teste**: Acesse http://localhost:3000 e faça login com as credenciais acima
