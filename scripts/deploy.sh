#!/bin/bash

# Script de Deploy Completo - DocTul OpenWebUI
# Configura modelos, quota e configurações necessárias

set -e  # Para em caso de erro

echo "🚀 Iniciando deploy completo do DocTul OpenWebUI..."

# Configurações
BASE_URL="http://localhost:3000"
CONFIG_DIR="/home/ai/doctul_open-webui/config"
SCRIPTS_DIR="/home/ai/doctul_open-webui/scripts"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se serviços estão rodando
check_services() {
    log_info "Verificando serviços..."
    
    # Verificar OpenWebUI
    if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
        log_success "OpenWebUI está rodando"
    else
        log_error "OpenWebUI não está acessível em $BASE_URL"
        exit 1
    fi
    
    # Verificar Redis
    if docker exec redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis está rodando"
    else
        log_warning "Redis pode não estar acessível"
    fi
    
    # Verificar vLLM
    if curl -s "http://localhost:8001/v1/models" > /dev/null 2>&1; then
        log_success "vLLM está rodando"
    else
        log_warning "vLLM pode não estar acessível"
    fi
}

# Função para obter token admin
get_admin_token() {
    log_info "Tentando obter token admin..."
    
    # Verificar se já existe admin
    ADMIN_CHECK=$(curl -s -X GET "$BASE_URL/api/v1/auths/" -H "Content-Type: application/json" | jq -r '.[] | select(.role == "admin") | .id' 2>/dev/null || echo "")
    
    if [ -z "$ADMIN_CHECK" ]; then
        log_info "Criando usuário admin..."
        
        # Criar admin via setup
        ADMIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auths/setup/admin" \
            -H "Content-Type: application/json" \
            -d '{
                "name": "Admin DocTul",
                "email": "admin@doctul.local",
                "password": "admin123"
            }' 2>/dev/null || echo "")
        
        if echo "$ADMIN_RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
            ADMIN_TOKEN=$(echo "$ADMIN_RESPONSE" | jq -r '.token')
            log_success "Admin criado com sucesso"
        else
            log_error "Falha ao criar admin"
            exit 1
        fi
    else
        log_info "Admin já existe, fazendo login..."
        
        # Login como admin
        LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auths/signin" \
            -H "Content-Type: application/json" \
            -d '{
                "email": "admin@doctul.local",
                "password": "admin123"
            }' 2>/dev/null || echo "")
        
        if echo "$LOGIN_RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
            ADMIN_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
            log_success "Login admin realizado"
        else
            log_error "Falha no login admin"
            log_info "Tentando com credenciais padrão..."
            exit 1
        fi
    fi
}

# Função para configurar modelos
configure_models() {
    log_info "Configurando modelos..."
    
    if [ -f "$SCRIPTS_DIR/model_manager.py" ]; then
        log_info "Usando script Python para configurar modelos..."
        cd "$SCRIPTS_DIR"
        python3 model_manager.py --token "$ADMIN_TOKEN" --action setup
        log_success "Modelos configurados via Python"
    else
        log_info "Usando script bash para configurar modelos..."
        if [ -f "$SCRIPTS_DIR/configure_models.sh" ]; then
            bash "$SCRIPTS_DIR/configure_models.sh" "$ADMIN_TOKEN"
            log_success "Modelos configurados via bash"
        else
            log_error "Nenhum script de configuração encontrado"
            exit 1
        fi
    fi
}

# Função para verificar configuração
verify_setup() {
    log_info "Verificando configuração..."
    
    # Verificar modelos criados
    MODELS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/v1/models/" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json")
    
    MODEL_COUNT=$(echo "$MODELS_RESPONSE" | jq length 2>/dev/null || echo "0")
    
    if [ "$MODEL_COUNT" -gt 0 ]; then
        log_success "Modelos configurados: $MODEL_COUNT"
        echo "$MODELS_RESPONSE" | jq -r '.[] | "  - \(.name) (ID: \(.id))"'
    else
        log_warning "Nenhum modelo personalizado encontrado"
    fi
    
    # Verificar modelos OpenAI disponíveis
    OPENAI_MODELS=$(curl -s -X GET "$BASE_URL/openai/models" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    OPENAI_COUNT=$(echo "$OPENAI_MODELS" | jq '.data | length' 2>/dev/null || echo "0")
    log_info "Modelos OpenAI disponíveis: $OPENAI_COUNT"
}

# Função para mostrar informações finais
show_final_info() {
    log_success "Deploy concluído com sucesso!"
    echo ""
    echo "📋 Informações do Sistema:"
    echo "  🌐 OpenWebUI: $BASE_URL"
    echo "  🔐 Admin: admin@doctul.local / admin123"
    echo "  🚀 vLLM: http://localhost:8001"
    echo "  📊 Redis: Container redis"
    echo ""
    echo "🔧 Scripts Disponíveis:"
    echo "  📁 $SCRIPTS_DIR/model_manager.py"
    echo "  📁 $SCRIPTS_DIR/configure_models.sh"
    echo "  📁 $CONFIG_DIR/models_config.json"
    echo ""
    echo "💬 Sistema de Quota:"
    echo "  👤 Anônimo: 10 mensagens/mês"
    echo "  🔐 Autenticado: 30 mensagens/mês"
    echo "  💎 Premium: Ilimitado"
    echo ""
    echo "🎯 Modelos Configurados:"
    echo "  🏥 DocTul: Assistente médico brasileiro"
    echo "  📚 Geral: Uso público com quota"
    echo "  🔬 Consultoria: Especialista premium"
}

# Função principal
main() {
    check_services
    get_admin_token
    configure_models
    verify_setup
    show_final_info
}

# Verificar dependências
if ! command -v jq &> /dev/null; then
    log_error "jq não está instalado. Instale com: sudo apt install jq"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_error "curl não está instalado. Instale com: sudo apt install curl"
    exit 1
fi

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
