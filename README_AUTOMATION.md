# DocTul OpenWebUI - Automação e API

Sistema de automação completo para o DocTul OpenWebUI com sistema de quota, múltiplos modelos e monitoramento.

## 📁 Estrutura dos Scripts

```
/home/ai/doctul_open-webui/
├── scripts/
│   ├── configure_models.sh     # Configuração básica via bash
│   ├── model_manager.py        # Gerenciador avançado Python
│   ├── deploy.sh              # Deploy completo automatizado
│   └── monitor.sh             # Monitoramento do sistema
├── config/
│   └── models_config.json     # Configuração de modelos
└── README_AUTOMATION.md       # Esta documentação
```

## 🚀 Deploy Rápido

Para configurar todo o sistema de uma vez:

```bash
cd /home/ai/doctul_open-webui/scripts
./deploy.sh
```

## 📋 Scripts Disponíveis

### 1. configure_models.sh
Script bash básico para criar modelos via API.

```bash
# Uso básico
./configure_models.sh [TOKEN_ADMIN]

# Exemplo
./configure_models.sh "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
```

### 2. model_manager.py
Gerenciador Python avançado com múltiplas funcionalidades.

```bash
# Listar modelos existentes
python3 model_manager.py --token "SEU_TOKEN" --action list

# Criar apenas modelo DocTul
python3 model_manager.py --token "SEU_TOKEN" --action create

# Setup completo (recomendado)
python3 model_manager.py --token "SEU_TOKEN" --action setup
```

### 3. deploy.sh
Script completo de deploy que:
- Verifica serviços em execução
- Cria usuário admin se necessário
- Configura todos os modelos
- Valida a configuração

```bash
./deploy.sh
```

### 4. monitor.sh
Monitoramento contínuo do sistema.

```bash
# Execução única
./monitor.sh

# Monitoramento contínuo (atualiza a cada 30s)
watch -n 30 ./monitor.sh
```

## 🔌 Endpoints da API

### Autenticação

#### Verificar Contexto do Usuário
```bash
curl -X GET http://localhost:3000/api/v1/auths/context \
  -H "Authorization: Bearer SEU_TOKEN"
```

**Resposta:**
```json
{
  "user_id": "user_123",
  "is_admin": true,
  "admin_context": false,
  "enforce_quota": false,
  "user_type": "admin"
}
```

#### Criar Admin (primeira vez)
```bash
curl -X POST http://localhost:3000/api/v1/auths/setup/admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin DocTul",
    "email": "admin@doctul.local", 
    "password": "admin123"
  }'
```

#### Login
```bash
curl -X POST http://localhost:3000/api/v1/auths/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@doctul.local",
    "password": "admin123"
  }'
```

### Gerenciamento de Modelos

#### Listar Modelos Personalizados
```bash
curl -X GET http://localhost:3000/api/v1/models/ \
  -H "Authorization: Bearer SEU_TOKEN"
```

#### Listar Modelos Base
```bash
curl -X GET http://localhost:3000/api/v1/models/base \
  -H "Authorization: Bearer SEU_TOKEN"
```

#### Listar Modelos OpenAI (Público)
```bash
curl -X GET http://localhost:3000/openai/models
```

#### Criar Modelo Personalizado
```bash
curl -X POST http://localhost:3000/api/v1/models/create \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d @- << 'EOF'
{
  "id": "doctul",
  "base_model_id": "/home/ai/II-Medical-8B",
  "name": "DocTul",
  "params": {
    "system": "You are DocTul, a clinical assistant for Brazilian doctors...",
    "top_p": 0.9,
    "temperature": 0.6
  },
  "meta": {
    "profile_image_url": "/static/favicon.png",
    "description": "Assistente clínico especializado para médicos brasileiros",
    "capabilities": {
      "vision": false,
      "file_upload": false,
      "web_search": false,
      "image_generation": false,
      "code_interpreter": false,
      "citations": false,
      "usage": false
    },
    "suggestion_prompts": [
      "Como proceder com paciente com dor torácica?",
      "Protocolo para hipertensão arterial"
    ],
    "tags": ["medicina", "clinica", "brasil"]
  }
}
EOF
```

#### Deletar Modelo
```bash
curl -X DELETE http://localhost:3000/api/v1/models/ID_DO_MODELO \
  -H "Authorization: Bearer SEU_TOKEN"
```

### Monitoramento de Quota

#### Verificar Quota no Redis
```bash
# Quota anônima
docker exec redis redis-cli get "quota:anonymous"

# Quota de usuário específico
docker exec redis redis-cli get "quota:USER_ID"

# Listar todas as quotas
docker exec redis redis-cli keys "quota:*"
```

## 🏥 Modelos Configurados

### 1. DocTul (doctul)
- **Propósito**: Assistente clínico para médicos brasileiros
- **Contexto**: Emergência, enfermaria, atenção primária
- **Idioma**: Português brasileiro exclusivamente
- **Acesso**: Usuários autenticados

### 2. Assistente Geral (geral)
- **Propósito**: Modelo público com quota limitada
- **Contexto**: Uso geral educativo
- **Idioma**: Português brasileiro
- **Acesso**: Usuários anônimos (10 msg/mês)

### 3. DocTul Consultoria (consultoria)
- **Propósito**: Consultoria médica especializada
- **Contexto**: Casos complexos, protocolos
- **Idioma**: Português brasileiro
- **Acesso**: Usuários premium

## 💬 Sistema de Quota

### Limites Configurados
- **Anônimo**: 10 mensagens/mês
- **Autenticado**: 30 mensagens/mês  
- **Premium**: Ilimitado

### Reset de Quota
```bash
# Reset quota anônima
docker exec redis redis-cli del "quota:anonymous"

# Reset quota específica
docker exec redis redis-cli del "quota:USER_ID"

# Reset todas as quotas
docker exec redis redis-cli flushdb
```

## 🔧 Configuração de Ambiente

### Variáveis Docker Compose
```yaml
environment:
  - ENABLE_SIGNUP=false
  - DEFAULT_USER_ROLE=user
  - ENABLE_COMMUNITY_SHARING=false
  - OPENAI_API_BASE_URL=http://localhost:8001/v1
  - OPENAI_API_KEY=not-needed
```

### Arquivos de Configuração
- **models_config.json**: Configurações de modelos
- **docker-compose.yml**: Serviços e redes
- **.env**: Variáveis de ambiente (se usado)

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Token Inválido
```bash
# Verificar token
curl -X GET http://localhost:3000/api/v1/auths/ \
  -H "Authorization: Bearer SEU_TOKEN"
```

#### 2. Modelo não Aparece
```bash
# Verificar modelos base disponíveis
curl -X GET http://localhost:3000/api/v1/models/base \
  -H "Authorization: Bearer SEU_TOKEN"

# Verificar vLLM
curl -X GET http://localhost:8001/v1/models
```

#### 3. Quota não Funciona
```bash
# Verificar Redis
docker exec doctul_open-webui-redis-1 redis-cli ping

# Verificar logs
docker logs doctul_open-webui-main-1 --tail 50
```

#### 4. Permissões de Script
```bash
# Tornar executáveis
chmod +x scripts/*.sh scripts/*.py
```

## 📊 Monitoramento

### Logs em Tempo Real
```bash
# OpenWebUI
docker logs -f doctul_open-webui-main-1

# Redis
docker logs -f doctul_open-webui-redis-1

# Todos os serviços
docker-compose logs -f
```

### Estatísticas Redis
```bash
docker exec redis redis-cli info stats
```

### Status dos Containers
```bash
docker-compose ps
docker stats
```

## 🎯 Estratégia Admin/User

### Alternância de Contexto
O sistema permite alternância inteligente entre modo admin e user:

- **Modo User**: `http://localhost:3000/` (quota aplicada)
- **Modo Admin**: `http://localhost:3000/admin` (sem quota)
- **Query Admin**: `http://localhost:3000/?admin=true` (sem quota)

### Detecção Automática
- **Admin Role**: Bypass automático se `user.role == "admin"`
- **URL Context**: Detecção por URL `/admin` ou `?admin=true`
- **Quota Bypass**: Admins podem usar sistema sem limitações

### Documentação Detalhada
Veja `docs/ADMIN_USER_STRATEGY.md` para implementação completa.

## 🎯 Próximos Passos

1. **Monitoramento Avançado**: Prometheus + Grafana
2. **Backup Automático**: Scripts de backup do Redis e configurações
3. **Load Balancing**: Múltiplas instâncias vLLM
4. **Analytics**: Tracking de uso e performance
5. **Notificações**: Alertas via webhook/email

## 📞 Suporte

Para issues e melhorias, verifique:
1. Logs dos containers
2. Status dos serviços via `monitor.sh`
3. Conectividade Redis/vLLM
4. Permissões de arquivos e tokens

---

**Última atualização**: $(date)
**Versão**: 1.0
**Autor**: DocTul Team
