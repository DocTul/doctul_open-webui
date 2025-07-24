#!/bin/bash

echo "🔥 PURGE COMPLETO DO SISTEMA (v3 - Definitivo) 🔥"
echo "================================================="
echo "Este script irá forçar a parada e remoção de tudo relacionado ao OpenWebUI e Keycloak."

# --- 1. MATAR PROCESSOS ---
echo "--- Etapa 1: Forçando o encerramento de processos travados ---"
PIDS=$(ps aux | grep -E "openwebui|keycloak|quarkus|uvicorn" | grep -v grep | awk '{print $2}')
if [ -n "$PIDS" ]; then
    echo "📍 PIDs encontrados: $PIDS. Encerrando com 'kill -9'..."
    sudo kill -9 $PIDS 2>/dev/null || true
    sleep 2
else
    echo "✅ Nenhum processo relevante encontrado."
fi

# --- 2. PARAR E REMOVER CONTÊINERES ---
echo ""
echo "--- Etapa 2: Parando e removendo contêineres ---"
CONTAINERS=$(sudo docker ps -a -q --filter "name=openwebui" --filter "name=keycloak")
if [ -n "$CONTAINERS" ]; then
    echo "🛑 Parando e removendo contêineres..."
    # Forçar kill dos processos de container para evitar 'permission denied'
    for cid in $CONTAINERS; do
        echo "🔪 Matando processo de container $cid..."
        hostpid=$(sudo docker inspect --format '{{.State.Pid}}' $cid)
        sudo kill -9 $hostpid 2>/dev/null || true
    done
    sudo docker stop $CONTAINERS 2>/dev/null || true
    sudo docker rm -f $CONTAINERS 2>/dev/null || true
else
    echo "✅ Nenhum contêiner relevante encontrado."
fi

# --- 3. LIMPAR REDES ---
echo ""
echo "--- Etapa 3: Removendo redes ---"
NETWORKS=$(sudo docker network ls --format '{{.Name}}' | grep -E "openwebui|keycloak")
if [ -n "$NETWORKS" ]; then
    echo "🌐 Removendo redes..."
    echo "$NETWORKS" | xargs -r sudo docker network rm 2>/dev/null || true
else
    echo "✅ Nenhuma rede relevante encontrada."
fi

# --- 4. LIMPAR VOLUMES ---
echo ""
echo "--- Etapa 4: Removendo volumes ---"
VOLUMES=$(sudo docker volume ls --format '{{.Name}}' | grep -E "openwebui|keycloak")
if [ -n "$VOLUMES" ]; then
    echo "💣 Removendo volumes..."
    echo "$VOLUMES" | xargs -r sudo docker volume rm -f 2>/dev/null || true
else
    echo "✅ Nenhum volume relevante encontrado."
fi

# --- 5. LIMPEZA GERAL DO SISTEMA DOCKER ---
echo ""
echo "--- Etapa 5: Limpeza geral do sistema Docker (prune) ---"
sudo docker system prune -a -f --volumes

echo ""
echo "✅ PURGE COMPLETO FINALIZADO!"
echo "🎯 Sistema limpo e pronto para uma nova instalação."
