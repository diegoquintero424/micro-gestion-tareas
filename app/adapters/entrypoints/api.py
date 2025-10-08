# app/adapters/entrypoints/api.py
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException
from app.domain.models import Task
from app.domain.services import TaskService  # <-- Importar el Servicio
from app.ports.task_repo import ITaskRepository
from app.adapters.secondary.dynamodb_repo import DynamoDBTaskRepository
import os

# Obtén el nombre de la tabla de una variable de entorno
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "TasksTable")

app = FastAPI()

# --- Funciones de Inyección de Dependencia ---

# 1. Proveedor del Adaptador (DynamoDB)
def get_task_repository() -> ITaskRepository:
    """Provee la implementación del puerto de persistencia."""
    return DynamoDBTaskRepository(table_name=DYNAMODB_TABLE_NAME)

# 2. Proveedor del Servicio (Core de la Aplicación)
def get_task_service(repo: ITaskRepository = Depends(get_task_repository)) -> TaskService:
    """Provee el Servicio (Caso de Uso), inyectándole el Repositorio."""
    return TaskService(task_repository=repo)

# --- Endpoints ---

class TaskCreateRequest(Task):
    # Modelo para la creación, omitiendo el ID que se genera en el dominio
    id: Optional[str] = None
    is_completed: bool = False

@app.post("/tasks", response_model=Task)
def create_task_endpoint(task_data: TaskCreateRequest, service: TaskService = Depends(get_task_service)):
    """
    Endpoint para crear una tarea.
    Delega toda la lógica de negocio al TaskService.
    """
    try:
        # Llama al Caso de Uso/Dominio
        new_task = service.create_new_task(
            title=task_data.title,
            description=task_data.description
        )
        return new_task
    except ValueError as e:
        # Manejo de errores de negocio del Dominio
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        # Manejo de errores inesperados de infraestructura/código
        print(f"Error creando tarea: {e}")
        raise HTTPException(status_code=500, detail="Error interno del servidor al guardar la tarea.")


@app.get("/tasks", response_model=list[Task])
def list_tasks_endpoint(service: TaskService = Depends(get_task_service)):
    """
    Endpoint para listar todas las tareas.
    """
    return service.get_all_tasks()

# Nota: El GET por ID debe implementarse también delegando a service.get_task_by_id
# @app.get("/tasks/{task_id}", response_model=Task)
# def get_task_endpoint(task_id: str, service: TaskService = Depends(get_task_service)):
#     # ... (Llamada al servicio)