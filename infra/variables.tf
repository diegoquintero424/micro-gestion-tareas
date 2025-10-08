# Define la región de AWS a usar.
variable "aws_region" {
  description = "Región de AWS para el despliegue."
  type        = string
  default     = "us-east-1" # Cámbiala a tu región preferida
}

# Define el prefijo para nombrar todos los recursos.
variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo para los recursos."
  type        = string
  default     = "taskapp"
}

# Define el entorno (útil para etiquetado y gestión de tablas de BD).
variable "environment" {
  description = "Entorno del despliegue (dev, staging, prod)."
  type        = string
  default     = "dev"
}