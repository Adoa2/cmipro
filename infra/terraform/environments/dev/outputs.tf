output "vpc_id" {
  value       = module.networking.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = module.networking.public_subnet_ids
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value       = module.networking.private_subnet_ids
  description = "IDs of private subnets"
}

output "database_subnet_ids" {
  value       = module.networking.database_subnet_ids
  description = "IDs of database subnets"
}

output "lambda_role_arn" {
  value       = module.security.lambda_role_arn
  description = "ARN of Lambda execution role"
}

output "s3_buckets" {
  value = {
    frontend = module.storage.frontend_bucket_name
    logs     = module.storage.logs_bucket_name
    backups  = module.storage.backups_bucket_name
  }
  description = "S3 bucket names"
}

output "security_groups" {
  value = {
    alb    = module.security.alb_sg_id
    lambda = module.security.lambda_sg_id
    rds    = module.security.rds_sg_id
    redis  = module.security.redis_sg_id
  }
  description = "Security group IDs"
}

output "nat_gateway_ids" {
  value       = module.networking.nat_gateway_ids
  description = "NAT Gateway IDs"
}

output "internet_gateway_id" {
  value       = module.networking.internet_gateway_id
  description = "Internet Gateway ID"
}

# ============================================================================
# OUTPUTS RDS POSTGRESQL - Martes Semana 2
# ============================================================================

output "rds_endpoint" {
  description = "Endpoint de conexión a PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "Puerto de PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.postgres.db_name
}

output "psql_command" {
  description = "Comando psql para conexión"
  value       = "psql -h ${aws_db_instance.postgres.endpoint} -p ${aws_db_instance.postgres.port} -U ${aws_db_instance.postgres.username} -d ${aws_db_instance.postgres.db_name}"
  sensitive   = true
}