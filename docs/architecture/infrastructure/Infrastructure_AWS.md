# Infraestructura AWS CMIPRO
## Especificaciones Técnicas con Explicaciones Detalladas

### 🎯 ¿Qué Configuramos en AWS?

Esta documentación especifica **exactamente qué recursos** crear en Amazon Web Services, **cómo configurarlos**, y **por qué cada configuración es importante** para CMIPRO.

### 🌐 1. NETWORKING: La Base de Todo

#### ¿Qué es una VPC y por qué la necesitamos?
```
🏠 VPC = "Casa Virtual" en AWS
├── 📫 Subredes Públicas (para internet)
├── 🔒 Subredes Privadas (para base de datos)
├── 🚪 Internet Gateway (puerta a internet)
├── 🛡️ Security Groups (reglas de firewall)
└── 📡 Route Tables (direcciones de tráfico)
```

**VPC Configuration Explicada:**
```hcl
resource "aws_vpc" "cmipro_vpc" {
  cidr_block = "10.0.0.0/16"  # Rango de IPs: 10.0.0.1 a 10.0.255.254
  
  # ¿Por qué estas configuraciones?
  enable_dns_hostnames = true  # Permite nombres como "database.internal"
  enable_dns_support   = true  # Permite resolución DNS dentro de VPC
}

# Subredes Públicas - ACCESIBLES DESDE INTERNET
resource "aws_subnet" "public_subnets" {
  count             = 2  # Dos subredes para alta disponibilidad
  cidr_block        = "10.0.${count.index + 1}.0/24"  # 10.0.1.0/24 y 10.0.2.0/24
  availability_zone = ["us-east-1a", "us-east-1b"][count.index]
  
  map_public_ip_on_launch = true  # Auto-asignar IP pública
  
  # ¿Para qué se usan?
  # - Load balancers (si los necesitamos)
  # - NAT gateways (para que privadas accedan internet)
  # - Bastion hosts (para debugging)
}

# Subredes Privadas - NO ACCESIBLES DESDE INTERNET
resource "aws_subnet" "private_subnets" {
  count             = 2  # Dos para redundancia
  cidr_block        = "10.0.${count.index + 10}.0/24"  # 10.0.10.0/24 y 10.0.11.0/24
  availability_zone = ["us-east-1a", "us-east-1b"][count.index]
  
  # ¿Para qué se usan?
  # - Base de datos TimescaleDB (máxima seguridad)
  # - Redis cache (solo acceso interno)
  # - Lambda functions (cuando necesitan VPC)
}
```

**¿Por qué esta estructura?**
- **Seguridad**: Base de datos nunca expuesta a internet
- **Alta Disponibilidad**: Dos zonas = si una falla, otra continúa  
- **Escalabilidad**: Podemos agregar más subredes fácilmente
- **Compliance**: Cumple mejores prácticas AWS

#### Security Groups: El Firewall Inteligente
```hcl
# Security Group para Lambda Functions
resource "aws_security_group" "lambda_sg" {
  name_prefix = "cmipro-lambda-"
  vpc_id      = aws_vpc.cmipro_vpc.id

  # REGLA DE ORO: Deny by default, allow específico
  
  # Solo permite salida (egress) - Lambda puede hacer requests externos
  egress {
    from_port   = 443          # Puerto HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Cualquier destino para APIs externas
    description = "HTTPS saliente para NOAA, Firebase, Stripe"
  }
  
  egress {
    from_port       = 5432     # Puerto PostgreSQL
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]  # Solo a la DB
    description     = "Acceso a TimescaleDB"
  }
  
  # ¿Por qué NO hay reglas de ingress?
  # Lambda NO necesita recibir conexiones directas
  # API Gateway maneja todas las requests externas
}

# Security Group para RDS (Ultra Restrictivo)
resource "aws_security_group" "rds_sg" {
  name_prefix = "cmipro-rds-"
  vpc_id      = aws_vpc.cmipro_vpc.id

  # SOLO permite entrada desde Lambda
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]  # SOLO desde Lambda
    description     = "PostgreSQL SOLO desde funciones autorizadas"
  }
  
  # ¿Por qué tan restrictivo?
  # La base de datos contiene TODOS los datos críticos
  # Un breach aquí = compromiso total del sistema
  # Principio de "least privilege" aplicado estrictamente
}
```

### 💾 2. BASE DE DATOS: TimescaleDB Optimizada

#### ¿Por qué TimescaleDB y no PostgreSQL normal?
```yaml
Datos que almacenamos:
  - Reading de nivel de río cada 5 minutos
  - 3 estaciones × 12 readings/hora × 24 horas = 864 readings/día
  - En 1 año = 315,360 readings
  - En 5 años = 1.5+ millones de readings

PostgreSQL normal:
  ❌ Query "últimas 24 horas" toma 5-10 segundos
  ❌ Almacena datos sin comprimir (mucho espacio)
  ❌ Indexes simples no optimizan por tiempo

TimescaleDB:
  ✅ Misma query toma <500ms (20x más rápida)
  ✅ Compresión automática (90% menos espacio)
  ✅ Particionamiento automático por fecha
  ✅ Funciones especiales: time_bucket(), last(), etc.
```

**Configuración RDS Explicada:**
```hcl
resource "aws_db_instance" "cmipro_timescaledb" {
  identifier = "cmipro-timescaledb"
  
  # Engine Configuration
  engine         = "postgres"
  engine_version = "14.9"  # Última versión estable compatible con TimescaleDB
  
  # Instance Sizing - ¿Por qué estos tamaños?
  instance_class = var.environment == "production" ? "db.t3.small" : "db.t3.micro"
  
  # db.t3.micro (Free Tier):
  # - 1 vCPU, 1 GB RAM
  # - Suficiente para 100-500 usuarios
  # - Burst performance cuando necesita
  
  # db.t3.small (Producción):
  # - 2 vCPU, 2 GB RAM  
  # - Maneja 1000+ usuarios concurrentes
  # - Performance consistente
  
  # Storage Configuration
  allocated_storage     = var.environment == "production" ? 100 : 20  # GB
  max_allocated_storage = 1000  # Auto-scaling hasta 1TB
  storage_type         = "gp2"  # General Purpose SSD (balance costo/performance)
  
  # Database Setup
  db_name  = "cmipro"
  username = var.db_username  # Desde variables de entorno
  password = var.db_password  # Desde Secrets Manager
  
  # Network & Security
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.cmipro_db_subnet_group.name
  
  # Backup Strategy - ¿Por qué estos valores?
  backup_retention_period = 7           # 7 días de backups automáticos
  backup_window          = "03:00-04:00" # 3AM Honduras = menor tráfico
  maintenance_window     = "sun:04:00-sun:05:00"  # Domingo madrugada
  
  # Security & Encryption
  storage_encrypted = true
  kms_key_id       = aws_kms_key.cmipro_key.arn
  
  # Disaster Recovery
  deletion_protection = var.environment == "production"  # Prevenir borrado accidental
  skip_final_snapshot = var.environment != "production"  # Snapshot al eliminar en prod
}

# Parameter Group - Optimizaciones específicas TimescaleDB
resource "aws_db_parameter_group" "cmipro_postgres_params" {
  family = "postgres14"
  
  # Cargar extensión TimescaleDB
  parameter {
    name  = "shared_preload_libraries"
    value = "timescaledb"  # ¡Crítico! Sin esto no funciona TimescaleDB
  }
  
  # Optimizaciones de memoria
  parameter {
    name  = "work_mem"
    value = "32MB"  # Memoria por query (default: 4MB muy poco)
  }
  
  parameter {
    name  = "effective_cache_size"
    value = "1GB"   # Cuánta memoria tiene disponible el sistema
  }
  
  # ¿Por qué estas optimizaciones?
  # TimescaleDB hace queries complejas en datasets grandes
  # Más memoria = menos acceso a disco = queries más rápidas
}
```

#### Redis Cache: La Memoria Rápida del Sistema
```hcl
resource "aws_elasticache_cluster" "cmipro_redis" {
  cluster_id           = "cmipro-redis"
  engine               = "redis"
  engine_version       = "7.0"  # Última versión con mejores features
  node_type           = var.environment == "production" ? "cache.t3.small" : "cache.t3.micro"
  num_cache_nodes     = 1  # Single node suficiente para MVP
  
  # ¿Qué guardamos en Redis?
  # 1. Niveles actuales de río (consulta cada segundo)
  # 2. Respuestas API frecuentes (cache 5 minutos)  
  # 3. Sesiones de usuario (tokens temporales)
  # 4. Rate limiting counters (requests por minuto)
  # 5. Estados de alerta activos
  
  # Configuración de persistencia
  snapshot_retention_limit = 5         # 5 días de snapshots
  snapshot_window         = "03:00-05:00"  # Ventana de backup
  
  # ¿Por qué cache.t3.micro vs cache.t3.small?
  # t3.micro (512MB RAM):
  # - Costo: ~$15/mes
  # - Suficiente para 100-500 usuarios
  # - Cache básico de datos frecuentes
  
  # t3.small (1.37GB RAM):  
  # - Costo: ~$30/mes
  # - Maneja 1000+ usuarios
  # - Cache más extenso, mejor performance
}
```

### ⚡ 3. COMPUTE: Lambda Functions Especializadas

#### ¿Por qué Lambda en vez de servidores tradicionales?
```yaml
Servidor EC2 tradicional:
  Costo: $50-100/mes corriendo 24/7
  Uso real: ~5% del tiempo (picos de tráfico)
  Mantenimiento: Actualizaciones, seguridad, monitoring
  Escalado: Manual y lento
  
Lambda Functions:
  Costo: $0 cuando no se usa, $5-15/mes en uso normal
  Uso: Solo cuando hay requests o triggers
  Mantenimiento: AWS maneja todo
  Escalado: Automático e instantáneo (0 → 1000 concurrent)
```

**FastAPI Lambda - El Cerebro del Sistema:**
```hcl
resource "aws_lambda_function" "cmipro_api" {
  function_name = "cmipro-api"
  runtime      = "python3.11"    # Última versión estable Python
  handler      = "main.handler"   # Función que maneja requests
  
  # Memory & Timeout - ¿Por qué estos valores?
  memory_size = 1024  # MB
  timeout     = 30    # segundos
  
  # ¿Por qué 1024MB memoria?
  # - FastAPI + SQLAlchemy + Pandas = ~300MB base
  # - Queries complejas TimescaleDB = ~200MB adicional  
  # - Buffer para picos de uso = ~500MB
  # - Total recomendado: 1024MB para performance óptima
  
  # ¿Por qué 30 segundos timeout?
  # - Queries normales: 1-3 segundos
  # - Queries complejas (reportes): 5-15 segundos
  # - Buffer para casos extremos: 30 segundos máximo
  # - API Gateway timeout es 29 segundos, así que 30 es límite
  
  # VPC Configuration - ¿Cuándo es necesario?
  vpc_config {
    subnet_ids         = aws_subnet.private_subnets[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  
  # ¿Por qué Lambda en VPC?
  # PRO: Puede acceder RDS en subredes privadas
  # PRO: Máxima seguridad de red
  # CON: Cold start más lento (~3-5 segundos)
  # CON: Necesita NAT Gateway para internet (costo extra)
  
  # Variables de entorno
  environment {
    variables = {
      DATABASE_URL = "postgresql://user:pass@${aws_db_instance.cmipro_timescaledb.endpoint}:5432/cmipro"
      REDIS_URL    = "redis://${aws_elasticache_cluster.cmipro_redis.cache_nodes[0].address}:6379"
      ENVIRONMENT  = var.environment
      LOG_LEVEL    = var.environment == "production" ? "INFO" : "DEBUG"
    }
  }
}
```

**NOAA Poller Lambda - El Monitor Automático:**
```hcl
resource "aws_lambda_function" "noaa_poller" {
  function_name = "cmipro-noaa-poller"
  runtime      = "python3.11"
  handler      = "poller.handler"
  
  # Configuración específica para polling
  memory_size = 512   # Menos memoria (solo procesa JSON)
  timeout     = 300   # 5 minutos máximo (por si NOAA es lento)
  
  # ¿Qué hace esta función?
  # 1. Se ejecuta automáticamente cada 5 minutos
  # 2. Hace HTTP request a NOAA HADS API
  # 3. Parsea datos JSON de estaciones hondureñas
  # 4. Filtra solo CHIH3, SANH3, RCHH3
  # 5. Valida datos (rangos lógicos, timestamps)
  # 6. Inserta en TimescaleDB
  # 7. Actualiza cache Redis
  # 8. Evalúa umbrales de riesgo
  # 9. Trigger alertas si necesario
  
  # EventBridge trigger - El despertador automático
}

# EventBridge Rule - Ejecutar cada 5 minutos
resource "aws_cloudwatch_event_rule" "noaa_poller_schedule" {
  name                = "cmipro-noaa-poller-schedule" 
  description         = "Trigger NOAA poller every 5 minutes"
  schedule_expression = "rate(5 minutes)"
  
  # ¿Por qué cada 5 minutos?
  # - NOAA actualiza datos cada 15 minutos
  # - Polling frecuente asegura detección rápida
  # - 5 minutos = balance entre freshness y costos
  # - En emergencia, 5 minutos puede salvar vidas
}
```

### 🌐 4. API GATEWAY: La Puerta de Entrada

#### ¿Qué hace API Gateway exactamente?
```yaml
Función Principal: Recibir TODAS las requests HTTP y direccionarlas

Request Lifecycle:
  1. Usuario hace: GET https://api.cmiweather.com/stations
  2. API Gateway recibe request
  3. Valida formato y headers
  4. Aplica rate limiting (100 requests/minuto)
  5. Rutea a Lambda function correcta
  6. Lambda procesa y responde
  7. API Gateway formatea respuesta
  8. Envía de vuelta al usuario

Beneficios vs servidor tradicional:
  ✅ Escalabilidad automática (1 → 10,000 RPS)
  ✅ Rate limiting built-in
  ✅ Logging automático de todas las requests
  ✅ CORS configuration centralizada
  ✅ API versioning simple
  ✅ Monitoring integrado con CloudWatch
```

**Configuración API Gateway:**
```hcl
resource "aws_api_gateway_rest_api" "cmipro_api" {
  name        = "cmipro-api"
  description = "CMIPRO Hydrological Monitoring API"
  
  # Regional vs Edge-optimized?
  endpoint_configuration {
    types = ["REGIONAL"]  # Más rápido para usuarios en misma región
  }
  
  # ¿Por qué REGIONAL?
  # - Usuarios principalmente en Honduras/Centroamérica
  # - Menor latencia que Edge-optimized
  # - CloudFront maneja la distribución global
}

# Proxy integration - Todas las rutas van a Lambda
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.cmipro_api.id
  parent_id   = aws_api_gateway_rest_api.cmipro_api.root_resource_id
  path_part   = "{proxy+}"  # Captura cualquier ruta: /api/v1/stations, /health, etc.
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.cmipro_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"  # GET, POST, PUT, DELETE, OPTIONS
  authorization = "NONE" # Lambda maneja la autenticación
}
```

### 📦 5. ALMACENAMIENTO: S3 Buckets Especializados

#### ¿Por qué múltiples buckets y no uno solo?
```yaml
Razones para separación:
  1. Seguridad: Diferentes permisos por bucket
  2. Performance: Optimizaciones específicas por tipo
  3. Costos: Diferentes storage classes
  4. Compliance: Retención diferente por tipo de dato
  5. Backup: Strategies específicas
```

**Bucket Configuration Detallada:**
```hcl
# Frontend Bucket - Hosting del sitio web
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "cmipro-frontend-${var.environment}"
  
  # ¿Qué contiene?
  # - index.html, _next/, static/ (Next.js build)
  # - Imágenes optimizadas (WebP, comprimidas)
  # - CSS/JS minificado
  # - Service worker para offline
}

# Configuración para website hosting
resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "404.html"  # Página personalizada de error
  }
  
  # ¿Por qué static website hosting?
  # - Next.js export genera sitio estático
  # - No necesita servidor Node.js corriendo
  # - CloudFront puede cachear todo eficientemente
  # - Costo mínimo (centavos por mes)
}

# Assets Bucket - Archivos subidos por usuarios
resource "aws_s3_bucket" "assets_bucket" {
  bucket = "cmipro-assets-${var.environment}"
}

# Versioning para assets críticos
resource "aws_s3_bucket_versioning" "assets_versioning" {
  bucket = aws_s3_bucket.assets_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  
  # ¿Por qué versioning?
  # - Recuperar archivos borrados accidentalmente
  # - Mantener historial de cambios en imágenes
  # - Compliance y auditoría
}

# Backups Bucket - Con lifecycle inteligente
resource "aws_s3_bucket" "backups_bucket" {
  bucket = "cmipro-backups-${var.environment}"
}

resource "aws_s3_bucket_lifecycle_configuration" "backups_lifecycle" {
  bucket = aws_s3_bucket.backups_bucket.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    # Optimización de costos automática
    transition {
      days          = 30
      storage_class = "STANDARD_IA"  # Infrequent Access = 50% más barato
    }

    transition {
      days          = 90  
      storage_class = "GLACIER"      # 80% más barato que Standard
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE" # 95% más barato, retrieval 12 horas
    }

    expiration {
      days = 2555  # 7 años (retención legal típica)
    }
  }
  
  # ¿Por qué esta estrategia?
  # Mes 1: $0.023/GB (acceso frecuente)
  # Mes 2-3: $0.0125/GB (acceso ocasional) 
  # Mes 4-12: $0.004/GB (archival)
  # Año 2+: $0.00099/GB (deep archive)
  # Resultado: 90% reducción de costos de almacenamiento
}
```

### 🛡️ 6. SEGURIDAD: WAF + Encryption

#### AWS WAF: El Firewall Inteligente
```hcl
resource "aws_wafv2_web_acl" "cmipro_waf" {
  name  = "cmipro-waf"
  scope = "CLOUDFRONT"  # Protege CloudFront distribution

  default_action {
    allow {}  # Por defecto permitir, bloquear específicamente
  }

  # Rule 1: Rate Limiting - Prevenir abuso
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000    # Requests por 5 minutos
        aggregate_key_type = "IP"    # Por dirección IP
      }
    }
    
    # ¿Por qué 2000 requests/5min?
    # - Usuario normal: ~50 requests/5min
    # - Usuario power: ~200 requests/5min  
    # - Bot legítimo: ~500 requests/5min
    # - Ataque DDoS: >2000 requests/5min
  }

  # Rule 2: OWASP Top 10 Protection
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    
    # ¿Qué bloquea esta regla?
    # - SQL Injection: ' OR 1=1 --
    # - XSS: <script>alert('hack')</script>
    # - Path traversal: ../../etc/passwd
    # - Remote file inclusion: http://evil.com/shell
    # - Command injection: ; rm -rf /
  }

  # Rule 3: Geoblocking - Solo países permitidos
  rule {
    name     = "GeographicRestriction"
    priority = 3
    
    action {
      block {}
    }
    
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["US", "HN", "GT", "SV", "NI", "CR", "PA"]
          }
        }
      }
    }
    
    # ¿Por qué estos países?
    # US: Servicios en la nube, APIs, CDN
    # HN, GT, SV, NI, CR, PA: Usuarios objetivo Centroamérica
    # Bloquea: China, Rusia, otros países con alta actividad maliciosa
  }
}
```

### 💰 7. OPTIMIZACIÓN DE COSTOS

#### Resource Scheduling para Development
```hcl
# Lambda para parar/iniciar recursos en horarios no laborales
resource "aws_lambda_function" "resource_scheduler" {
  count = var.environment == "development" ? 1 : 0
  
  function_name = "cmipro-resource-scheduler"
  runtime      = "python3.11"
  handler      = "scheduler.handler"
  
  # ¿Qué hace?
  # 6PM: Para RDS instance (ahorro: $20/día)
  # 6PM: Flush Redis y para cluster (ahorro: $10/día)  
  # 8AM: Inicia RDS instance
  # 8AM: Inicia Redis cluster
  # Fin de semana: Todo parado
  
  # Ahorro estimado: $600/mes en ambiente dev
}

# EventBridge - Parar recursos 6PM
resource "aws_cloudwatch_event_rule" "stop_resources" {
  count = var.environment == "development" ? 1 : 0
  
  name                = "cmipro-stop-resources"
  description         = "Stop dev resources at 6 PM Central America time"
  schedule_expression = "cron(0 0 * * MON-FRI *)"  # 6PM Honduras = 00:00 UTC+1
}
```

### 📊 8. MONITORING: CloudWatch Alarms Inteligentes

#### ¿Qué monitoreamos y por qué?
```hcl
# Alarm 1: Errores en Lambda API
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "cmipro-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2      # 2 períodos consecutivos
  metric_name         = "Errors"
  period             = 300     # 5 minutos
  statistic          = "Sum"
  threshold          = 10      # Más de 10 errores
  
  # ¿Por qué estos valores?
  # 10 errores en 5 minutos = 2% error rate (si 500 requests)
  # 2 períodos = evitar false alarms por picos temporales
  # Acción: Email inmediato al equipo
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Alarm 2: Latencia alta
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "cmipro-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  period             = 300
  statistic          = "Average"
  threshold          = 5000    # 5 segundos
  
  # ¿Por qué 5 segundos?
  # Objetivo: <2 segundos response time
  # Warning: >5 segundos = experiencia pobre
  # 3 períodos = 15 minutos de latencia alta
  # Acción: Investigar performance issues
}

# Alarm 3: Database connections
resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "cmipro-db-connections"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "DatabaseConnections"
  threshold          = 80      # 80% de max connections
  
  # ¿Por qué monitorear connections?
  # RDS tiene límite de connections (por instance class)
  # Si llega al límite = nuevas requests fallan
  # 80% = tiempo para escalar antes de problemas
}
```

### 🔄 Variables de Configuración

#### ¿Cómo manejar diferentes ambientes?
```hcl
# variables.tf - Configuraciones que cambian por ambiente
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# Configuraciones por ambiente
locals {
  environment_config = {
    development = {
      db_instance_class    = "db.t3.micro"    # $0 Free Tier
      db_allocated_storage = 20               # GB mínimo
      lambda_memory        = 512              # MB suficiente para dev
      redis_node_type      = "cache.t3.micro" # $15/mes
      backup_retention     = 1                # 1 día backup
      monitoring_detailed  = false           # Reducir costos
    }
    
    staging = {
      db_instance_class    = "db.t3.small"    # $25/mes
      db_allocated_storage = 50               # GB intermedio  
      lambda_memory        = 1024             # MB performance testing
      redis_node_type      = "cache.t3.small" # $30/mes
      backup_retention     = 3                # 3 días backup
      monitoring_detailed  = true            # Testing completo
    }
    
    production = {
      db_instance_class    = "db.t3.small"    # $25/mes inicialmente
      db_allocated_storage = 100              # GB con auto-scaling
      lambda_memory        = 1024             # MB performance óptima
      redis_node_type      = "cache.t3.small" # $30/mes
      backup_retention     = 7                # 7 días backup
      monitoring_detailed  = true            # Monitoring completo
      multi_az            = false            # Inicialmente single AZ
    }
  }
}

# ¿Por qué esta estrategia?
# Development: Costo mínimo, funcionalidad básica
# Staging: Replica producción pero más barato  
# Production: Balance performance/costo, escalable
```

### 📋 Outputs: Valores que Necesitamos

```hcl
# outputs.tf - Información que otros sistemas necesitan
output "api_gateway_url" {
  description = "URL base para API calls"
  value       = aws_api_gateway_deployment.cmipro_api_deployment.invoke_url
  
  # Ejemplo: https://abc123.execute-api.us-east-1.amazonaws.com/production
  # Frontend lo usa para: fetch(`${API_URL}/api/v1/stations`)
}

output "cloudfront_distribution_domain" {
  description = "URL del sitio web"  
  value       = aws_cloudfront_distribution.cmipro_distribution.domain_name
  
  # Ejemplo: d1234567890.cloudfront.net
  # DNS CNAME: cmiweather.com → d1234567890.cloudfront.net
}

output "database_endpoint" {
  description = "Conexión a base de datos"
  value       = aws_db_instance.cmipro_timescaledb.endpoint
  sensitive   = true  # No mostrar en logs
  
  # Ejemplo: cmipro-db.abc123.us-east-1.rds.amazonaws.com
  # Lambda lo usa para: postgresql://user:pass@endpoint:5432/cmipro
}
```

### ✅ Validaciones y Checkpoints

#### Pre-Deployment Checklist
```yaml
Infrastructure Validation:
  - [ ] Terraform plan sin errores
  - [ ] Costos estimados dentro de presupuesto
  - [ ] Security groups con acceso mínimo
  - [ ] Backups configurados correctamente
  - [ ] Monitoring alarms activos
  - [ ] Variables de entorno configuradas
  - [ ] Secrets en AWS Secrets Manager

Network Configuration:
  - [ ] VPC con subredes en 2 AZs
  - [ ] RDS en subredes privadas
  - [ ] Lambda con acceso a RDS y Redis
  - [ ] Internet Gateway para acceso externo
  - [ ] Route Tables correctamente configuradas

Security Validation:  
  - [ ] WAF rules testing passed
  - [ ] RDS encryption at rest enabled
  - [ ] S3 buckets con permisos mínimos
  - [ ] KMS keys para encryption
  - [ ] CloudTrail logging enabled

Performance Baseline:
  - [ ] Lambda cold start < 3 segundos
  - [ ] API response time < 2 segundos  
  - [ ] Database query performance acceptable
  - [ ] Redis cache hit ratio > 80%
  - [ ] CloudFront cache hit ratio > 70%
```

Esta infraestructura AWS proporciona la base técnica sólida para CMIPRO, balanceando costo, performance, seguridad y escalabilidad para un sistema crítico de alertas de emergencia.