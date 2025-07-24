# Plano de Implementação V2: OpenWebUI com Acesso Anônimo, Cotas e Pagamento

Este documento detalha o plano para transformar o OpenWebUI em uma plataforma com um fluxo de usuário progressivo: acesso anônimo, cadastro via Keycloak para mais acesso, e pagamento via Stripe para uso ilimitado.

## Fluxo do Usuário Alvo

1.  **Usuário Anônimo:** Acessa a UI diretamente, sem login. Pode enviar até 10 mensagens.
2.  **Limite Anônimo:** Ao atingir 10 mensagens, é solicitado a se cadastrar via Keycloak.
3.  **Usuário Cadastrado (Grátis):** Após o login, recebe uma cota de 30 chats gratuitos.
4.  **Limite de Cota:** Ao usar os 30 chats, é direcionado para uma página de pagamento (Stripe).
5.  **Usuário Pagante:** Após o pagamento, tem acesso contínuo.
6.  **Administrador:** Faz login via Keycloak com um "role" de `admin` para acessar o painel de controle.

---

## 1. Configuração de Ambiente e Docker

-   **[ ] Objetivo: Habilitar acesso anônimo e configurar o fluxo.**
    -   **Arquivo:** `docker-compose.yml`
    -   **Ação 1: Habilitar Acesso Direto:**
        -   Alterar a variável principal de autenticação para `WEBUI_AUTH=false`. Isso desativa a tela de login obrigatória.
    -   **Ação 2: Centralizar Login no Keycloak:**
        -   Garantir que `ENABLE_OAUTH_SIGNUP=true`.
        -   Remover ou definir como `false`: `ENABLE_SIGNUP`, `ENABLE_LOGIN_FORM`.
    -   **Ação 3: Adicionar Novas Variáveis de Controle:**
        -   `- ANONYMOUS_CHAT_LIMIT=10`
        -   `- FREE_CHAT_QUOTA_AFTER_LOGIN=30`
        -   `- STRIPE_CHECKOUT_URL=...`
        -   `- OAUTH_ADMIN_ROLES=["admin"]`
    -   **Ação 4: Limpar Variáveis Duplicadas:**
        -   Remover o segundo bloco de `environment` para evitar conflitos.
        -   Validar com `docker-compose config`.

## 2. Backend (FastAPI)

-   **[ ] Objetivo: Implementar a lógica de controle de acesso e cotas.**
    -   **Ação 1: Lidar com Usuários Anônimos (Não-autenticados):**
        -   **Arquivo:** `backend/open_webui/routers/auths.py` (e middlewares relacionados).
        -   **Lógica:** Modificar o middleware de autenticação. Se nenhum token for fornecido, em vez de dar erro, deve criar um objeto `AnonymousUser` com permissões limitadas. A lógica de "primeiro usuário é admin" deve ser desativada quando `WEBUI_AUTH=false`.
    -   **Ação 2: Implementar Contadores de Chat:**
        -   **Arquivo:** `backend/open_webui/routers/chat.py` (no endpoint de envio de mensagem).
        -   **Contador Anônimo:** Usar um cookie de sessão para contar os chats. Se o contador (`>=ANONYMOUS_CHAT_LIMIT`) for atingido, a API deve retornar um erro `403 Forbidden` com o corpo `{"detail": "ANONYMOUS_LIMIT_REACHED"}`.
        -   **Contador de Usuário Logado:** Usar uma coluna no banco de dados (`users` table) para a cota. Se a cota (`>=FREE_CHAT_QUOTA_AFTER_LOGIN`) for atingida, retornar `403 Forbidden` com `{"detail": "QUOTA_EXCEEDED"}`.
    -   **Ação 3: Implementar Acesso de Administrador via Keycloak:**
        -   **Arquivo:** `backend/open_webui/utils/oauth.py`.
        -   **Lógica:** O código existente que lê `OAUTH_ADMIN_ROLES` já é suficiente. Apenas garantir que ele atribua o `role="admin"` corretamente ao usuário durante o login via OIDC.

## 3. Front-end (Svelte)

-   **[ ] Objetivo: Criar uma interface reativa que guia o usuário pelo fluxo.**
    -   **Ação 1: Tratar Respostas de Erro da API:**
        -   **Arquivo:** Lógica de chamada da API de chat (ex: `src/lib/apis/chat.ts`).
        -   **Lógica:** Interceptar erros da API.
            -   Se receber `ANONYMOUS_LIMIT_REACHED`, exibir um modal/pop-up ("Seu teste acabou. Cadastre-se para ganhar mais 30 chats.") e oferecer um botão que redireciona para o login do Keycloak.
            -   Se receber `QUOTA_EXCEEDED`, exibir um modal ("Sua cota gratuita terminou. Adquira mais créditos.") e redirecionar para a `STRIPE_CHECKOUT_URL`.
    -   **Ação 2: Exibir Conteúdo Condicional:**
        -   **Arquivo:** Componentes de layout (ex: `src/App.svelte`).
        -   **Lógica:** O painel de administração e outras funcionalidades de admin só devem ser renderizados se a API `/api/session` retornar `user.role === 'admin'`.

## 4. SSO e Admin (Keycloak)

-   **[ ] Objetivo: Configurar o Keycloak para gerenciar usuários e administradores.**
    -   **Ação 1: Criar o Role de Administrador:**
        -   No console do Keycloak, no realm `openwebui`, criar um "Realm Role" chamado `admin`.
    -   **Ação 2: Atribuir o Role a um Usuário:**
        -   Atribuir o role `admin` ao seu usuário de teste para que ele possa acessar as funcionalidades de admin.
    -   **Ação 3: Configurar o Mapeamento de Claims:**
        -   No client `open-webui`, garantir que o "token mapper" para `realm_access.roles` ou `groups` esteja ativo, para que o backend receba a informação de `admin`.

## 5. Integração de Pagamento (Stripe)

-   **[ ] Objetivo: Integrar o Stripe para desbloquear o uso após a cota gratuita.**
    -   **Ação 1: Criar Endpoints no Backend:**
        -   **Arquivo:** `backend/open_webui/routers/stripe.py`.
        -   **Endpoint de Checkout:** Criar uma rota `/api/stripe/create-checkout-session` que inicia uma sessão de pagamento no Stripe.
        -   **Endpoint de Webhook:** Criar uma rota `/api/stripe/webhook` para receber a confirmação de pagamento do Stripe e atualizar o status/cota do usuário no banco de dados.
    -   **Ação 2: Adicionar Coluna de Cota no Banco de Dados:**
        -   **Arquivo:** `backend/open_webui/models/users.py`.
        -   **Lógica:** Adicionar uma coluna como `chat_quota` ou `has_paid_access` à tabela de usuários.

## 6. Testes e Documentação

-   **[ ] Objetivo: Garantir a qualidade e a manutenibilidade do projeto.**
    -   **Ação 1: Atualizar Testes E2E (Cypress):**
        -   Criar/atualizar testes que simulem todo o fluxo do usuário: anônimo -> atinge limite -> login -> atinge cota -> pagamento.
    -   **Ação 2: Atualizar Documentação:**
        -   Atualizar `README.md` e `INSTALLATION.md` com as novas variáveis de ambiente e o fluxo de configuração.
        -   Criar um diagrama do fluxo em `docs/USER_FLOW.md`.

---

> **Nota:** Este plano revisado serve como guia. Cada passo deve ser validado antes de prosseguir para o próximo.
