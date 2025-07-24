#!/bin/bash

# Script de Monitoramento - DocTul OpenWebUI
# Monitora quota de usuários, uso de modelos e status do sistema

set -e

# Configurações
BASE_URL="http://localhost:3000"
REDIS_CONTAINER="redis"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# Função para verificar status dos serviços
check_services_status() {
    log_header "📊 STATUS DOS SERVIÇOS"
    echo "================================"
    
    # OpenWebUI
    if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
        log_success "OpenWebUI: Online ($BASE_URL)"
    else
        log_error "OpenWebUI: Offline"
    fi
    
    # Redis
    if docker exec $REDIS_CONTAINER redis-cli ping > /dev/null 2>&1; then
        log_success "Redis: Online"
        
        # Estatísticas do Redis
        REDIS_INFO=$(docker exec $REDIS_CONTAINER redis-cli info memory | grep used_memory_human)
        echo "  💾 $REDIS_INFO"
    else
        log_error "Redis: Offline"
    fi
    
    # vLLM
    if curl -s "http://localhost:8001/v1/models" > /dev/null 2>&1; then
        log_success "vLLM: Online (http://localhost:8001)"
        
        # Modelos vLLM
        VLLM_MODELS=$(curl -s "http://localhost:8001/v1/models" | jq -r '.data[].id' 2>/dev/null || echo "Erro ao obter modelos")
        echo "  🤖 Modelo: $VLLM_MODELS"
    else
        log_error "vLLM: Offline"
    fi
    
    echo ""
}

# Função para verificar quota de usuários
check_quota_usage() {
    log_header "📈 USO DE QUOTA"
    echo "================================"
    
    if docker exec $REDIS_CONTAINER redis-cli ping > /dev/null 2>&1; then
        # Obter todas as chaves de quota
        QUOTA_KEYS=$(docker exec $REDIS_CONTAINER redis-cli keys "quota:*" 2>/dev/null || echo "")
        
        if [ -z "$QUOTA_KEYS" ]; then
            log_info "Nenhuma quota registrada ainda"
        else
            echo "👥 Usuários com quota registrada:"
            echo "$QUOTA_KEYS" | while read -r key; do
                if [ -n "$key" ]; then
                    COUNT=$(docker exec $REDIS_CONTAINER redis-cli get "$key" 2>/dev/null || echo "0")
                    USER_ID=$(echo "$key" | cut -d':' -f2)
                    
                    if [ "$USER_ID" = "anonymous" ]; then
                        echo "  🕶️  Anônimo: $COUNT/10 mensagens"
                    else
                        echo "  👤 $USER_ID: $COUNT mensagens"
                    fi
                fi
            done
        fi
        
        # Estatísticas gerais
        TOTAL_KEYS=$(docker exec $REDIS_CONTAINER redis-cli dbsize 2>/dev/null || echo "0")
        echo "  📊 Total de chaves Redis: $TOTAL_KEYS"
    else
        log_error "Redis não acessível para verificar quota"
    fi
    
    echo ""
}

# Função para verificar logs recentes
check_recent_logs() {
    log_header "📝 LOGS RECENTES"
    echo "================================"
    
    # Logs do OpenWebUI (últimas 10 linhas)
    log_info "OpenWebUI (últimas 10 linhas):"
    docker logs --tail 10 doctul_open-webui-main-1 2>/dev/null | tail -5 || log_warning "Logs do OpenWebUI não disponíveis"
    
    echo ""
    
    # Logs do Redis (se houver)
    log_info "Redis (informações):"
    docker exec $REDIS_CONTAINER redis-cli info stats | grep -E "total_commands_processed|total_connections_received" 2>/dev/null || log_warning "Stats do Redis não disponíveis"
    
    echo ""
}

# Função para verificar modelos disponíveis
check_models() {
    log_header "🤖 MODELOS DISPONÍVEIS"
    echo "================================"
    
    # Verificar se conseguimos acessar sem token (público)
    PUBLIC_MODELS=$(curl -s "$BASE_URL/openai/models" 2>/dev/null || echo "")
    
    if echo "$PUBLIC_MODELS" | jq -e '.data' > /dev/null 2>&1; then
        log_success "Modelos acessíveis publicamente:"
        echo "$PUBLIC_MODELS" | jq -r '.data[] | "  🔹 \(.id)"' 2>/dev/null || echo "  Erro ao processar resposta"
    else
        log_warning "Modelos não acessíveis publicamente (pode precisar de auth)"
    fi
    
    echo ""
}

# Função para verificar uso de recursos
check_resource_usage() {
    log_header "💻 USO DE RECURSOS"
    echo "================================"
    
    # CPU e Memória dos containers
    log_info "Uso de recursos dos containers:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(doctul|NAME)" || log_warning "Erro ao obter stats dos containers"
    
    echo ""
    
    # Espaço em disco
    log_info "Espaço em disco (pasta do projeto):"
    du -sh /home/ai/doctul_open-webui/ 2>/dev/null || log_warning "Erro ao verificar espaço em disco"
    
    # Espaço do modelo
    log_info "Espaço do modelo II-Medical-8B:"
    du -sh /home/ai/II-Medical-8B/ 2>/dev/null || log_warning "Modelo não encontrado"
    
    echo ""
}

# Função para exibir resumo de configuração
show_config_summary() {
    log_header "⚙️  RESUMO DA CONFIGURAÇÃO"
    echo "================================"
    
    echo "🌐 URLs de Acesso:"
    echo "  - Interface: $BASE_URL"
    echo "  - API OpenAI: $BASE_URL/openai"
    echo "  - vLLM direto: http://localhost:8001"
    echo ""
    
    echo "📋 Sistema de Quota:"
    echo "  - Anônimo: 10 mensagens/mês"
    echo "  - Autenticado: 30 mensagens/mês" 
    echo "  - Reset: Primeiro dia do mês"
    echo ""
    
    echo "🏥 Modelos Configurados:"
    echo "  - DocTul: Assistente médico brasileiro"
    echo "  - Geral: Modelo público com quota"
    echo "  - Consultoria: Especialista premium"
    echo ""
}

# Função para executar testes básicos
run_basic_tests() {
    log_header "🧪 TESTES BÁSICOS"
    echo "================================"
    
    # Teste de conectividade
    log_info "Testando conectividade..."
    
    if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
        log_success "Health check: OK"
    else
        log_error "Health check: FALHOU"
    fi
    
    # Teste de quota anônima
    log_info "Testando sistema de quota..."
    
    CURRENT_QUOTA=$(docker exec $REDIS_CONTAINER redis-cli get "quota:anonymous" 2>/dev/null || echo "0")
    log_info "Quota anônima atual: $CURRENT_QUOTA/10"
    
    echo ""
}

# Função principal
main() {
    echo "🔍 MONITORAMENTO DOCTUL OPENWEBUI"
    echo "=================================="
    echo "$(date)"
    echo ""
    
    check_services_status
    check_quota_usage
    check_models
    check_resource_usage
    show_config_summary
    run_basic_tests
    
    log_success "Monitoramento concluído!"
    echo ""
    echo "💡 Para monitoramento contínuo, execute:"
    echo "   watch -n 30 $0"
}

# Verificar dependências
if ! command -v jq &> /dev/null; then
    log_warning "jq não está instalado. Algumas funcionalidades podem não funcionar."
fi

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
