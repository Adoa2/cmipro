# Archivo: backend/app/main.py
# Aplicación principal FastAPI simplificada y funcional

import logging
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .config.database import init_db, test_connection, check_tables
from .config.settings import get_settings, Settings
from .routers import stations

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Crear instancia de FastAPI
def create_app() -> FastAPI:
    """Factory function para crear aplicación FastAPI"""
    
    settings = get_settings()
    
    app = FastAPI(
        title=settings.app_name,
        description=settings.app_description,
        version=settings.app_version,
        debug=settings.debug,
        docs_url="/docs",
        redoc_url="/redoc"
    )
    
    # Configurar CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["*"],
    )
    
    return app

# Crear aplicación
app = create_app()

# Event handlers
@app.on_event("startup")
async def startup_event():
    """Eventos al iniciar la aplicación"""
    logger.info("🚀 Iniciando CMIPRO API...")
    
    # Inicializar base de datos
    if init_db():
        logger.info("✅ Base de datos inicializada correctamente")
        
        # Mostrar información de tablas
        tables_info = check_tables()
        logger.info(f"📊 Tablas disponibles: {tables_info['tables']}")
        if tables_info['counts']:
            logger.info(f"📈 Registros por tabla: {tables_info['counts']}")
    else:
        logger.error("❌ Error inicializando base de datos")
    
    logger.info(f"🌐 API iniciada en modo: {get_settings().environment}")
    logger.info("📖 Documentación disponible en: /docs")

@app.on_event("shutdown")
async def shutdown_event():
    """Eventos al cerrar la aplicación"""
    logger.info("⏹️ Cerrando CMIPRO API...")

# Incluir routers
app.include_router(stations.router, prefix="/api/v1")

# Rutas principales
@app.get("/")
async def root():
    """Endpoint raíz - información de la API"""
    settings = get_settings()
    return {
        "message": "CMIPRO - Sistema de Alerta Temprana para Honduras",
        "description": "API REST para monitoreo de niveles de ríos en el Valle de Sula",
        "version": settings.app_version,
        "environment": settings.environment,
        "timestamp": datetime.utcnow(),
        "status": "operational",
        "coverage": {
            "rivers": ["Ulúa", "Chamelecón"],
            "stations": settings.monitored_stations,
            "population_protected": "400,000+ personas"
        },
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "stations": "/api/v1/stations"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint para monitoreo"""
    try:
        # Verificar conexión a base de datos
        db_status = test_connection()
        
        return {
            "status": "healthy" if db_status else "unhealthy",
            "timestamp": datetime.utcnow(),
            "database": "connected" if db_status else "disconnected",
            "version": get_settings().app_version,
            "environment": get_settings().environment
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "timestamp": datetime.utcnow(),
                "error": str(e)
            }
        )

@app.get("/api/v1/status")
async def api_status():
    """Estado detallado de la API y servicios"""
    try:
        settings = get_settings()
        
        # Verificar estado de la base de datos
        tables_info = check_tables()
        db_connected = len(tables_info['tables']) > 0
        
        # Información del sistema
        system_info = {
            "api": {
                "name": settings.app_name,
                "version": settings.app_version,
                "environment": settings.environment,
                "debug_mode": settings.debug,
                "timestamp": datetime.utcnow()
            },
            "database": {
                "status": "connected" if db_connected else "disconnected",
                "type": "SQLite (desarrollo)" if settings.environment == "development" else "PostgreSQL (producción)",
                "tables_count": len(tables_info['tables']),
                "tables": tables_info['tables'],
                "records_count": tables_info['counts'],
                "total_records": sum(tables_info['counts'].values()) if tables_info['counts'] else 0
            },
            "monitoring": {
                "stations_configured": len(settings.monitored_stations),
                "monitored_stations": settings.monitored_stations,
                "risk_levels_defined": len(settings.risk_levels)
            },
            "coverage": {
                "rivers": ["Río Ulúa", "Río Chamelecón"],
                "locations": ["San Pedro Sula", "El Progreso", "La Lima", "Villanueva"],
                "population_protected": 400000,
                "area_coverage": "Valle de Sula, Honduras"
            }
        }
        
        return {
            "success": True,
            "data": system_info,
            "message": "Sistema operativo y funcional"
        }
        
    except Exception as e:
        logger.error(f"Status check failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error verificando estado del sistema: {str(e)}"
        )

# Handler global de errores
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Handler personalizado para excepciones HTTP"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": exc.status_code,
                "message": exc.detail
            },
            "timestamp": datetime.utcnow(),
            "path": str(request.url)
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Handler para excepciones generales"""
    logger.error(f"Error no manejado: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": 500,
                "message": "Error interno del servidor"
            },
            "timestamp": datetime.utcnow(),
            "path": str(request.url)
        }
    )

# Punto de entrada para desarrollo
if __name__ == "__main__":
    import uvicorn
    
    settings = get_settings()
    
    uvicorn.run(
        "main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.debug,
        log_level="info"
    )