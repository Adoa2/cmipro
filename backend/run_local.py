# Archivo: backend/run_local.py
# Script para ejecutar FastAPI en desarrollo local

import os
import sys
import uvicorn
import logging
from pathlib import Path

# Agregar el directorio app al path de Python
app_dir = Path(__file__).parent / "app"
sys.path.insert(0, str(app_dir))

# Configurar logging básico
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)

def main():
    """Función principal para ejecutar la aplicación"""
    
    print("🚀 CMIPRO FastAPI Development Server")
    print("=" * 50)
    
    # Verificar que existe .env.local
    env_file = Path(__file__).parent / ".env.local"
    if not env_file.exists():
        print("❌ Error: archivo .env.local no encontrado")
        print("   Crear archivo .env.local con las variables de entorno")
        return
    
    print(f"✅ Variables de entorno: {env_file}")
    
    # Configuración del servidor
    config = {
        "app": "app.main:app",
        "host": "0.0.0.0",
        "port": 8000,
        "reload": True,
        "reload_dirs": ["app"],
        "log_level": "info",
        "access_log": True
    }
    
    print(f"🌐 Servidor: http://localhost:{config['port']}")
    print(f"📖 Documentación: http://localhost:{config['port']}/docs")
    print(f"🔄 Auto-reload: {config['reload']}")
    print("=" * 50)
    
    try:
        # Ejecutar servidor
        uvicorn.run(**config)
    except KeyboardInterrupt:
        print("\n⏹️ Servidor detenido por el usuario")
    except Exception as e:
        logger.error(f"Error ejecutando servidor: {e}")

if __name__ == "__main__":
    main()