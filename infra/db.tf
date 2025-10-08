# ----------------------------------------------------
# REPOSITORIO DE CONTENEDORES (ECR)
# ----------------------------------------------------

resource "aws_ecr_repository" "api_repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "${var.project_name}-${var.environment}-repo"
  }
}

# ----------------------------------------------------
# BASE DE DATOS (DYNAMODB)
# ----------------------------------------------------

resource "aws_dynamodb_table" "tasks_table" {
  name         = "${var.project_name}TasksTable-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Serverless y de fácil configuración
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}

# Nota: El permiso de acceso a esta tabla se define en 'main.tf' (task_dynamodb_attachment)