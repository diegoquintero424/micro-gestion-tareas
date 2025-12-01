# ----------------------------------------------------
# RED (VPC, SUBREDES, INTERNET GATEWAY)
# ----------------------------------------------------

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Subredes Públicas (para ALB)
resource "aws_subnet" "public" {
  count                   = 2 # Crea dos subredes en diferentes AZs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Necesario para NAT Gateway (en un proyecto real) / ALB

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Obtener las zonas de disponibilidad
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway para la VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Tabla de ruteo para Subredes Públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------
# LOAD BALANCER (ALB)
# ----------------------------------------------------

# Security Group para el ALB (Permite tráfico HTTP/80 desde cualquier lugar)
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-${var.environment}-alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "api_alb" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

# Target Group (donde se registran las tareas ECS)
resource "aws_lb_target_group" "api_tg" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 8000 # El puerto que expone el contenedor
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Necesario para Fargate

  health_check {
    path                = "/tasks"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener del ALB (escucha en el puerto 80 y reenvía al Target Group)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

# Security Group para las Tareas ECS Fargate
resource "aws_security_group" "fargate_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-${var.environment}-fargate-sg"

  # INGRESS: Solo permite tráfico desde el ALB en el puerto del contenedor (8000)
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # EGRESS: Permite todo el tráfico saliente (necesario para DynamoDB y logs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}