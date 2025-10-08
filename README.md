# 1. Construye la imagen localmente
podman build -t task-api:latest .

# 2. Ejecuta un contenedor (usando DynamoDB Local si quieres, o solo prueba la API)
podman run -p 8000:8000 task-api:latest




-----> Comandos ejecutados para completar la ejecución de código

alb_url = "taskapp-dev-alb-521408575.us-east-1.elb.amazonaws.com"
dynamodb_table_name = "taskappTasksTable-dev"
ecr_repository_url = "165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo"

---- 2. Autentica Docker con ECR: Usa AWS CLI para autenticar tu Docker local:
---- aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo
aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo

--- 3. Etiqueta la imagen: Etiqueta tu imagen Docker con la URL de ECR:
--- docker tag task-api:latest <ecr-registry-url>/task-api-repo:latest
podman tag task-api:latest 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo:latest
(Malo)podman tag task-api:latest 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo/task-api-repo:latest

--- 4. Sube la imagen a ECR:
--- docker push 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo/task-api-repo:latest
podman push 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo:latest
(MALO)podman push 165473157627.dkr.ecr.us-east-1.amazonaws.com/taskapp-repo/task-api-repo:latest







1. Aplicación Python (Arquitectura Hexagonal)
Usaremos Python con FastAPI (o Flask, si prefieres) para el servidor web y el patrón hexagonal.

.
├── app/
│   ├── domain/           # Núcleo de la aplicación (Lógica de Negocio)
│   │   ├── models.py     # Entidades (Task)
│   │   └── services.py   # Casos de uso (CreateTask, GetTask, etc.)
│   ├── ports/            # Interfaces de los Adaptadores (Puertos)
│   │   └── task_repo.py  # Interfaz: ITareaRepository
│   └── adapters/         # Implementaciones de las interfaces (Adaptadores)
│       ├── entrypoints/  # Adaptador Primario (API HTTP)
│       │   └── api.py    # Rutas de FastAPI/Flask
│       └── secondary/    # Adaptadores Secundarios (Infraestructura)
│           └── dynamodb_repo.py # Implementa ITareaRepository con DynamoDB
├── Dockerfile            # Define la imagen del contenedor
└── requirements.txt      # Dependencias de Python


2. Infraestructura como Código (Terraform)
Terraform se encargará de crear todos los recursos necesarios en AWS.

.
└── infra/
    ├── main.tf         # Definición principal de recursos
    ├── variables.tf    # Variables de entrada (ej: region, nombre_proyecto)
    ├── outputs.tf      # Salidas (ej: URL del Load Balancer)
    └── ecs.tf          # Definición del Cluster, Task Definition y Service
    └── network.tf      # Definición de VPC, Subnets y Load Balancer
    └── db.tf           # Definición de DynamoDB y ECR


🚀 Pasos para Implementar y Hacer Funcionar
Sigue estos pasos para construir e implementar el proyecto:

Paso 1: Configuración Local
Instala los requisitos: Asegúrate de tener Python 3.11+, Docker, Terraform y AWS CLI configurados.

Estructura de Carpetas: Crea la estructura de carpetas (app/, infra/, Dockerfile, requirements.txt).

Credenciales de AWS: Configura tu AWS CLI para que Terraform pueda interactuar con tu cuenta (aws configure).

Paso 2: Desarrollo de la Aplicación (Python y Docker)
Escribe el código Python: Completa el código en la carpeta app/ siguiendo el patrón hexagonal.

Define el Dockerfile: Crea el archivo para contenerizar tu aplicación.

Prueba localmente (Opcional pero recomendado):

Bash

# 1. Construye la imagen localmente
docker build -t task-api:latest .

# 2. Ejecuta un contenedor (usando DynamoDB Local si quieres, o solo prueba la API)
docker run -p 8000:8000 task-api:latest

Paso 3: Provisión de Infraestructura (Terraform)
Crea archivos .tf: Completa los archivos .tf en infra/ para definir la VPC, el Cluster ECS Fargate, el ECR, la tabla DynamoDB y el ALB.

Inicializa Terraform:

Bash

cd infra
terraform init
Planifica y Aplica:

Bash

terraform plan
terraform apply --auto-approve 
Esto creará todos los recursos AWS, incluyendo el repositorio ECR.

Paso 4: Construir y Desplegar el Contenedor
Obtén la URL de ECR: El comando terraform apply debería haber generado la URL de tu repositorio ECR (o puedes obtenerla desde la consola/outputs de Terraform).

Autentica Docker con ECR: Usa AWS CLI para autenticar tu Docker local:

Bash

aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <ecr-registry-url>
(Reemplaza <your-region> y <ecr-registry-url>).

Etiqueta la imagen: Etiqueta tu imagen Docker con la URL de ECR:

Bash

docker tag task-api:latest <ecr-registry-url>/task-api-repo:latest
Sube la imagen a ECR:

Bash

docker push <ecr-registry-url>/task-api-repo:latest
Paso 5: Despliegue en ECS y Prueba
Actualiza ECS Service: Dado que la imagen en ECR ha sido actualizada, necesitas forzar un nuevo despliegue del servicio ECS. Terraform puede hacer esto si la Task Definition usa el tag :latest, o puedes usar la AWS CLI/Consola para actualizar el servicio ECS Fargate y forzar una nueva implementación con la última imagen.

Obtén la URL de la API: Una vez que el servicio esté corriendo (tardará unos minutos), obtén la URL del Application Load Balancer (ALB) de las salidas de Terraform (terraform output) o de la consola de AWS.

Prueba la API: Usa curl o Postman para interactuar con tu API a través de la URL del ALB:

Bash

# Ejemplo: Crear una nueva tarea
curl -X POST -H "Content-Type: application/json" -d '{"title": "Aprender ECS", "description": "Implementar el proyecto TO-DO"}' <ALB-URL>/tasks

# Ejemplo: Obtener todas las tareas
curl -X GET <ALB-URL>/tasks
Este proyecto no solo te enseñará a configurar un entorno ECS con Terraform, sino que te obligará a pensar en la separación de responsabilidades y la inyección de dependencias, conceptos clave de la Arquitectura Hexagonal. ¡Mucha suerte! 🧑‍💻✨