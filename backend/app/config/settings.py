# Archivo: backend/app/config/settings.py
# Configuración híbrida para SQLite (dev) y PostgreSQL (prod)

import os
from typing import List, Optional
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv('.env.local')

class Settings(BaseSettings):
    """
    Configuración híbrida usando Pydantic Settings.
    Funciona con SQLite (desarrollo) y PostgreSQL (producción).
    """
    
    # Información de la aplicación
    app_name: str = "CMIPRO - Sistema de Alerta Temprana"
    app_version: str = "1.0.0"
    app_description: str = "API para monitoreo de niveles de ríos en Honduras"
    
    # Configuración del servidor
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    debug: bool = True
    environment: str = "development"
    
    # Base de datos (opcional para SQLite)
    database_url: Optional[str] = None
    
    # AWS
    aws_region: str = "us-east-1"
    aws_profile: str = "cmipro-dev"
    
    # Seguridad
    secret_key: str = "dev-secret-key-not-for-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # CORS
    allowed_origins: List[str] = [
        "http://localhost:3000",  # Frontend Next.js development
        "http://localhost:8000",  # FastAPI docs
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000"
    ]
    
    # Configuración NOAA
    noaa_hads_url: str = "https://hads.ncep.noaa.gov/nexhads2/servlet/DecodedData"
    noaa_polling_interval: int = 300  # 5 minutos en segundos
    
    # Estaciones monitoreadas (desde Semana 1)
    monitored_stations: List[str] = ["CHIH3", "SANH3", "RCHH3"]
    
    # Umbrales de riesgo (desde Martes S1)
    risk_levels: dict = {
        "normal": {"min": 0.0, "color": "#22C55E"},
        "low": {"min": 2.0, "color": "#86EFAC"}, 
        "moderate": {"min": 4.0, "color": "#FDE047"},
        "high": {"min": 6.0, "color": "#FB923C"},
        "very_high": {"min": 8.0, "color": "#DC2626"},
        "critical": {"min": 12.0, "color": "#FF0000"}
    }
    
    class Config:
        env_file = '.env.local'
        case_sensitive = False

# Instancia global de configuración
settings = Settings()

# Función para obtener configuración según entorno
def get_settings() -> Settings:
    """
    Factory function para obtener configuración.
    Permite inyección de dependencias en FastAPI.
    """
    return settings

# Configuración específica por entorno
if settings.environment == "production":
    settings.debug = False
    settings.allowed_origins = [
        "https://cmiweather.com",
        "https://www.cmiweather.com"
    ]
elif settings.environment == "staging":
    settings.debug = True
    settings.allowed_origins.extend([
        "https://staging.cmiweather.com"
    ])

# Logging configuration simplificado
LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        },
    },
    "handlers": {
        "default": {
            "formatter": "default",
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stdout",
        },
    },
    "root": {
        "level": "INFO" if settings.environment == "production" else "DEBUG",
        "handlers": ["default"],
    },
}