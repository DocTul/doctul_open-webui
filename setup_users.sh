#!/bin/bash

# Script para configurar usuários padrão no OpenWebUI
# Opção A: Login Automático como User

echo "🔧 Configurando usuários padrão do OpenWebUI..."

# Aguardar OpenWebUI estar pronto
echo "⏳ Aguardando OpenWebUI inicializar..."
sleep 15

# Verificar se OpenWebUI está rodando
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "❌ OpenWebUI não está rodando. Execute ./start.sh primeiro."
    exit 1
fi

echo "✅ OpenWebUI está pronto!"

# Criar usuário admin (primeiro usuário é sempre admin)
echo "👤 Criando usuário administrador..."
curl -X POST http://localhost:3000/api/v1/auths/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Administrador",
    "email": "admin@localhost",
    "password": "admin123",
    "role": "admin"
  }' || echo "⚠️  Admin pode já existir"

# Criar usuário padrão
echo "👥 Criando usuário padrão..."
curl -X POST http://localhost:3000/api/v1/auths/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Usuário Padrão",
    "email": "user@localhost", 
    "password": "user123",
    "role": "user"
  }' || echo "⚠️  Usuário pode já existir"

echo ""
echo "🎉 Configuração concluída!"
echo ""
echo "📋 Credenciais criadas:"
echo "   👨‍💼 ADMIN:"
echo "      Email: admin@localhost"
echo "      Senha: admin123"
echo ""
echo "   👤 USER:"
echo "      Email: user@localhost"
echo "      Senha: user123"
echo ""
echo "🌐 Acesso: http://localhost:3000"
echo "💡 Para acesso rápido como user, use as credenciais acima"
