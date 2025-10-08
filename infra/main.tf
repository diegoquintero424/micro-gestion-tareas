# Configuración del proveedor AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ----------------------------------------------------
# ROLES IAM PARA ECS FARGATE
# ----------------------------------------------------

# Rol de Ejecución de Tareas (para Fargate)
# Permite que ECS extraiga imágenes de ECR y escriba logs en CloudWatch.
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Rol de Tarea (para la Aplicación)
# Permite que la aplicación acceda a otros servicios de AWS (como DynamoDB).
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Política que permite al contenedor interactuar con DynamoDB (CRUD).
resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "${var.project_name}-${var.environment}-DynamoDBAccess"
  description = "Permite acceso de lectura/escritura a la tabla TaskApp."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.tasks_table.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_dynamodb_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}