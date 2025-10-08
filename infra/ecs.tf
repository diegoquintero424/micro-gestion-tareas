# ----------------------------------------------------
# CLOUDWATCH (Logs)
# ----------------------------------------------------

resource "aws_cloudwatch_log_group" "task_api_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

# ----------------------------------------------------
# ECS FARGATE
# ----------------------------------------------------

# Cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
}

# Definición de la Tarea ECS (blueprint del contenedor)
resource "aws_ecs_task_definition" "task_api" {
  family                   = "${var.project_name}-${var.environment}-task"
  cpu                      = 256  #  512  # 0.5 vCPU
  memory                   = 512  #  1024 # 1 GB RAM
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "task-api-container"
      image     = "${aws_ecr_repository.api_repo.repository_url}:latest"
      cpu       = 256 # 512
      memory    = 512 # 1024
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [
        {
          name  = "DYNAMODB_TABLE_NAME"
          value = aws_dynamodb_table.tasks_table.name # Inyecta el nombre de la tabla
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task_api_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Servicio ECS (mantiene la(s) tarea(s) ejecutándose)
resource "aws_ecs_service" "task_service" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task_api.arn
  desired_count   = 1 # Mantén una tarea ejecutándose
  launch_type     = "FARGATE"

  # Conexión al Load Balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.api_tg.arn
    container_name   = "task-api-container"
    container_port   = 8000
  }

  # Configuración de red para Fargate
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = true # Permite la conexión a Internet para logs, ECR, etc.
  }
}