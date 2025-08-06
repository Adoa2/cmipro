# Arquitectura de Seguridad CMIPRO
## Protección Integral Explicada Paso a Paso

### 🎯 ¿Por Qué la Seguridad es CRÍTICA en CMIPRO?

**CMIPRO no es solo una app - es un sistema que puede salvar vidas**

```yaml
Riesgos específicos:
  Desinformación maliciosa:
    - Falsas alertas → pánico innecesario
    - Ocultar alertas reales → muertes evitables
    
  Datos sensibles:
    - 10,000 usuarios con ubicaciones
    - Información de pagos (aunque Stripe lo maneja)
    - Patrones de evacuación predecibles
    
  Disponibilidad crítica:
    - Caída durante emergencia = vidas en riesgo
    - DDoS durante huracán = sistema inútil
    - Performance lenta = evacuaciones tardías
```

### 🛡️ Modelo de Seguridad por Capas (Defense in Depth)

```
🌐 Internet (Atacantes, Bots, Tráfico Normal)
     ↓ Capa 1: EDGE SECURITY
🛡️ CloudFront + WAF + DDoS Protection
     ↓ Capa 2: NETWORK SECURITY  
🔒 VPC + Security Groups + NACLs
     ↓ Capa 3: APPLICATION SECURITY
⚡ API Gateway + Lambda + Input Validation
     ↓ Capa 4: DATA SECURITY
💾 Encryption + Access Control + Audit
     ↓ Capa 5: IDENTITY SECURITY
🔐 Firebase Auth + JWT + MFA
```

### 🌐 CAPA 1: Edge Security (Primera Línea de Defensa)

#### AWS WAF: El Firewall Web Inteligente
```yaml
¿Qué hace WAF exactamente?

Antes de que ANY request llegue a nuestros servidores:
  1. Analiza cada HTTP request
  2. Compara contra reglas de seguridad  
  3. Permite request legítima
  4. Bloquea request maliciosa
  5. Registra todo para análisis

Es como un guardia de seguridad que revisa cada visitante
antes de que entre al edificio.
```

**Reglas WAF Específicas para CMIPRO:**
```hcl
# Rule 1: Rate Limiting - Prevenir abuso
rule {
  name = "RateLimitRule"
  
  statement {
    rate_based_statement {
      limit = 2000                    # Requests por 5 minutos
      aggregate_key_type = "IP"       # Por dirección IP
    }
  }
  
  action { block {} }
}

# ¿Por qué 2000 requests/5min?
# Usuario normal navegando: ~50 requests/5min
# - Cargar página: 10 requests
# - Ver dashboard: 5 requests  
# - Actualizar cada minuto: 5x5 = 25 requests
# - Total: ~50 requests

# Usuario power (admin, desarrollador): ~200 requests/5min
# - Testing funcionalidades: 100 requests
# - Debugging issues: 50 requests  
# - Monitoring checks: 50 requests
# - Total: ~200 requests

# Bot legítimo (Google, Monitoring): ~500 requests/5min
# - Crawling sitio: 200 requests
# - Health checks: 100 requests
# - API monitoring: 200 requests
# - Total: ~500 requests

# Ataque DDoS: >2000 requests/5min
# - Objetivo: Saturar servidor
# - Patrón: Miles de requests por minuto
# - Detección: Excede límite → BLOCK
```

**AWS Shield: Protección DDoS Automática**
```yaml
¿Qué es un ataque DDoS?
  Distributed Denial of Service = múltiples computadoras atacando simultáneamente
  
Ejemplo de ataque típico:
  - 10,000 computadoras infectadas (botnet)
  - Cada una hace 100 requests/segundo
  - Total: 1,000,000 requests/segundo
  - Objetivo: Saturar servidor hasta que se caiga

AWS Shield Standard (GRATIS):
  ✅ Protege contra ataques comunes (SYN flood, UDP flood)
  ✅ Detecta patrones maliciosos automáticamente  
  ✅ Redirige tráfico malicioso a "black holes"
  ✅ Mantiene tráfico legítimo funcionando
  ✅ No requiere configuración

AWS Shield Advanced ($3000/mes):
  ❌ Demasiado caro para MVP
  ❌ Solo necesario para aplicaciones enterprise
  ✅ Considerarlo cuando tengamos >10,000 usuarios
```

**Geo-blocking: Restricción Geográfica**
```hcl
# Permitir solo países específicos
rule {
  name = "GeographicRestriction"
  
  statement {
    geo_match_statement {
      country_codes = ["US", "HN", "GT", "SV", "NI", "CR", "PA"]
    }
  }
  
  action { allow {} }
}

# ¿Por qué estos países específicamente?

# US (Estados Unidos):
# - Servicios AWS hosted desde US
# - APIs de terceros (NOAA, Stripe, Firebase)
# - CDN edge locations
# - Equipo de desarrollo remoto

# HN (Honduras):
# - Usuarios objetivo primario
# - Valle de Sula = área principal de servicio
# - Autoridades locales (COPECO)

# GT, SV, NI, CR, PA (Centroamérica):
# - Usuarios potenciales en región
# - Mismos patrones climáticos  
# - Mercado de expansión natural
# - Comunidades hondureñas en región

# ¿Qué países bloqueamos y por qué?
# China, Rusia: Alto volumen de tráfico malicioso
# Nigeria, Brasil: Fuente común de fraud
# Otros: No hay usuarios legítimos esperados
```

### 🔒 CAPA 2: Network Security (Perímetro Interno)

#### VPC: La Red Privada Virtual
```yaml
¿Qué es una VPC en términos simples?

Imagina tu casa:
  - Jardín frontal = Subred Pública (visitantes pueden llegar)
  - Casa interior = Subred Privada (solo familia tiene acceso)
  - Portón principal = Internet Gateway
  - Cámaras de seguridad = Security Groups
  - Reglas de acceso = NACLs (Network ACLs)

En AWS:
  - VPC = Tu propiedad completa
  - Public Subnet = Zona para Load Balancers, CDN
  - Private Subnet = Base de datos, recursos internos
  - Internet Gateway = Conexión a internet
  - Security Groups = Firewall por recurso
```

**Security Groups: Firewall Granular**
```hcl
# Security Group para Lambda Functions
resource "aws_security_group" "lambda_sg" {
  name        = "cmipro-lambda-sg"
  description = "Firewall rules for Lambda functions"

  # OUTBOUND RULES (qué puede hacer Lambda)
  egress {
    from_port   = 443                    # Puerto HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]         # Cualquier destino en internet
    description = "HTTPS para APIs externas (NOAA, Firebase, Stripe)"
  }
  
  egress {
    from_port       = 5432               # Puerto PostgreSQL
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]  # Solo a nuestra DB
    description     = "Acceso exclusivo a TimescaleDB"
  }
  
  egress {
    from_port       = 6379               # Puerto Redis
    to_port         = 6379  
    protocol        = "tcp"
    security_groups = [aws_security_group.redis_sg.id]  # Solo a nuestro Redis
    description     = "Acceso exclusivo a Redis Cache"
  }

  # INBOUND RULES (qué puede llegar a Lambda)
  # ¡NINGUNA! Lambda NO recibe conexiones directas
  # API Gateway maneja todas las requests externas
}

# ¿Por qué esta configuración?
# Principio de "Least Privilege" = mínimos permisos necesarios
# Lambda solo puede:
# ✅ Hacer requests HTTPS a internet (APIs externas)
# ✅ Conectarse a nuestra base de datos específica
# ✅ Conectarse a nuestro Redis específico
# ❌ Recibir conexiones directas (no necesario)
# ❌ Acceder a otras bases de datos
# ❌ Hacer conexiones HTTP no seguras
```

**Database Security Group: Ultra Restrictivo**
```hcl
# Security Group para RDS TimescaleDB
resource "aws_security_group" "rds_sg" {
  name        = "cmipro-rds-sg"  
  description = "Ultra-restrictive firewall for database"

  # INBOUND RULES (qué puede conectarse a la DB)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]  # SOLO desde Lambda
    description     = "PostgreSQL ÚNICAMENTE desde funciones autorizadas"
  }
  
  # OUTBOUND RULES
  # ¡NINGUNA! La base de datos NO necesita hacer conexiones salientes
  
  # ¿Por qué tan restrictivo?
  # La base de datos es el "tesoro" del sistema:
  # - Todos los datos de usuarios
  # - Todo el histórico de niveles de río  
  # - Configuraciones críticas del sistema
  # - Logs de auditoría
  
  # Un breach en la DB = Game Over
  # Por eso: CERO acceso directo desde internet
  # Por eso: SOLO Lambda autorizada puede conectarse
  # Por eso: NO outbound connections (prevenir data exfiltration)
}
```

### ⚡ CAPA 3: Application Security (Lógica de Negocio)

#### Input Validation: Nunca Confíes en el Usuario
```python
# En FastAPI - Validación estricta de entrada
from pydantic import BaseModel, validator, Field
from typing import Optional
import re

class StationRequest(BaseModel):
    station_id: str = Field(..., regex=r'^[A-Z]{4}H3$')  # Solo formato CHIH3, SANH3
    start_date: Optional[str] = Field(None, regex=r'^\d{4}-\d{2}-\d{2}$')
    end_date: Optional[str] = Field(None, regex=r'^\d{4}-\d{2}-\d{2}$')
    
    @validator('station_id')
    def validate_station(cls, v):
        allowed_stations = ['CHIH3', 'SANH3', 'RCHH3']
        if v not in allowed_stations:
            raise ValueError(f'Station {v} not supported')
        return v
    
    @validator('start_date', 'end_date')  
    def validate_dates(cls, v):
        if v is None:
            return v
            
        # Validar rango de fechas razonable
        from datetime import datetime, timedelta
        try:
            date_obj = datetime.strptime(v, '%Y-%m-%d')
            
            # No fechas futuras
            if date_obj > datetime.now():
                raise ValueError('Future dates not allowed')
                
            # No fechas muy antiguas (>2 años)
            two_years_ago = datetime.now() - timedelta(days=730)
            if date_obj < two_years_ago:
                raise ValueError('Date too old (>2 years)')
                
        except ValueError as e:
            raise ValueError(f'Invalid date format: {e}')
            
        return v

# ¿Por qué validación tan estricta?
# Sin validación:
# ❌ SQL Injection: station_id = "'; DROP TABLE readings; --"
# ❌ Path Traversal: start_date = "../../../etc/passwd" 
# ❌ DoS Attack: end_date = "9999-12-31" (query gigantesco)
# ❌ Data Scraping: requests de 10 años de datos

# Con validación:
# ✅ Solo estaciones válidas aceptadas
# ✅ Solo formatos de fecha correctos
# ✅ Solo rangos de fecha razonables  
# ✅ Previene ataques de injection
```

#### Rate Limiting por Usuario
```python
from collections import defaultdict
import time
import redis
from fastapi import HTTPException, Request

class UserRateLimiter:
    def __init__(self, redis_client):
        self.redis = redis_client
        
    def check_rate_limit(self, user_id: str, endpoint: str) -> bool:
        """
        Implement sliding window rate limiting
        Different limits for different user types
        """
        
        # Define limits by user role and endpoint
        rate_limits = {
            'free_user': {
                '/api/v1/stations': 100,      # requests per hour
                '/api/v1/levels': 50,         # requests per hour  
                '/api/v1/alerts': 20,         # requests per hour
            },
            'premium_user': {
                '/api/v1/stations': 500,      # requests per hour
                '/api/v1/levels': 1000,       # requests per hour
                '/api/v1/alerts': 200,        # requests per hour
            },
            'admin': {
                '/api/v1/stations': 10000,    # requests per hour (unlimited)
                '/api/v1/levels': 10000,      # requests per hour
                '/api/v1/alerts': 10000,      # requests per hour
            }
        }
        
        # Get user role from database/cache
        user_role = self.get_user_role(user_id)
        limit = rate_limits[user_role][endpoint]
        
        # Sliding window implementation
        now = int(time.time())
        window_start = now - 3600  # 1 hour window
        
        # Count requests in current window
        key = f"rate_limit:{user_id}:{endpoint}"
        
        # Remove old entries
        self.redis.zremrangebyscore(key, 0, window_start)
        
        # Count current requests
        current_count = self.redis.zcard(key)
        
        if current_count >= limit:
            return False  # Rate limit exceeded
            
        # Add current request
        self.redis.zadd(key, {str(now): now})
        self.redis.expire(key, 3600)  # Expire after 1 hour
        
        return True  # Request allowed

# ¿Por qué rate limiting por usuario?
# Sin rate limiting:
# ❌ Usuario puede hacer 1000 requests/minuto
# ❌ Saturar base de datos con queries
# ❌ Aumentar costos de AWS dramáticamente
# ❌ Degradar performance para otros usuarios
# ❌ Scraping masivo de datos históricos

# Con rate limiting:
# ✅ Free users: Uso razonable para necesidades normales
# ✅ Premium users: Mayor allowance por pagar
# ✅ Admins: Sin límites para monitoreo/debugging
# ✅ Protege recursos compartidos
# ✅ Mantiene costos controlados
```

### 💾 CAPA 4: Data Security (Protección de Datos)

#### Encryption at Rest: Datos Encriptados Siempre
```yaml
¿Qué significa "Encryption at Rest"?

Datos en reposo = archivos guardados en disco
Sin encryption:
  - Alguien roba el disco duro
  - Puede leer todos los datos directamente
  - Como dejar documentos importantes sin caja fuerte

Con encryption:
  - Disco robado solo contiene datos encriptados
  - Sin la clave = datos inútiles para el atacante
  - Como una caja fuerte: aún robando la caja, no pueden abrirla

En AWS:
  - RDS: storage_encrypted = true
  - S3: server_side_encryption = AES256
  - Lambda: environment variables encrypted with KMS
```

**KMS Key Management:**
```hcl
# Customer Managed Key para máximo control
resource "aws_kms_key" "cmipro_key" {
  description             = "CMIPRO master encryption key"
  deletion_window_in_days = 7     # Periodo de gracia antes de borrado
  enable_key_rotation     = true  # Rotar clave automáticamente cada año
  
  # Key Policy - ¿Quién puede usar esta clave?
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda to decrypt"
        Effect = "Allow" 
        Principal = {
          AWS = aws_iam_role.lambda_execution_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ¿Por qué Customer Managed vs AWS Managed?
# AWS Managed Key (gratis):
# ✅ Sin costo adicional
# ❌ Menos control sobre rotación
# ❌ No auditoría granular de uso
# ❌ Compartida entre servicios

# Customer Managed Key ($1/mes):
# ✅ Control total sobre políticas
# ✅ Auditoría detallada en CloudTrail
# ✅ Rotación automática configurable
# ✅ Isolation completa por aplicación
```

#### Database Encryption Configuration:
```hcl
resource "aws_db_instance" "cmipro_timescaledb" {
  # ... otras configuraciones ...
  
  # Encryption at Rest
  storage_encrypted = true
  kms_key_id       = aws_kms_key.cmipro_key.arn
  
  # Backup Encryption
  backup_retention_period = 7
  copy_tags_to_snapshot  = true  # Tags incluyen encryption config
  
  # Log Encryption  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  # ¿Qué datos se encriptan?
  # 1. Todas las tablas de la base de datos
  # 2. Todos los backups automáticos
  # 3. Todos los snapshots manuales
  # 4. Todos los logs de PostgreSQL
  # 5. Toda la replicación (si activamos Multi-AZ)
  
  # ¿Performance impact?
  # Encryption/Decryption: ~5% CPU overhead
  # Storage space: Sin cambio
  # Query performance: Sin impacto notable
  # Backup/restore: ~10% más lento
}
```

### 🔐 CAPA 5: Identity Security (Quién Es Quién)

#### Firebase Authentication: ¿Por Qué Firebase?
```yaml
Alternativas consideradas:

AWS Cognito:
  ✅ Integración nativa con AWS
  ✅ Precios competitivos
  ❌ UI menos pulida
  ❌ Menos features sociales (Google, Facebook)
  ❌ Documentación más compleja

Auth0:
  ✅ Muy completa
  ✅ Excelente UX
  ❌ Costosa ($23/mes por 1000 MAU)
  ❌ Vendor lock-in fuerte

Firebase Auth:
  ✅ UI/UX excepcional
  ✅ Gratis hasta 50K usuarios
  ✅ Integración fácil con frontend
  ✅ Social login sin configuración extra
  ✅ Documentación excelente
  ❌ Dependencia de Google
```

**JWT Token Validation Pipeline:**
```python
import firebase_admin
from firebase_admin import auth
from fastapi import HTTPException, Depends, Request
import time
import hashlib

class FirebaseAuthenticator:
    def __init__(self):
        # Initialize Firebase with service account
        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": os.getenv("FIREBASE_PROJECT_ID"),
            "private_key": os.getenv("FIREBASE_PRIVATE_KEY").replace('\\n', '\n'),
            "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
        })
        firebase_admin.initialize_app(cred)
        
    async def verify_token(self, authorization: str) -> dict:
        """
        Multi-step token verification process
        """
        # Step 1: Extract token from Authorization header
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
        
        token = authorization.split(" ")[1]
        
        # Step 2: Basic token format validation
        if len(token) < 100:  # JWT tokens are typically >100 chars
            raise HTTPException(status_code=401, detail="Token too short")
        
        try:
            # Step 3: Verify token with Firebase
            decoded_token = auth.verify_id_token(token)
            
            # Step 4: Additional security validations
            self._validate_token_claims(decoded_token)
            
            # Step 5: Check if user still exists and is active
            user_record = auth.get_user(decoded_token['uid'])
            if user_record.disabled:
                raise HTTPException(status_code=401, detail="User account disabled")
            
            # Step 6: Rate limit token verification (prevent abuse)
            self._rate_limit_verification(decoded_token['uid'])
            
            return decoded_token
            
        except firebase_admin.auth.InvalidIdTokenError as e:
            raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")
        except firebase_admin.auth.ExpiredIdTokenError:
            raise HTTPException(status_code=401, detail="Token expired")
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")
    
    def _validate_token_claims(self, token: dict):
        """Additional security validations"""
        
        # Check token age (not older than 1 hour)
        issued_at = token.get('iat', 0)
        if time.time() - issued_at > 3600:
            raise ValueError("Token too old")
        
        # Validate audience
        if token.get('aud') != os.getenv('FIREBASE_PROJECT_ID'):
            raise ValueError("Invalid audience")
        
        # Validate issuer  
        expected_issuer = f"https://securetoken.google.com/{os.getenv('FIREBASE_PROJECT_ID')}"
        if token.get('iss') != expected_issuer:
            raise ValueError("Invalid issuer")
        
        # Check if token was issued in the future (clock skew attack)
        if token.get('iat', 0) > time.time() + 300:  # 5 min tolerance
            raise ValueError("Token issued in future")

# ¿Por qué tanta validación?
# Sin validación extra:
# ❌ Tokens robados funcionan indefinidamente
# ❌ Replay attacks con tokens viejos
# ❌ Tokens falsificados con claims manipulados
# ❌ Accounts deshabilitados siguen accediendo

# Con validación completa:
# ✅ Tokens expiran automáticamente
# ✅ Validación de claims críticos
# ✅ Check de estado de usuario en tiempo real
# ✅ Rate limiting previene abuse
# ✅ Detección de ataques sofisticados
```

### 🔍 Monitoring y Detección de Amenazas

#### Security Event Logging
```python
import structlog
import boto3
from datetime import datetime
import json

# Structured logging para eventos de seguridad
security_logger = structlog.get_logger("security")

class SecurityMonitor:
    def __init__(self):
        self.cloudwatch = boto3.client('cloudwatch')
        self.sns = boto3.client('sns')
        
    def log_security_event(self, event_type: str, user_id: str, details: dict):
        """
        Registrar eventos de seguridad con metadata rica
        """
        event = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type,
            'user_id': user_id,
            'ip_address': details.get('ip_address'),
            'user_agent': details.get('user_agent'),
            'endpoint': details.get('endpoint'),
            'success': details.get('success', False),
            'error_details': details.get('error')
        }
        
        # Log estructurado para análisis
        security_logger.info(
            "Security event",
            event_type=event_type,
            user_id=user_id,
            **details
        )
        
        # Enviar métricas a CloudWatch
        self.cloudwatch.put_metric_data(
            Namespace='CMIPRO/Security',
            MetricData=[{
                'MetricName': f'SecurityEvent_{event_type}',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [
                    {'Name': 'EventType', 'Value': event_type},
                    {'Name': 'Success', 'Value': str(details.get('success', False))}
                ]
            }]
        )
        
        # Alertas automáticas para eventos críticos
        self._check_alert_threshold(event_type, event)
    
    def detect_brute_force_attack(self, user_id: str, ip_address: str) -> bool:
        """
        Detectar intentos de fuerza bruta
        """
        # Contadores Redis para sliding window
        import redis
        r = redis.Redis(host=os.getenv('REDIS_HOST'))
        
        now = int(time.time())
        window = 3600  # 1 hora
        
        # Contar fallos por usuario
        user_key = f"failed_logins:user:{user_id}"
        user_failures = r.zcount(user_key, now - window, now)
        
        # Contar fallos por IP
        ip_key = f"failed_logins:ip:{ip_address}"  
        ip_failures = r.zcount(ip_key, now - window, now)
        
        # Thresholds de detección
        if user_failures >= 5:  # 5 fallos del mismo usuario
            self.log_security_event('BRUTE_FORCE_USER', user_id, {
                'ip_address': ip_address,
                'failure_count': user_failures,
                'window_minutes': 60
            })
            return True
            
        if ip_failures >= 20:  # 20 fallos de la misma IP
            self.log_security_event('BRUTE_FORCE_IP', user_id, {
                'ip_address': ip_address,
                'failure_count': ip_failures,
                'window_minutes': 60
            })
            return True
            
        return False
    
    def detect_data_exfiltration(self, user_id: str, data_size_mb: float) -> bool:
        """
        Detectar posible exfiltración masiva de datos
        """
        import redis
        r = redis.Redis(host=os.getenv('REDIS_HOST'))
        
        # Tracking por usuario por hora
        hour = int(time.time() // 3600)
        key = f"data_usage:user:{user_id}:{hour}"
        
        # Acumular datos descargados
        current_usage = float(r.get(key) or 0)
        total_usage = current_usage + data_size_mb
        
        r.setex(key, 3600, total_usage)  # Expire en 1 hora
        
        # Thresholds por tipo de usuario
        thresholds = {
            'free_user': 50,     # 50MB por hora
            'premium_user': 200,  # 200MB por hora  
            'admin': 1000        # 1GB por hora
        }
        
        user_role = self._get_user_role(user_id)
        threshold = thresholds.get(user_role, 50)
        
        if total_usage > threshold:
            self.log_security_event('EXCESSIVE_DATA_ACCESS', user_id, {
                'usage_mb': total_usage,
                'threshold_mb': threshold,
                'user_role': user_role
            })
            return True
            
        return False

# ¿Por qué monitoreo tan detallado?
# Sistema tradicional:
# ❌ Solo logs básicos de acceso
# ❌ Detección manual de problemas
# ❌ Response lenta a incidentes
# ❌ No correlación de eventos

# Sistema CMIPRO:
# ✅ Logging estructurado de todos los eventos
# ✅ Detección automática de patrones sospechosos
# ✅ Alertas en tiempo real para amenazas
# ✅ Métricas para análisis de tendencias
# ✅ Response automatizada a incidentes
```

### 🚨 Incident Response (Respuesta a Incidentes)

#### Plan de Respuesta Automatizada
```python
class IncidentResponseSystem:
    def __init__(self):
        self.waf_client = boto3.client('wafv2')
        self.sns_client = boto3.client('sns')
        
    def handle_security_incident(self, incident_type: str, severity: str, details: dict):
        """
        Respuesta automática basada en tipo y severidad
        """
        
        response_actions = {
            'LOW': self._low_severity_response,
            'MEDIUM': self._medium_severity_response,  
            'HIGH': self._high_severity_response,
            'CRITICAL': self._critical_severity_response
        }
        
        # Ejecutar respuesta apropiada
        response_func = response_actions.get(severity, self._low_severity_response)
        response_func(incident_type, details)
        
        # Notificar al equipo
        self._send_incident_alert(incident_type, severity, details)
    
    def _critical_severity_response(self, incident_type: str, details: dict):
        """
        Respuesta inmediata para incidentes críticos
        """
        if incident_type == 'MASSIVE_BRUTE_FORCE':
            # Bloquear IPs atacantes automáticamente
            malicious_ips = details.get('ip_addresses', [])
            self._block_ips_in_waf(malicious_ips)
            
        elif incident_type == 'DATA_BREACH_SUSPECTED':
            # Activar modo de solo lectura temporalmente
            self._enable_read_only_mode()
            
        elif incident_type == 'DDOS_ATTACK':
            # Activar modo supervivencia
            self._enable_emergency_mode()
            
        # Log de acción tomada
        security_logger.critical(
            "Critical incident response activated",
            incident_type=incident_type,
            automated_action="immediate_response",
            details=details
        )
    
    def _block_ips_in_waf(self, ip_addresses: list):
        """
        Agregar IPs maliciosas a WAF block list
        """
        try:
            # Obtener IP set actual
            ip_set_response = self.waf_client.get_ip_set(
                Scope='CLOUDFRONT',
                Id='cmipro-blocked-ips',
                Name='CMIPRO-Blocked-IPs'
            )
            
            # Agregar nuevas IPs
            current_ips = set(ip_set_response['IPSet']['Addresses'])
            new_ips = set(f"{ip}/32" for ip in ip_addresses)
            updated_ips = current_ips.union(new_ips)
            
            # Actualizar IP set
            self.waf_client.update_ip_set(
                Scope='CLOUDFRONT',
                Id='cmipro-blocked-ips',
                Addresses=list(updated_ips),
                LockToken=ip_set_response['LockToken']
            )
            
            security_logger.info(
                f"Blocked {len(new_ips)} malicious IPs in WAF",
                blocked_ips=list(new_ips)
            )
            
        except Exception as e:
            security_logger.error(f"Failed to block IPs: {str(e)}")
    
    def _enable_emergency_mode(self):
        """
        Activar modo de emergencia del sistema
        """
        # Reducir rate limits temporalmente
        # Cachear respuestas más agresivamente  
        # Deshabilitar endpoints no críticos
        # Priorizar alertas de emergencia
        
        # Implementar como feature flag
        import redis
        r = redis.Redis(host=os.getenv('REDIS_HOST'))
        r.setex('emergency_mode', 3600, 'true')  # 1 hora
        
        security_logger.warning(
            "Emergency mode activated",
            duration_seconds=3600,
            reason="security_incident_response"
        )

# ¿Por qué respuesta automática?
# Respuesta manual:
# ❌ Requiere persona disponible 24/7
# ❌ Tiempo de respuesta: 5-30 minutos
# ❌ Posible error humano bajo presión
# ❌ Inconsistencia en acciones

# Respuesta automática:
# ✅ Disponible 24/7/365
# ✅ Tiempo de respuesta: <30 segundos
# ✅ Acciones consistentes y probadas
# ✅ Escalamiento automático a humanos
# ✅ Logging detallado de todas las acciones
```

### 📋 Security Compliance Checklist

#### Pre-Production Security Validation
```yaml
Infrastructure Security:
  - [ ] VPC configurada con subredes privadas
  - [ ] Security Groups con reglas mínimas
  - [ ] WAF con reglas OWASP Top 10
  - [ ] DDoS protection habilitado
  - [ ] Geo-blocking configurado para países autorizados

Application Security:
  - [ ] Input validation en todos los endpoints
  - [ ] Rate limiting por usuario implementado
  - [ ] CORS configurado restrictivamente
  - [ ] HTTPS forzado en toda la aplicación
  - [ ] Headers de seguridad configurados

Data Protection:
  - [ ] Encryption at rest para RDS
  - [ ] Encryption at rest para S3
  - [ ] Encryption in transit (TLS 1.2+)
  - [ ] KMS keys con rotation habilitada
  - [ ] Secrets en AWS Secrets Manager

Identity & Access:
  - [ ] Firebase Auth configurado correctamente
  - [ ] JWT token validation implementada
  - [ ] Role-based access control (RBAC)
  - [ ] MFA disponible para usuarios premium
  - [ ] Session timeout configurado

Monitoring & Response:
  - [ ] Security event logging implementado
  - [ ] Automated threat detection activo
  - [ ] Incident response procedures documentadas
  - [ ] Security alerts configuradas
  - [ ] Backup y recovery procedures probadas

Compliance:
  - [ ] GDPR data deletion capability
  - [ ] Data retention policies definidas
  - [ ] Privacy policy actualizada
  - [ ] Terms of service actualizados
  - [ ] Audit logging para compliance
```

### 🔄 Maintenance y Updates

#### Security Maintenance Schedule
```yaml
Daily (Automatizado):
  - Vulnerability scans en dependencias
  - Log analysis para anomalías
  - Backup verification
  - Certificate expiration check

Weekly (Semi-automatizado):
  - Security metrics review
  - Failed login analysis
  - WAF rules effectiveness review
  - Incident response drill (automated)

Monthly (Manual):
  - Dependency updates (con testing)
  - Security configuration audit
  - Access permissions review
  - Penetration testing (basic)

Quarterly (Manual):
  - Full security audit
  - Professional penetration testing
  - Incident response plan update
  - Security awareness training
  - Third-party security assessment
```

Esta arquitectura de seguridad multi-capa proporciona protección robusta para CMIPRO, balanceando seguridad máxima con usabilidad para usuarios en situaciones de emergencia. Cada capa actúa independientemente, creando redundancia que asegura que el sistema permanezca seguro incluso si una capa es comprometida.