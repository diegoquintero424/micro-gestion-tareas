from abc import ABC, abstractmethod
from typing import List, Optional
from app.domain.models import Task

class ITaskRepository(ABC):
    @abstractmethod
    def save(self, task: Task) -> Task:
        pass

    @abstractmethod
    def get_all(self) -> List[Task]:
        pass

    @abstractmethod
    def get_by_id(self, task_id: str) -> Optional[Task]:
        pass

    # ... otros métodos