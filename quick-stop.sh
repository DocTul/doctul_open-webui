#!/bin/bash

# Script rápido para parar OpenWebUI
PID=$(docker inspect openwebui --format '{{.State.Pid}}' 2>/dev/null)
if [ "$PID" != "0" ] && [ -n "$PID" ]; then
    echo "Matando PID: $PID"
    sudo kill -9 $PID
fi

echo "Removendo container..."
docker rm openwebui 2>/dev/null || echo "Container já removido"
echo "✅ Pronto!"
