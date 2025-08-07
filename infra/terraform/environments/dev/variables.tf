variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cmipro"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Umbrales calibrados del Martes Semana 1
variable "alert_thresholds" {
  description = "River level thresholds calibrated for Valle de Sula"
  type = map(object({
    normal    = number
    low       = number
    moderate  = number
    high      = number
    very_high = number
    critical  = number
  }))
  default = {
    CHIH3 = {
      normal    = 2.0
      low       = 4.0
      moderate  = 6.0
      high      = 8.0
      very_high = 12.0
      critical  = 15.0
    }
    SANH3 = {
      normal    = 2.0
      low       = 4.0
      moderate  = 6.0
      high      = 8.0
      very_high = 12.0
      critical  = 15.0
    }
    RCHH3 = {
      normal    = 2.0
      low       = 4.0
      moderate  = 6.0
      high      = 8.0
      very_high = 12.0
      critical  = 15.0
    }
  }
}
# ============================================================================
# VARIABLES RDS POSTGRESQL - Martes Semana 2
# ============================================================================

variable "rds_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_database_name" {
  description = "Nombre de la base de datos principal"
  type        = string
  default     = "cmipro_dev"
}

variable "rds_allocated_storage" {
  description = "Almacenamiento inicial en GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Almacenamiento máximo para auto-scaling en GB"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "Días de retención de backups"
  type        = number
  default     = 7
}

variable "rds_skip_final_snapshot" {
  description = "Omitir snapshot final al eliminar"
  type        = bool
  default     = true
}