#!/usr/bin/env python3
"""
Script Python para configuração automatizada de modelos OpenWebUI
"""

import requests
import json
import sys
import argparse
from typing import Dict, List, Optional

class OpenWebUIModelManager:
    def __init__(self, base_url: str = "http://localhost:3000", token: str = None):
        self.base_url = base_url.rstrip('/')
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    
    def get_base_models(self) -> List[Dict]:
        """Obter modelos base disponíveis"""
        response = requests.get(f"{self.base_url}/api/v1/models/base", headers=self.headers)
        response.raise_for_status()
        return response.json()
    
    def get_custom_models(self) -> List[Dict]:
        """Obter modelos personalizados criados"""
        response = requests.get(f"{self.base_url}/api/v1/models/", headers=self.headers)
        response.raise_for_status()
        return response.json()
    
    def get_openai_models(self) -> Dict:
        """Obter modelos OpenAI disponíveis"""
        response = requests.get(f"{self.base_url}/openai/models", headers=self.headers)
        response.raise_for_status()
        return response.json()
    
    def create_model(self, model_config: Dict) -> Dict:
        """Criar modelo personalizado"""
        response = requests.post(
            f"{self.base_url}/api/v1/models/create",
            headers=self.headers,
            json=model_config
        )
        response.raise_for_status()
        return response.json()
    
    def delete_model(self, model_id: str) -> bool:
        """Deletar modelo personalizado"""
        response = requests.delete(
            f"{self.base_url}/api/v1/models/{model_id}",
            headers=self.headers
        )
        return response.status_code == 200

def create_doctul_model() -> Dict:
    """Configuração do modelo DocTul"""
    return {
        "id": "doctul",
        "base_model_id": "/home/ai/II-Medical-8B",
        "name": "DocTul",
        "params": {
            "system": """You are DocTul, a clinical assistant for Brazilian doctors (ER, ward, primary care). Always reply in Brazilian Portuguese.
Be practical and medically accurate. When appropriate, be didactic and clear.
Assume Brazilian context: limited resources, CT is more available than MRI.
Follow internal context strictly if provided. Never override or ignore it.
Never guess drug compositions. If a brand name is mentioned, ask for the active ingredient.
Avoid speculation and self-references. Use step-by-step reasoning only when useful. Highlight final recommendations.""",
            "top_p": 0.9,
            "temperature": 0.6
        },
        "meta": {
            "profile_image_url": "/static/favicon.png",
            "description": "Assistente clínico especializado para médicos brasileiros",
            "capabilities": {
                "vision": False,
                "file_upload": False,
                "web_search": False,
                "image_generation": False,
                "code_interpreter": False,
                "citations": False,
                "usage": False
            },
            "suggestion_prompts": [
                "Como proceder com paciente com dor torácica?",
                "Protocolo para hipertensão arterial",
                "Diagnóstico diferencial de febre em adultos",
                "Manejo de diabetes tipo 2 na atenção primária"
            ],
            "tags": ["medicina", "clinica", "brasil"]
        }
    }

def create_general_model() -> Dict:
    """Configuração de um modelo geral para usuários limitados"""
    return {
        "id": "geral",
        "base_model_id": "/home/ai/II-Medical-8B",
        "name": "Assistente Geral",
        "params": {
            "system": "Você é um assistente útil e respeitoso. Responda sempre em português brasileiro de forma clara e educativa.",
            "top_p": 0.95,
            "temperature": 0.7
        },
        "meta": {
            "profile_image_url": "/static/favicon.png",
            "description": "Modelo geral para uso público com quota limitada",
            "capabilities": {
                "vision": False,
                "file_upload": False,
                "web_search": False,
                "image_generation": False,
                "code_interpreter": False,
                "citations": False,
                "usage": True
            },
            "suggestion_prompts": [
                "Explique um conceito científico",
                "Ajude com uma dúvida",
                "Escreva um texto",
                "Faça um resumo"
            ],
            "tags": ["geral", "publico"]
        }
    }

def main():
    parser = argparse.ArgumentParser(description="Gerenciador de Modelos OpenWebUI")
    parser.add_argument("--token", required=True, help="Token de autenticação admin")
    parser.add_argument("--base-url", default="http://localhost:3000", help="URL base da API")
    parser.add_argument("--action", choices=["list", "create", "setup"], default="setup",
                       help="Ação a executar")
    
    args = parser.parse_args()
    
    manager = OpenWebUIModelManager(args.base_url, args.token)
    
    try:
        if args.action == "list":
            print("=== Modelos Base ===")
            base_models = manager.get_base_models()
            for model in base_models:
                print(f"- {model['id']}")
            
            print("\n=== Modelos Personalizados ===")
            custom_models = manager.get_custom_models()
            for model in custom_models:
                print(f"- {model['name']} (ID: {model['id']})")
            
            print("\n=== Modelos OpenAI ===")
            openai_models = manager.get_openai_models()
            for model in openai_models['data']:
                print(f"- {model['id']}")
        
        elif args.action == "create":
            print("Criando modelo DocTul...")
            doctul_config = create_doctul_model()
            result = manager.create_model(doctul_config)
            print(f"✅ Modelo criado: {result['name']}")
        
        elif args.action == "setup":
            print("🔧 Configuração completa de modelos...")
            
            # Criar modelo DocTul
            print("Criando modelo DocTul...")
            try:
                doctul_config = create_doctul_model()
                manager.create_model(doctul_config)
                print("✅ DocTul criado com sucesso!")
            except requests.exceptions.HTTPError as e:
                if "already exists" in str(e):
                    print("⚠️  DocTul já existe, pulando...")
                else:
                    raise
            
            # Criar modelo geral
            print("Criando modelo geral...")
            try:
                general_config = create_general_model()
                manager.create_model(general_config)
                print("✅ Modelo geral criado com sucesso!")
            except requests.exceptions.HTTPError as e:
                if "already exists" in str(e):
                    print("⚠️  Modelo geral já existe, pulando...")
                else:
                    raise
            
            print("🎉 Configuração concluída!")
    
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de API: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
