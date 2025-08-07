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