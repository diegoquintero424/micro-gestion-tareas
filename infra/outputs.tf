# URL del Application Load Balancer
output "alb_url" {
  description = "La URL del Application Load Balancer para acceder a la API."
  value       = aws_lb.api_alb.dns_name
}

# Nombre del repositorio ECR
output "ecr_repository_url" {
  description = "La URL del repositorio ECR para subir la imagen Docker."
  value       = aws_ecr_repository.api_repo.repository_url
}

# Nombre de la tabla DynamoDB
output "dynamodb_table_name" {
  description = "El nombre de la tabla DynamoDB creada."
  value       = aws_dynamodb_table.tasks_table.name
}