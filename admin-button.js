// Script para adicionar botão de acesso admin na interface OpenWebUI

function initAdminButton() {
    'use strict';
    
    // Verificar se já existe o botão para evitar duplicatas
    if (document.querySelector('.admin-access-button')) {
        return;
    }
    
    // Criar o botão de acesso admin
    const adminButton = document.createElement('a');
    adminButton.className = 'admin-access-button';
    adminButton.href = '/?admin=true';
    adminButton.textContent = 'Admin';
    adminButton.title = 'Clique para acessar como administrador';
    
    // Adicionar evento de clique alternativo
    adminButton.addEventListener('click', function(e) {
        e.preventDefault();
        
        // Opção 1: Redirecionar com parâmetro admin
        window.location.href = '/?admin=true';
        
        // Opção 2: Mostrar modal de login (comentado)
        // showAdminLogin();
    });
    
    // Adicionar à página
    document.body.appendChild(adminButton);
    
    // Função para mostrar modal de login admin (alternativa)
    function showAdminLogin() {
        const modal = document.createElement('div');
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 10000;
        `;
        
        const form = document.createElement('div');
        form.style.cssText = `
            background: white;
            padding: 20px;
            border-radius: 8px;
            max-width: 300px;
            width: 100%;
        `;
        
        form.innerHTML = `
            <h3 style="margin-top: 0;">Acesso Admin</h3>
            <p style="color: #666; font-size: 14px;">Use as credenciais de administrador:</p>
            <div style="margin: 10px 0;">
                <strong>Email:</strong> admin@localhost<br>
                <strong>Senha:</strong> admin123
            </div>
            <div style="display: flex; gap: 10px; margin-top: 15px;">
                <button onclick="window.location.href='/auth'" style="flex: 1; padding: 8px; background: #dc2626; color: white; border: none; border-radius: 4px; cursor: pointer;">
                    Ir para Login
                </button>
                <button onclick="this.closest('[style*=\"position: fixed\"]').remove()" style="flex: 1; padding: 8px; background: #6b7280; color: white; border: none; border-radius: 4px; cursor: pointer;">
                    Cancelar
                </button>
            </div>
        `;
        
        modal.appendChild(form);
        document.body.appendChild(modal);
        
        // Fechar modal clicando fora
        modal.addEventListener('click', function(e) {
            if (e.target === modal) {
                modal.remove();
            }
        });
    }
    
    // Verificar se estamos em modo admin
    if (window.location.search.indexOf('admin=true') !== -1) {
        adminButton.style.background = '#059669';
        adminButton.textContent = '👑 Admin';
        adminButton.title = 'Modo administrador ativo';
        
        // Adicionar indicador visual de modo admin
        const indicator = document.createElement('div');
        indicator.style.cssText = `
            position: fixed;
            top: 10px;
            right: 10px;
            background: #059669;
            color: white;
            padding: 4px 12px;
            border-radius: 16px;
            font-size: 12px;
            font-weight: bold;
            z-index: 9998;
        `;
        indicator.textContent = '👑 Modo Admin';
        document.body.appendChild(indicator);
    }
    
    console.log('🔧 Botão de acesso admin adicionado!');
}

// Executar quando a página carregar
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAdminButton);
} else {
    // Se já carregou, executar imediatamente
    setTimeout(initAdminButton, 100);
}
