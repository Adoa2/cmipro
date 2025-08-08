# Archivo: backend/app/config/database.py
# Configuración híbrida: SQLite para desarrollo, PostgreSQL para producción

import os
import logging
from typing import Generator
from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv('.env.local')

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Determinar qué base de datos usar
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
DATABASE_URL = os.getenv("DATABASE_URL")

if ENVIRONMENT == "development":
    # Usar SQLite para desarrollo local
    DATABASE_URL = "sqlite:///./cmipro_dev.db"
    logger.info("🔄 Usando SQLite para desarrollo local")
    
    # Configuración SQLite
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},  # Solo para SQLite
        echo=True if os.getenv("DEBUG") == "true" else False
    )
else:
    # Usar PostgreSQL para producción
    if not DATABASE_URL:
        raise ValueError("DATABASE_URL no está configurada para producción")
    
    logger.info("🔄 Usando PostgreSQL para producción")
    
    # Configuración PostgreSQL
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_recycle=300,
        echo=True if os.getenv("DEBUG") == "true" else False
    )

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para modelos
Base = declarative_base()

# Dependency para obtener sesión DB
def get_db() -> Generator[Session, None, None]:
    """
    Dependency que proporciona sesión de base de datos.
    Se cierra automáticamente después de cada request.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Función para probar conectividad
def test_connection() -> bool:
    """
    Prueba la conexión con la base de datos.
    """
    try:
        with engine.connect() as connection:
            if ENVIRONMENT == "development":
                result = connection.execute(text("SELECT 1"))
                logger.info("✅ Conexión exitosa a SQLite")
            else:
                result = connection.execute(text("SELECT version()"))
                version = result.fetchone()[0]
                logger.info(f"✅ Conexión exitosa a PostgreSQL: {version}")
            return True
    except Exception as e:
        logger.error(f"❌ Error conectando a base de datos: {e}")
        return False

# Función para verificar tablas existentes
def check_tables() -> dict:
    """
    Verifica qué tablas existen en la base de datos.
    """
    try:
        with engine.connect() as connection:
            if ENVIRONMENT == "development":
                # Query para SQLite
                result = connection.execute(text("""
                    SELECT name FROM sqlite_master 
                    WHERE type='table' AND name NOT LIKE 'sqlite_%'
                    ORDER BY name;
                """))
            else:
                # Query para PostgreSQL
                result = connection.execute(text("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'
                    ORDER BY table_name;
                """))
            
            if ENVIRONMENT == "development":
                tables = [row[0] for row in result.fetchall()]
            else:
                tables = [row[0] for row in result.fetchall()]
            
            # Contar registros en cada tabla
            table_counts = {}
            for table in tables:
                count_result = connection.execute(text(f"SELECT COUNT(*) FROM {table}"))
                table_counts[table] = count_result.fetchone()[0]
            
            logger.info(f"✅ Tablas encontradas: {tables}")
            return {"tables": tables, "counts": table_counts}
    except Exception as e:
        logger.error(f"❌ Error verificando tablas: {e}")
        return {"tables": [], "counts": {}}

# Función para crear tablas de desarrollo
def create_dev_tables():
    """
    Crear tablas básicas para desarrollo con SQLite.
    """
    if ENVIRONMENT != "development":
        return
    
    try:
        with engine.connect() as connection:
            # Crear tabla stations
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS stations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    nwsli_id TEXT NOT NULL UNIQUE,
                    name TEXT NOT NULL,
                    river_name TEXT NOT NULL,
                    location TEXT,
                    latitude REAL,
                    longitude REAL,
                    status TEXT DEFAULT 'active',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # Crear tabla hydrologic_readings
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS hydrologic_readings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    station_id INTEGER NOT NULL,
                    timestamp DATETIME NOT NULL,
                    water_level_m REAL NOT NULL,
                    flow_rate_cms REAL,
                    temperature_c REAL,
                    source TEXT DEFAULT 'NOAA',
                    quality_flag TEXT DEFAULT 'good',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (station_id) REFERENCES stations (id)
                )
            """))
            
            # Crear tabla station_thresholds
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS station_thresholds (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    station_id INTEGER NOT NULL,
                    normal_max REAL NOT NULL,
                    low_max REAL NOT NULL,
                    moderate_max REAL NOT NULL,
                    high_max REAL NOT NULL,
                    very_high_max REAL NOT NULL,
                    critical_min REAL NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (station_id) REFERENCES stations (id)
                )
            """))
            
            # Insertar datos de prueba de las 3 estaciones del Valle de Sula
            connection.execute(text("""
                INSERT OR IGNORE INTO stations 
                (nwsli_id, name, river_name, location, latitude, longitude) 
                VALUES 
                ('CHIH3', 'Ulúa en Chinda', 'Ulúa', 'Chinda', 15.3847, -87.9547),
                ('SANH3', 'Ulúa en Santiago', 'Ulúa', 'Santiago', 15.2941, -87.9234),
                ('RCHH3', 'Chamelecón en El Tablón', 'Chamelecón', 'El Tablón', 15.4234, -88.0123)
            """))
            
            # Insertar umbrales de riesgo (del Martes S1)
            connection.execute(text("""
                INSERT OR IGNORE INTO station_thresholds 
                (station_id, normal_max, low_max, moderate_max, high_max, very_high_max, critical_min)
                SELECT 
                    s.id, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0
                FROM stations s 
                WHERE NOT EXISTS (
                    SELECT 1 FROM station_thresholds st WHERE st.station_id = s.id
                )
            """))
            
            # Insertar algunas lecturas de prueba
            connection.execute(text("""
                INSERT OR IGNORE INTO hydrologic_readings 
                (station_id, timestamp, water_level_m, flow_rate_cms)
                VALUES 
                (1, datetime('now', '-1 hour'), 3.2, 45.8),
                (1, datetime('now', '-2 hours'), 3.1, 44.2),
                (2, datetime('now', '-1 hour'), 2.5, 35.2),
                (3, datetime('now', '-1 hour'), 4.1, 52.3)
            """))
            
            connection.commit()
            logger.info("✅ Tablas SQLite creadas con datos de prueba del Valle de Sula")
            
    except Exception as e:
        logger.error(f"❌ Error creando tablas de desarrollo: {e}")

# Función de inicialización
def init_db():
    """
    Inicializa la base de datos y verifica conectividad.
    """
    logger.info("🔄 Inicializando base de datos...")
    logger.info(f"📍 Entorno: {ENVIRONMENT}")
    logger.info(f"🗄️ Database: {'SQLite (local)' if ENVIRONMENT == 'development' else 'PostgreSQL (RDS)'}")
    
    if test_connection():
        if ENVIRONMENT == "development":
            create_dev_tables()
        
        tables_info = check_tables()
        logger.info(f"📊 Estado de tablas: {tables_info}")
        return True
    else:
        logger.error("💥 No se pudo conectar a la base de datos")
        return False