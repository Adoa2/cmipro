variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}