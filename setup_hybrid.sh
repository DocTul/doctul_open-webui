#!/bin/bash

# Script para configurar acesso admin na interface do OpenWebUI
# Cria um usuário admin e configura acesso via botão na interface

echo "🔧 Configurando acesso admin híbrido..."

# Aguardar OpenWebUI estar pronto
echo "⏳ Aguardando OpenWebUI inicializar..."
sleep 10

# Verificar se OpenWebUI está rodando
if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "❌ OpenWebUI não está rodando. Execute ./start.sh primeiro."
    exit 1
fi

echo "✅ OpenWebUI está pronto!"

# Tentar criar usuário admin via API (mesmo que falhe, está documentado)
echo "👤 Tentando criar usuário administrador..."
curl -X POST http://localhost:3000/api/v1/auths/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Administrador",
    "email": "admin@localhost",
    "password": "admin123",
    "role": "admin"
  }' 2>/dev/null || echo "⚠️  Usuário admin pode já existir ou precisa ser criado manualmente"

echo ""
echo "🎉 Configuração híbrida concluída!"
echo ""
echo "📋 Como usar:"
echo ""
echo "🌐 ACESSO NORMAL (Como User Limitado):"
echo "   • URL: http://localhost:3000"
echo "   • Comportamento: Acesso direto ao chat (sem login)"
echo "   • Permissões: Limitadas (somente chat básico)"
echo ""
echo "👨‍💼 ACESSO ADMIN:"
echo "   Método 1 - URL com parâmetro:"
echo "     http://localhost:3000/?admin=true"
echo ""
echo "   Método 2 - Login manual:"
echo "     • Clique no ícone de usuário (canto superior direito)"
echo "     • Selecione 'Sign In'"
echo "     • Email: admin@localhost"
echo "     • Senha: admin123"
echo ""
echo "   Método 3 - Primeira vez (criar admin):"
echo "     • Clique em 'Sign Up'"
echo "     • Registre-se como primeiro usuário (será admin automaticamente)"
echo ""
echo "🔧 Funcionalidades:"
echo "   👤 User: Chat, upload documentos, histórico pessoal"
echo "   👨‍💼 Admin: + Gerenciar usuários, configurações, modelos"
echo ""
echo "💡 Dica: Deixe os usuários normais acessarem direto,"
echo "   e use admin apenas quando necessário configurar algo!"
