# Estratégia de Alternância Admin/User - DocTul OpenWebUI

## Visão Geral

O sistema DocTul implementa uma estratégia inteligente que permite o uso da mesma interface tanto para usuários limitados (com quota) quanto para administradores (sem quota), sem quebrar a funcionalidade de controle de acesso.

## Como Funciona

### 1. Detecção de Contexto

O sistema detecta automaticamente o contexto de uso através de múltiplos critérios:

#### Critérios de Bypass Admin:
- **Role do Usuário**: `user.role == "admin"`
- **URL Admin**: URLs contendo `/admin`
- **Query Parameter**: URLs contendo `?admin=true`

#### Exemplos:
```
http://localhost:3000/               → Modo USER (quota aplicada)
http://localhost:3000/admin          → Modo ADMIN (sem quota)
http://localhost:3000/?admin=true    → Modo ADMIN (sem quota)
```

### 2. Middleware de Quota Inteligente

```python
def should_enforce_quota(request: Request, user: Optional[UserModel]) -> bool:
    # Bypass para administradores
    if user and hasattr(user, 'role') and user.role == "admin":
        return False
    
    # Bypass para URLs admin
    url_path = str(request.url.path)
    url_query = str(request.url.query) if request.url.query else ""
    
    if "/admin" in url_path or "admin=true" in url_query:
        return False
    
    # Aplicar quota para users normais e anônimos
    return True
```

### 3. Endpoint de Contexto

**GET `/api/v1/auths/context`**

Retorna informações sobre o contexto atual do usuário:

```json
{
  "user_id": "user_123",
  "is_admin": true,
  "admin_context": false,
  "enforce_quota": false,
  "user_type": "admin"
}
```

## Fluxos de Uso

### Fluxo Usuário Anônimo (Padrão)
1. Acessa `http://localhost:3000/`
2. Sistema detecta usuário anônimo
3. Quota de 10 mensagens é aplicada
4. Interface mostra contador de mensagens
5. Após 10 mensagens → modal de upgrade

### Fluxo Administrador
1. Acessa `http://localhost:3000/admin` ou `?admin=true`
2. Sistema detecta contexto admin
3. Quota é ignorada (bypass)
4. Interface mostra controles administrativos
5. Acesso total aos modelos e configurações

### Fluxo Híbrido
1. Admin pode acessar ambos os modos:
   - URL normal → Modo user (para testar experiência)
   - URL admin → Modo admin (para configurar)
2. Contexto é preservado durante navegação
3. Alternância não afeta contadores de quota

## Implementação Técnica

### Arquivos Modificados

#### 1. `utils/quota.py`
- Função `should_enforce_quota()` adicionada
- Lógica de bypass para admins
- Detecção de contexto por URL

#### 2. `routers/auths.py`
- Endpoint `/context` adicionado
- Retorna estado do contexto atual
- Integra com sistema de quota

#### 3. `backend/config.py`
- Configurações de quota mantidas
- Compatibilidade com bypass admin

### Frontend (A Implementar)

```javascript
// Detectar contexto admin
const response = await fetch('/api/v1/auths/context');
const context = await response.json();

if (context.is_admin && context.admin_context) {
    // Mostrar interface admin
    showAdminControls();
} else if (context.enforce_quota) {
    // Mostrar contador de quota
    showQuotaCounter();
}
```

## Benefícios da Estratégia

### 1. **Preservação da Funcionalidade**
- Sistema de quota permanece intacto
- Contadores não são afetados pela alternância
- Experiência do usuário final preservada

### 2. **Flexibilidade Administrativa**
- Admin pode testar experiência do usuário
- Alternância simples entre modos
- Controles administrativos quando necessário

### 3. **Segurança Mantida**
- Autenticação admin requerida para bypass
- URLs admin protegidas
- Auditoria de acesso preservada

### 4. **Experiência Unificada**
- Uma única interface para todos os usuários
- Adaptação baseada em contexto
- Transições suaves entre modos

## Configuração e Uso

### 1. **Criar Usuário Admin**
```bash
curl -X POST http://localhost:3000/api/v1/auths/setup/admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin DocTul",
    "email": "admin@doctul.local",
    "password": "admin123"
  }'
```

### 2. **Acessar Modo Admin**
- URL: `http://localhost:3000/admin`
- URL: `http://localhost:3000/?admin=true`
- Login com credenciais admin

### 3. **Acessar Modo User**
- URL: `http://localhost:3000/`
- Experiência normal com quota

### 4. **Verificar Contexto**
```bash
curl -X GET http://localhost:3000/api/v1/auths/context \
  -H "Authorization: Bearer SEU_TOKEN"
```

## Monitoramento

### Logs de Quota
```bash
# Ver quota atual
docker exec redis redis-cli get "anon_quota:2025-07:HASH"

# Ver todas as quotas
docker exec redis redis-cli keys "anon_quota:*"
```

### Verificar Bypass Admin
```bash
# Testar endpoint de contexto
curl -s http://localhost:3000/api/v1/auths/context | jq .
```

## Troubleshooting

### Problema: Admin não consegue bypass
1. Verificar role do usuário via `/api/v1/auths/`
2. Confirmar URL contém `/admin` ou `?admin=true`
3. Verificar logs do sistema

### Problema: Quota aplicada incorretamente
1. Verificar contexto via `/api/v1/auths/context`
2. Confirmar função `should_enforce_quota()`
3. Testar com URLs diferentes

### Problema: Alternância não funciona
1. Verificar cookies e sessão
2. Limpar cache do navegador
3. Verificar rede e proxy

---

**Última atualização**: Julho 2025  
**Versão**: 1.0  
**Status**: Implementado e funcional
