### Installing Both Ollama and Open WebUI Using Kustomize

For cpu-only pod

```bash
kubectl apply -f ./kubernetes/manifest/base
```

For gpu-enabled pod

```bash
kubectl apply -k ./kubernetes/manifest
```

### Installing Both Ollama and Open WebUI Using Helm

Package Helm file first

```bash
helm package ./kubernetes/helm/
```

For cpu-only pod

```bash
helm install ollama-webui ./ollama-webui-*.tgz
```

For gpu-enabled pod

```bash
helm install ollama-webui ./ollama-webui-*.tgz --set ollama.resources.limits.nvidia.com/gpu="1"
```

Check the `kubernetes/helm/values.yaml` file to know which parameters are available for customization

## Variáveis de Ambiente
Para usar via Docker Compose, crie um arquivo `.env` na raiz com:
```
WEBUI_AUTH=false
ENABLE_OAUTH_SIGNUP=true
ENABLE_SIGNUP=false
ENABLE_LOGIN_FORM=false
ANONYMOUS_CHAT_LIMIT=10
FREE_CHAT_QUOTA_AFTER_LOGIN=30
STRIPE_CHECKOUT_URL=<URL_DO_CHECKOUT>
STRIPE_WEBHOOK_SECRET=<SECRET>
OAUTH_ADMIN_ROLES=["admin"]
OAUTH_GROUPS_CLAIM=groups
WEBUI_SESSION_COOKIE_SECURE=false
WEBUI_SESSION_COOKIE_SAME_SITE=lax
```
