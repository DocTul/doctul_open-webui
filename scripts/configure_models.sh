#!/bin/bash

# Script para configurar modelos automaticamente via API
# Uso: ./configure_models.sh <admin_token>

set -e

ADMIN_TOKEN="$1"
BASE_URL="http://localhost:3000"

if [ -z "$ADMIN_TOKEN" ]; then
    echo "Erro: Token de admin necessário"
    echo "Uso: $0 <admin_token>"
    exit 1
fi

echo "🔧 Configurando modelos via API..."

# 1. Verificar modelos base disponíveis
echo "📋 Verificando modelos base disponíveis..."
BASE_MODELS=$(curl -s -X GET "$BASE_URL/api/v1/models/base" \
    -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Modelos base encontrados:"
echo "$BASE_MODELS" | jq -r '.[].id'

# 2. Criar modelo DocTul personalizado
echo "🏥 Criando modelo DocTul..."

DOCTUL_PAYLOAD='{
  "id": "doctul",
  "base_model_id": "/home/ai/II-Medical-8B",
  "name": "DocTul",
  "params": {
    "system": "You are DocTul, a clinical assistant for Brazilian doctors (ER, ward, primary care). Always reply in Brazilian Portuguese.\\nBe practical and medically accurate. When appropriate, be didactic and clear.\\nAssume Brazilian context: limited resources, CT is more available than MRI.\\nFollow internal context strictly if provided. Never override or ignore it.\\nNever guess drug compositions. If a brand name is mentioned, ask for the active ingredient.\\nAvoid speculation and self-references. Use step-by-step reasoning only when useful. Highlight final recommendations.",
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
      "Protocolo para hipertensão arterial",
      "Diagnóstico diferencial de febre em adultos",
      "Manejo de diabetes tipo 2 na atenção primária"
    ],
    "tags": ["medicina", "clinica", "brasil"]
  }
}'

RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/models/create" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$DOCTUL_PAYLOAD")

if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
    echo "✅ Modelo DocTul criado com sucesso!"
else
    echo "❌ Erro ao criar modelo DocTul:"
    echo "$RESPONSE"
fi

# 3. Listar modelos personalizados criados
echo "📋 Listando modelos personalizados..."
CUSTOM_MODELS=$(curl -s -X GET "$BASE_URL/api/v1/models/" \
    -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Modelos personalizados:"
echo "$CUSTOM_MODELS" | jq -r '.[].name'

# 4. Verificar modelos OpenAI disponíveis
echo "🔗 Verificando modelos OpenAI disponíveis..."
OPENAI_MODELS=$(curl -s -X GET "$BASE_URL/openai/models" \
    -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Modelos OpenAI:"
echo "$OPENAI_MODELS" | jq -r '.data[].id'

echo "🎉 Configuração de modelos concluída!"
