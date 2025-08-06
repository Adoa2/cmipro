output "lambda_role_arn" {
  value = aws_iam_role.lambda_execution.arn
}

output "lambda_role_name" {
  value = aws_iam_role.lambda_execution.name
}

output "ecs_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}