"""
Controle de cotas para usuários anônimos e autenticados
"""
import hashlib
import time
from typing import Optional
from fastapi import Request, HTTPException
from open_webui.config import ANONYMOUS_CHAT_LIMIT, FREE_CHAT_QUOTA_AFTER_LOGIN
from open_webui.models.users import UserModel


def get_anonymous_identifier(request: Request) -> str:
    """
    Gera um identificador único para usuários anônimos baseado em IP + User-Agent
    para resistir à limpeza de cookies
    """
    client_ip = request.client.host
    user_agent = request.headers.get("user-agent", "")
    fingerprint = f"{client_ip}:{user_agent}"
    return hashlib.sha256(fingerprint.encode()).hexdigest()


def get_current_month_key() -> str:
    """
    Retorna uma chave baseada no mês atual para reset mensal automático
    """
    current_time = time.time()
    current_month = time.strftime("%Y-%m", time.localtime(current_time))
    return current_month


def check_and_increment_quota(request: Request, user: Optional[UserModel]) -> bool:
    """
    Verifica e incrementa quota para usuários anônimos e autenticados
    Retorna True se dentro da quota, False se excedida
    """
    try:
        import redis
        redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)
        redis_client.ping()  # Test connection
        
        anonymous_id = get_anonymous_identifier(request)
        month_key = get_current_month_key()
        redis_key = f"anon_quota:{month_key}:{anonymous_id}"
        
        # Buscar contador atual
        stored_count = redis_client.get(redis_key)
        current_count = int(stored_count) if stored_count else 0
        
        # Verificar se excede o limite - corrigir acesso ao PersistentConfig
        limit_value = int(ANONYMOUS_CHAT_LIMIT.value) if hasattr(ANONYMOUS_CHAT_LIMIT, 'value') else int(ANONYMOUS_CHAT_LIMIT)
        if current_count >= limit_value:
            return False
        
        # Incrementar contador
        new_count = current_count + 1
        redis_client.setex(redis_key, 86400 * 31, new_count)  # Expira em 31 dias
        
        return True
        
    except Exception as e:
        # Em caso de erro no Redis, permitir (fallback)
        print(f"Redis error in anonymous quota check: {e}")
        return True


def should_enforce_quota(request: Request, user: Optional[UserModel]) -> bool:
    """
    Determina se a quota deve ser aplicada baseado no contexto do usuário
    PADRÃO: SEMPRE aplicar quota, exceto em contextos admin explícitos
    """
    # Verificar parâmetros de URL para contexto admin EXPLÍCITO
    url_path = str(request.url.path)
    url_query = str(request.url.query) if request.url.query else ""
    
    # Apenas bypass se explicitamente solicitado via URL
    if "/admin" in url_path or "admin=true" in url_query:
        return False
    
    # SEMPRE aplicar quota por padrão, mesmo para admins
    # Isso garante que admins vejam a experiência real do usuário
    return True


def enforce_chat_quota(request: Request, user: Optional[UserModel] = None) -> dict:
    """
    Função principal para verificar e aplicar controle de cotas
    """
    # Verificar se deve aplicar quota
    if not should_enforce_quota(request, user):
        return {"allowed": True, "user_type": "admin_bypass"}
    
    if user is None or (hasattr(user, 'id') and user.id.startswith("anonymous_")):
        # Usuário anônimo
        quota_allowed = check_and_increment_quota(request, user)
        
        if not quota_allowed:
            raise HTTPException(
                status_code=403,
                detail="ANONYMOUS_LIMIT_REACHED",
                headers={
                    "X-Chat-Status": "anonymous_limit_reached"
                }
            )
        
        return {"allowed": True, "user_type": "anonymous"}
    else:
        # Usuário autenticado - por enquanto permite tudo
        return {"allowed": True, "user_type": "authenticated"}
