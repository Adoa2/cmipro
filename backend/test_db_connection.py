
# Archivo: backend/test_db_connection.py
# Script para probar conexión a PostgreSQL RDS

import os
import sys
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

# Cargar variables de entorno
env_file = Path(__file__).parent / ".env.local"
load_dotenv(env_file)

def test_direct_connection():
    """Probar conexión directa a PostgreSQL"""
    
    print("🔄 Probando conexión directa a PostgreSQL RDS...")
    
    # Obtener variables de entorno
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        print("❌ Error: DATABASE_URL no configurada en .env.local")
        return False
    
    try:
        # Extraer componentes de la URL
        # Format: postgresql://user:password@host:port/database
        url_parts = database_url.replace("postgresql://", "").split("/")
        db_name = url_parts[1]
        
        user_pass_host = url_parts[0].split("@")
        host_port = user_pass_host[1].split(":")
        host = host_port[0]
        port = int(host_port[1])
        
        user_pass = user_pass_host[0].split(":")
        user = user_pass[0]
        password = user_pass[1]
        
        print(f"📍 Host: {host}:{port}")
        print(f"👤 Usuario: {user}")
        print(f"🗄️ Base de datos: {db_name}")
        
        # Intentar conexión
        connection = psycopg2.connect(
            host=host,
            port=port,
            database=db_name,
            user=user,
            password=password,
            connect_timeout=10
        )
        
        cursor = connection.cursor()
        
        # Probar queries básicas
        print("\n🧪 Ejecutando pruebas...")
        
        # 1. Versión de PostgreSQL
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✅ PostgreSQL: {version.split(',')[0]}")
        
        # 2. Verificar tablas
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        table_names = [table[0] for table in tables]
        print(f"✅ Tablas encontradas: {table_names}")
        
        # 3. Verificar función de riesgo
        try:
            cursor.execute("SELECT calculate_risk_level(5.0, 'CHIH3');")
            risk_result = cursor.fetchone()[0]
            print(f"✅ Función calculate_risk_level: {risk_result}")
        except Exception as e:
            print(f"⚠️ Función calculate_risk_level no disponible: {e}")
        
        # 4. Contar registros en tablas principales
        for table in ["stations", "hydrologic_readings"]:
            if table in table_names:
                cursor.execute(f"SELECT COUNT(*) FROM {table};")
                count = cursor.fetchone()[0]
                print(f"✅ {table}: {count} registros")
        
        cursor.close()
        connection.close()
        
        print("\n🎉 ¡Conexión exitosa a PostgreSQL RDS!")
        return True
        
    except psycopg2.OperationalError as e:
        print(f"❌ Error de conexión: {e}")
        print("\n🔧 Posibles soluciones:")
        print("   1. Verificar que el Security Group permite acceso desde tu IP")
        print("   2. Confirmar que las credenciales en .env.local son correctas")
        print("   3. Verificar conectividad de red")
        return False
        
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False

def test_sqlalchemy_connection():
    """Probar conexión usando SQLAlchemy (como lo hace FastAPI)"""
    
    print("\n🔄 Probando conexión SQLAlchemy...")
    
    try:
        # Importar y probar configuración de FastAPI
        sys.path.insert(0, str(Path(__file__).parent / "app"))
        
        from config.database import test_connection, check_tables
        
        # Probar conexión
        if test_connection():
            print("✅ Conexión SQLAlchemy exitosa")
            
            # Verificar tablas
            tables_info = check_tables()
            print(f"✅ Información de tablas: {tables_info}")
            
            return True
        else:
            print("❌ Error en conexión SQLAlchemy")
            return False
            
    except ImportError as e:
        print(f"⚠️ No se pudo importar módulos FastAPI: {e}")
        print("   Asegúrate de haber instalado todas las dependencias")
        return False
    except Exception as e:
        print(f"❌ Error en SQLAlchemy: {e}")
        return False

def main():
    """Función principal"""
    
    print("🧪 CMIPRO - Prueba de Conexión a Base de Datos")
    print("=" * 60)
    
    # Verificar archivo de entorno
    if not env_file.exists():
        print("❌ Error: archivo .env.local no encontrado")
        print(f"   Crear archivo en: {env_file}")
        return
    
    print(f"✅ Variables de entorno cargadas desde: {env_file}")
    
    # Ejecutar pruebas
    success1 = test_direct_connection()
    success2 = test_sqlalchemy_connection()
    
    print("\n" + "=" * 60)
    if success1 and success2:
        print("🎉 ¡Todas las pruebas exitosas! La base de datos está lista.")
        print("✅ Puedes ejecutar FastAPI con: python run_local.py")
    else:
        print("❌ Algunas pruebas fallaron. Revisar configuración.")
    
    print("=" * 60)

if __name__ == "__main__":
    main()