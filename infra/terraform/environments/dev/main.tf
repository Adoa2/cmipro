terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "cmipro-dev"
  default_tags {
    tags = {
      Project     = "CMIPRO"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Adolfo Angel"
      CostCenter  = "CMI-Weather"
    }
  }
}

# Módulo de Networking
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  aws_region         = var.aws_region
}

# Módulo de Seguridad
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  aws_region   = var.aws_region
}

# Módulo de Storage
module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  environment  = var.environment
  #aws_region   = var.aws_region
}

# ============================================================================
# CONFIGURACIÓN RDS POSTGRESQL - Martes Semana 2
# ============================================================================

# Secrets Manager para credenciales RDS
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project_name}-${var.environment}-rds-credentials"
  description             = "Credenciales de la base de datos RDS PostgreSQL"
  recovery_window_in_days = 0 # Para desarrollo, en producción usar 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-credentials"
    Project     = var.project_name
    Environment = var.environment
    Type        = "Database"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "cmipro_admin"
    password = "TempPassword123!" # Cambiar en producción
  })
}

# Parameter Group - PostgreSQL optimizado para series temporales
resource "aws_db_parameter_group" "postgres_params" {
  family = "postgres16"
  name   = "${var.project_name}-${var.environment}-postgres-params"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"  # Requiere reinicio
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-params"
    Project     = var.project_name
    Environment = var.environment
    Type        = "Database"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  # Identificación
  identifier = "${var.project_name}-${var.environment}-postgres"

  # Engine
  engine         = "postgres"
  engine_version = "16.4" # Versión estable actual
  instance_class = var.rds_instance_class

  # Credenciales
  db_name  = var.rds_database_name
  username = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["password"]

  # Storage
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp2" # General Purpose SSD
  storage_encrypted     = true

  # Networking
  db_subnet_group_name   = module.networking.db_subnet_group_name
  vpc_security_group_ids = [module.security.rds_sg_id]
  publicly_accessible    = true # Solo acceso desde Lambda/VPC

  # Configuración
  parameter_group_name = aws_db_parameter_group.postgres_params.name

  # Backups (Free Tier)
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"         # UTC (11PM-12AM Honduras)
  maintenance_window      = "sun:04:00-sun:05:00" # UTC (12AM-1AM Sunday Honduras)

  # Opciones de desarrollo
  skip_final_snapshot = var.rds_skip_final_snapshot
  deletion_protection = false # Para desarrollo

  # Monitoring
  monitoring_interval             = 0 # Desactivado en Free Tier
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Performance Insights (Free Tier)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7 # Días (Free Tier)

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Project     = var.project_name
    Environment = var.environment
    Type        = "Database"
    Backup      = "enabled"
    CostCenter  = "CMI-Weather"
  }

  # Prevenir cambios accidentales
  lifecycle {
    prevent_destroy = false # Para desarrollo
  }
}