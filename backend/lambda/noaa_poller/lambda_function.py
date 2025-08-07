"""
Lambda Function para NOAA Polling - CMIPRO
Version limpia sin dependencias externas ni emojis
"""

import json
import logging
import urllib.request
import urllib.parse
from datetime import datetime

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Handler principal de Lambda - Version funcional sin dependencias"""
    start_time = datetime.utcnow()
    logger.info("CMIPRO NOAA Poller Lambda iniciado")
    
    try:
        # Test de conectividad a NOAA (usando urllib built-in)
        logger.info("Testing conectividad a NOAA HADS...")
        
        # URL de prueba NOAA
        test_url = "https://hads.ncep.noaa.gov/nexhads2/servlet/DecodedData"
        params = {
            'sinceday': -1,
            'hsa': 'nil', 
            'state': 'HN',
            'nesdis_ids': 'nil',
            'of': '3'
        }
        
        # Construir URL con parametros
        url_params = urllib.parse.urlencode(params)
        full_url = f"{test_url}?{url_params}"
        
        logger.info(f"Conectando a: {full_url[:100]}...")
        
        # Hacer request usando urllib (built-in)
        req = urllib.request.Request(full_url)
        req.add_header('User-Agent', 'CMIPRO/1.0 (Honduras Flood Monitoring)')
        
        with urllib.request.urlopen(req, timeout=30) as response:
            data = response.read().decode('utf-8')
            data_length = len(data)
            
        logger.info(f"Respuesta NOAA recibida: {data_length} caracteres")
        
        # Buscar estaciones de Honduras en los datos
        target_stations = ['CHIH3', 'SANH3', 'RCHH3']
        stations_found = []
        
        for station in target_stations:
            if station in data:
                stations_found.append(station)
                logger.info(f"Estacion encontrada: {station}")
        
        # Test basico de parsing
        lines = data.strip().split('\n')
        honduras_lines = [line for line in lines if any(station in line for station in target_stations)]
        
        logger.info(f"Lineas totales: {len(lines)} | Honduras: {len(honduras_lines)}")
        
        # Simular conexion futura a RDS (preparado para manana)
        logger.info("Preparado para conectar a PostgreSQL RDS")
        logger.info("Preparado para insertar datos en hydrologic_readings")
        logger.info("Preparado para evaluar alertas de riesgo")
        
        # Resultado exitoso
        end_time = datetime.utcnow()
        execution_time = (end_time - start_time).total_seconds()
        
        result = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'CMIPRO NOAA connectivity test successful',
                'timestamp': start_time.isoformat(),
                'execution_time_seconds': execution_time,
                'noaa_data_length': data_length,
                'total_lines': len(lines),
                'honduras_lines': len(honduras_lines),
                'stations_found': stations_found,
                'next_steps': [
                    'Add psycopg2 for RDS connection',
                    'Implement data parsing logic', 
                    'Add risk evaluation',
                    'Configure 5-minute trigger'
                ],
                'infrastructure_status': {
                    'lambda': 'working',
                    'vpc': 'connected', 
                    'nat_gateway': 'functional',
                    'internet_access': 'confirmed',
                    'cloudwatch_logs': 'enabled'
                }
            })
        }
        
        logger.info("Test NOAA completado exitosamente")
        logger.info(f"Estaciones encontradas: {', '.join(stations_found)}")
        return result
        
    except urllib.error.URLError as e:
        logger.error(f"Error de conectividad NOAA: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'NOAA connectivity error: {str(e)}',
                'timestamp': start_time.isoformat(),
                'error_type': 'URLError'
            })
        }
    except Exception as e:
        logger.error(f"Error general en Lambda: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'timestamp': start_time.isoformat(),
                'error_type': 'GeneralError'
            })
        }