# Lambda Function para NOAA Polling - CMIPRO
# Versión mínima funcional (sin Layer)

# Datos de la infraestructura existente
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-${var.environment}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# IAM Role para Lambda
resource "aws_iam_role" "noaa_poller_lambda_role" {
  name = "${var.project_name}-${var.environment}-noaa-poller-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-noaa-poller-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Política IAM básica para Lambda
resource "aws_iam_role_policy" "noaa_poller_lambda_policy" {
  name = "${var.project_name}-${var.environment}-noaa-poller-lambda-policy"
  role = aws_iam_role.noaa_poller_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attachment de política VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.noaa_poller_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Crear el ZIP del código Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../../../../backend/lambda/noaa_poller"
  output_path = "noaa_poller.zip"
}

# Security Group para Lambda
resource "aws_security_group" "lambda_sg" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  vpc_id      = data.aws_vpc.main.id

  # Salida HTTPS para APIs externas
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida HTTP para APIs externas
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  }
}

# Lambda Function (SIN dependencias externas por ahora)
resource "aws_lambda_function" "noaa_poller" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-noaa-poller"
  role            = aws_iam_role.noaa_poller_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60   # 1 minuto para testing
  memory_size     = 128  # Mínimo para testing

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Configuración VPC
  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Variables de entorno
  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT_NAME = var.project_name
      LOG_LEVEL = "INFO"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-noaa-poller"
    Environment = var.environment
    Project     = var.project_name
    Function    = "data_ingestion"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-noaa-poller"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-noaa-poller-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Outputs
output "lambda_function_arn" {
  description = "ARN de la función Lambda NOAA Poller"
  value       = aws_lambda_function.noaa_poller.arn
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda NOAA Poller"
  value       = aws_lambda_function.noaa_poller.function_name
}

output "lambda_security_group_id" {
  description = "ID del Security Group de Lambda"
  value       = aws_security_group.lambda_sg.id
}