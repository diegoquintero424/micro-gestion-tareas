# app/domain/services.py
from typing import List, Optional
from app.domain.models import Task
from app.ports.task_repo import ITaskRepository
from uuid import uuid4

class TaskService:
    """
    Representa el Core de la Aplicación.
    Contiene la lógica de negocio y utiliza los Puertos (ITaskRepository)
    para interactuar con el mundo exterior (persistencia de datos).
    """

    def __init__(self, task_repository: ITaskRepository):
        # Inyección de dependencia (Dependency Injection) del Puerto
        self.repo = task_repository

    def create_new_task(self, title: str, description: Optional[str] = None) -> Task:
        """
        Caso de Uso: Crear una nueva tarea.
        Aquí se aplica la lógica de negocio (ej: validación, asignación de ID).
        """
        if not title or len(title.strip()) == 0:
            raise ValueError("El título de la tarea no puede estar vacío.")
        
        # 1. Crear la entidad del dominio
        new_task = Task(
            id=str(uuid4()), # Generamos un ID único en el dominio
            title=title.strip(),
            description=description,
            is_completed=False
        )

        # 2. Persistir a través del Puerto (el Dominio no sabe que es DynamoDB)
        return self.repo.save(new_task)

    def get_all_tasks(self) -> List[Task]:
        """
        Caso de Uso: Obtener todas las tareas.
        """
        # 1. Consulta a través del Puerto
        tasks = self.repo.get_all()
        
        # 2. Se podría aplicar lógica de negocio adicional aquí (ej: filtrado, ordenación)
        return tasks

    def get_task_by_id(self, task_id: str) -> Optional[Task]:
        """
        Caso de Uso: Obtener una tarea específica.
        """
        return self.repo.get_by_id(task_id)

    # Puedes añadir más métodos como update_task, delete_task, mark_as_complete, etc.