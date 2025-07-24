 # Plano de Implementação Unificado: OpenWebUI com Acesso Anônimo, Cotas e Pagamento

 Este documento detalha o fluxo completo e as ações necessárias para implementar:
 1. Acesso anônimo com limite de 10 chats.
 2. Cadastro via Keycloak para 30 chats gratuitos.
 3. Pagamento via Stripe para acesso ilimitado.
 4. Login de administrador via Keycloak.

 ---

 ## PROGRESSO ATUAL (Julho 2025)

 ### ✅ Implementado e Funcionando
 1. **Sistema de Quota Anônima:**
    - Limite de 10 mensagens por mês funcionando
    - Persistência via Redis com reset mensal
    - Arquivo: `utils/quota.py` → `enforce_chat_quota()`

 2. **Integração vLLM:**
    - Modelo II-Medical-8B servindo na porta 8001
    - API OpenAI-compatible configurada
    - Modelo "DocTul" configurado via interface admin

 3. **Autenticação Híbrida:**
    - Acesso anônimo direto à interface funcionando
    - Endpoint `/setup/admin` para criação de admin
    - AnonymousUser para usuários sem token

 4. **Infraestrutura:**
    - Docker Compose com OpenWebUI + Redis
    - Automação via scripts em `/scripts/`
    - Monitoramento via `monitor.sh`

 ### 🔄 Em Desenvolvimento
 1. **Sistema de Alternância Admin/User:**
    - ✅ Implementar detecção de contexto admin
    - ✅ Bypass inteligente de quota para admins
    - ✅ Interface adaptável baseada em contexto
    - ✅ Endpoint `/api/v1/auths/context` funcionando

 2. **Quota para Usuários Autenticados:**
    - Limite de 30 mensagens após login
    - Integração com sistema de autenticação existente

 ### 📋 Próximos Passos
 1. ✅ Implementar middleware de bypass admin
 2. ✅ Adicionar endpoints de contexto de usuário
 3. Frontend adaptável para modo admin/user
 4. Integração Stripe para upgrade premium
 5. Testes E2E completos

 ---

 ## Fluxo do Usuário (Visão Geral)
 1. Usuário Anônimo: acesso direto, sem login, até **10 mensagens** (`ANONYMOUS_CHAT_LIMIT`).
 2. Limite Anônimo: ao atingir, exibir modal/redirecionar para `/oauth/authorize`.
 3. Usuário Cadastrado (Grátis): após login, **30 mensagens** gratuitas (`FREE_CHAT_QUOTA_AFTER_LOGIN`).
 4. Limite Gratuito: ao esgotar, exibir modal/redirecionar para `STRIPE_CHECKOUT_URL`.
 5. Usuário Pagante: acesso ilimitado após confirmação de pagamento.
 6. Administrador: login via Keycloak, `role='admin'`, acesso a painel administrativo.

 ---

 ## 1. Configuração de Ambiente e Docker
 **Arquivo:** `docker-compose.yml`
 
 - **EXISTENTE:** Suporte básico de SSO e variáveis de ambiente.
 - **NOVO:** Consolidar blocos `environment`, removendo duplicatas:
   ```yaml
   environment:
     WEBUI_AUTH: "false"
     ENABLE_OAUTH_SIGNUP: "true"
     ENABLE_SIGNUP: "false"
     ENABLE_LOGIN_FORM: "false"
     ANONYMOUS_CHAT_LIMIT: "10"
     FREE_CHAT_QUOTA_AFTER_LOGIN: "30"
     STRIPE_CHECKOUT_URL: "<URL_DO_CHECKOUT>"
     STRIPE_WEBHOOK_SECRET: "<SECRET>"
     OAUTH_ADMIN_ROLES: "['admin']"
     OAUTH_GROUPS_CLAIM: "groups"
   ```
 - Validar sintaxe com `docker-compose config`.
 - Documentar em `README.md`, `INSTALLATION.md` e `KEYCLOAK_SETUP.md`:
   - Seção **Variáveis de Ambiente** com descrições e exemplos de `.env`.
 - Ajustar `SESSION_COOKIE_SECURE` e `SameSite` (DEV: `secure=false, lax`; PROD: `secure=true, strict`).

### Status das Tarefas
- [x] Consolidar blocos `environment` removendo duplicatas
- [x] Validar sintaxe com `docker-compose config`
- [x] Documentar variáveis em `README.md`, `INSTALLATION.md` e `KEYCLOAK_SETUP.md`
- [x] Sistema Redis configurado e funcional
- [x] Integração vLLM estabelecida (porta 8001)
- [x] Acesso direto à interface funcionando
- [ ] Ajustar `SESSION_COOKIE_SECURE` e `SameSite` para DEV vs PROD

 ## 2. Backend (FastAPI)
 **Arquivo:** `backend/open_webui/config.py`
 
 - **EXISTENTE:** Uso de `PersistentConfig` para algumas variáveis.
 - **NOVO:** Adicionar/ajustar:
  **NOVO:** Adicionar/ajustar:
   ```python
   ANONYMOUS_CHAT_LIMIT = PersistentConfig('ANONYMOUS_CHAT_LIMIT', default=10)
   FREE_CHAT_QUOTA_AFTER_LOGIN = PersistentConfig('FREE_CHAT_QUOTA_AFTER_LOGIN', default=30)
   STRIPE_CHECKOUT_URL = PersistentConfig('STRIPE_CHECKOUT_URL')
   STRIPE_WEBHOOK_SECRET = PersistentConfig('STRIPE_WEBHOOK_SECRET')
   OAUTH_ADMIN_ROLES = PersistentConfig('OAUTH_ADMIN_ROLES', default=['admin'])
   OAUTH_GROUPS_CLAIM = PersistentConfig('OAUTH_GROUPS_CLAIM', default='groups')
   ```

### Status das Tarefas
- [x] Inserir `PersistentConfig` para quotas, Stripe e Keycloak em `config.py`
- [x] Remover auto-atribuição de `admin` no `signup` quando `WEBUI_AUTH=false`
- [x] Criar `AnonymousUser` em `routers/auths.py` para usuários sem token
- [x] Sistema de quota implementado e funcional (10 msgs anônimo)
- [x] Integração Redis para persistência de quota
- [x] Endpoint `/setup/admin` para criação de administrador
 
 **Arquivo:** `routers/auths.py`
 - Criar `AnonymousUser` quando não houver token.
 - Remover auto-atribuição `role='admin'` ao primeiro usuário se `WEBUI_AUTH=false`.

 ## 3. Controle de Cotas e Fluxo de Chat
 **Arquivo:** `routers/chat.py`
 
 - **EXISTENTE:** Endpoint `POST /api/chat` para usuários autenticados.
 - **NOVO:**
  - Usuários anônimos: contar mensagens via Redis (IP + fingerprint) para resistir à limpeza de cookies.
    - Se ≥ `ANONYMOUS_CHAT_LIMIT`, retornar `403 ANONYMOUS_LIMIT_REACHED`.
    - Resetar a contagem anônima mensalmente.
  - Usuários logados: verificar `users.chat_quota`. Se ≥ `FREE_CHAT_QUOTA_AFTER_LOGIN`, retornar `403 QUOTA_EXCEEDED`.
  - Adicionar cabeçalhos `X-Chat-Status` para front exibir modal ou redirecionar.

### Status das Tarefas
- [x] Sistema de quota anônima implementado via Redis
- [x] Verificação de limite de 10 mensagens funcionando
- [x] Reset mensal de quota configurado
- [x] Função `enforce_chat_quota()` em `utils/quota.py`
- [x] Integração com endpoints de chat
- [ ] Implementar quota para usuários autenticados (30 msgs)
- [ ] Cabeçalhos `X-Chat-Status` para frontend

 ## 3.1. Estratégia de Alternância Admin/User
 **Objetivo:** Permitir que a interface funcione tanto para usuários limitados quanto para administradores, sem quebrar o sistema de quota.

 **Implementação:**
 1. **Detecção de Contexto:**
    - URL padrão (`/`) → Modo USER limitado com quota
    - URL admin (`/admin` ou `?admin=true`) → Modo ADMIN sem quota
    - Token admin presente → Bypass automático de quota

 2. **Middleware de Quota Inteligente (ATUALIZADO 24/07/2025):**
    ```python
    def should_enforce_quota(request, user):
        # ⚠️ MUDANÇA: Removido bypass automático para admin role
        # Apenas bypass se contexto admin EXPLÍCITO via URL
        
        # URL admin bypass
        if "/admin" in request.url.path or "admin=true" in str(request.url.query):
            return False
        
        # SEMPRE aplicar quota por padrão (incluindo admins)
        return True
    ```

 3. **Interface Adaptável:**
    - Detectar contexto admin via token ou URL
    - Exibir controles administrativos quando apropriado
    - Manter funcionalidade de quota em modo user

 **Arquivos Afetados:**
 - `utils/quota.py` → Adicionar lógica de bypass admin
 - `routers/auths.py` → Endpoint para verificar contexto admin
 - Frontend → Detectar modo admin e adaptar interface

### Status das Tarefas - Alternância Admin/User
- [x] Função `should_enforce_quota()` implementada
- [x] Endpoint `/api/v1/auths/context` criado
- [x] Detecção por URL `/admin` e `?admin=true`
- [x] ⚠️ **CORREÇÃO 24/07:** Removido bypass automático para role admin
- [x] Sistema testado e funcionando via API
- [x] Documentação criada em `docs/ADMIN_USER_STRATEGY.md`
- [x] Endpoint Ollama corrigido para permitir usuários anônimos
- [ ] **PENDENTE:** Rebuild container para aplicar correções
- [ ] **PENDENTE:** Frontend adaptável baseado em contexto
- [ ] **PENDENTE:** Interface de alternância user/admin

 ## 4. SSO / Keycloak
 **Arquivo:** `KEYCLOAK_SETUP.md`
 
 - Documentar criação do realm `openwebui` e role `admin`.
- Configurar mapeadores de claims, preferindo `realm_access.roles` em vez de `groups`:
  - Roles são atribuídos diretamente no token, simplificando autorização sem hierarquias de grupos.
 - Ajustar `redirect_uris` e políticas de CORS no client `open-webui`.
 - Em `utils/oauth.py`, validar claims e atribuir `role='admin'`.

 ## 5. Front-end (Svelte)
 **Arquivos:** `src/stores/session.ts`, `src/lib/apis/chat.ts`, `src/App.svelte`
 
 **`session.ts`:**
 ```js
 import { writable } from 'svelte/store';
 export const session = writable({ authenticated: false, role: null });
 fetch('/api/session')
   .then(r => r.json())
   .then(data => session.set(data));
 ```
 **`chat.ts`:**
 - Interceptar `ANONYMOUS_LIMIT_REACHED` → modal "Cadastre-se para ganhar 30 chats" + botão Keycloak.
 - Interceptar `QUOTA_EXCEEDED` → modal "Sua cota acabou" + botão Stripe.
 **`App.svelte`/`Layout.svelte`:**
 - Exibir `<AdminButton>` se `$session.role==='admin'`.
 - Remover uso de `?admin=true`.
 - Placeholder para anônimos convidando a login.

 ## 6. Integração Stripe
 **Arquivo:** `backend/open_webui/routers/stripe.py`
 
 - Endpoint `POST /api/stripe/create-checkout-session`: recebe `{ userId }`, retorna `{ url }` para iniciar assinatura recorrente mensal.
 - Endpoint `POST /api/stripe/webhook`: validar `Stripe-Signature` e processar eventos de assinatura:
   - `invoice.payment_succeeded` → renovar acesso do usuário.
   - `invoice.payment_failed` → notificar o usuário e suspender acesso.
   - Garantir idempotência usando `stripe.Event.id` + tabela `processed_events`.
 - Em `models/users.py`, adicionar campo `paid_credits` ou `has_paid_access`.
 - Documentar fluxo em `docs/stripe.md` com diagrama.

 ## 7. Testes e QA
 - **Cypress (`cypress/integration`):**
   - `anonymous_limit.spec.ts`: testar 10 chats → redireciona ao login.
   - Fluxo completo: anônimo → login → usar 30 → Stripe → desbloqueio.
 - **Segurança e carga (`test/`):**
   - CSRF (ex.: `test/csrf.spec.ts`).
   - CORS e testes de múltiplos WebSockets simultâneos.

 ## 8. Documentação
 - Atualizar `README.md`, `README_FINAL.md`, `README_HIBRIDO.md`.
 - Atualizar `INSTALLATION.md` com exemplos de `.env`.
 - Criar `docs/flow.md` e `docs/USER_FLOW.md` com diagramas.
 - Incluir seção de **Variáveis de Ambiente** em `docs/`.

 > **Nota:** Revisar cada item antes de prosseguir para garantir coerência e evitar regressões.

1.1. EXISTENTE
- Há um arquivo `docker-compose.yml` com suporte a SSO e variáveis básicas.

1.2. NOVO
- Consolidar e unificar blocos `environment`, removendo duplicatas.
- Adicionar/ajustar variáveis:
  - `WEBUI_AUTH=false`
  - `ENABLE_OAUTH_SIGNUP=true`
  - `ENABLE_SIGNUP=false`
  - `ENABLE_LOGIN_FORM=false`
  - `ANONYMOUS_CHAT_LIMIT=10`
  - `FREE_CHAT_QUOTA_AFTER_LOGIN=30`
  - `STRIPE_CHECKOUT_URL=<URL_DO_CHECKOUT>`
  - `STRIPE_WEBHOOK_SECRET=<SECRET>`
  - `OAUTH_ADMIN_ROLES=["admin"]`
  - `OAUTH_GROUPS_CLAIM=groups`
- Validar sintaxe com `docker-compose config`.
- Atualizar `README.md`, `INSTALLATION.md` e `KEYCLOAK_SETUP.md` com novas variáveis.
- Ajustar `SESSION_COOKIE_SECURE` e `SameSite` para DEV vs PROD.

---

## 2. Configuração do Backend (FastAPI)

2.1. EXISTENTE
- `backend/open_webui/config.py` define algumas configs via `PersistentConfig`.
- Autenticação básica e SSO via Keycloak já integrados em `routers/auths.py` e `utils/oauth.py`.

2.2. NOVO
- Em `config.py`, garantir/ajustar `PersistentConfig` para:
  - `ANONYMOUS_CHAT_LIMIT`
  - `FREE_CHAT_QUOTA_AFTER_LOGIN`
  - `STRIPE_CHECKOUT_URL`
  - `STRIPE_WEBHOOK_SECRET`
  - `OAUTH_ADMIN_ROLES`
  - `OAUTH_GROUPS_CLAIM`
- Em `routers/auths.py` (ou middleware):
  - Se não houver token, instanciar `AnonymousUser` com permissões limitadas.
  - Remover fallback que atribui `admin` ao primeiro usuário quando `WEBUI_AUTH=false`.

---

## 3. Controle de Cotas e Fluxo de Chat

3.1. EXISTENTE
- Endpoint `POST /api/chat` processa mensagens de usuários autenticados.

3.2. NOVO
- Em `routers/chat.py`:
  - Para usuários anônimos, contar mensagens via cookie/session/Redis.
    - Se ≥ `ANONYMOUS_CHAT_LIMIT`, retornar `403` com `{"detail":"ANONYMOUS_LIMIT_REACHED"}`.
  - Para usuários logados, verificar coluna `users.chat_quota`.
    - Se ≥ `FREE_CHAT_QUOTA_AFTER_LOGIN`, retornar `403` com `{"detail":"QUOTA_EXCEEDED"}`.
  - Incluir resposta para front-end exibir modal/redirecionar.

---

## 4. Integração de Pagamento (Stripe)

4.1. EXISTENTE
- Dependência Stripe já no `pyproject.toml`/`requirements.txt`.

4.2. NOVO
- Criar `routers/stripe.py`:
  - `POST /api/stripe/create-checkout-session` → retorna `session.url`.
  - `POST /api/stripe/webhook` → processa `checkout.session.completed`, idempotência, atualiza `paid_credits`.
- Em `models/users.py`, adicionar campo `paid_credits` ou `has_paid_access`.
- Documentar diagrama e fluxo em `docs/stripe.md`.

---

## 5. SSO e Admin (Keycloak)

5.1. EXISTENTE
- Keycloak já configurado para login de usuários via OIDC.

5.2. NOVO
- Em `KEYCLOAK_SETUP.md`:
  - Criar realm `openwebui` e role `admin`.
  - Mapear `realm_access.roles` ou `groups`.
  - Ajustar mapeadores de claims no client `open-webui`.
  - Configurar `redirect_uris` e políticas de CORS.
- Em `utils/oauth.py`, testar leitura de claims e atribuir `role="admin"`.

---

## 6. Front-end (Svelte)

6.1. EXISTENTE
- Store `src/stores/session.ts` e chamadas básicas a `/api/session`.
- Componentes de chat e layout já em funcionamento.

6.2. NOVO
- Em `session.ts`, garantir fetch de `{ authenticated, role }`.
- Em `src/lib/apis/chat.ts`:
  - Tratar `ANONYMOUS_LIMIT_REACHED` → modal + botão para `/oauth/authorize`.
  - Tratar `QUOTA_EXCEEDED` → modal + botão para `STRIPE_CHECKOUT_URL`.
- Em componentes Svelte:
  - Renderizar admin se `role==='admin'`.
  - Remover `?admin=true`.
  - Placeholder e convite ao login para anônimos.

---

## 7. Testes e QA

7.1. NOVO
- E2E com Cypress: fluxo completo (anônimo → login → cota → pagamento).
- Scripts de segurança e carga: CSRF, CORS, WebSocket em `test/`.

---

> **Nota:** Execute cada bloco na sequência indicada. Valide completamente antes de avançar ao próximo para evitar regressões.
