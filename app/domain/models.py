from pydantic import BaseModel
from typing import Optional

class Task(BaseModel):
    id: Optional[str] = None
    title: str
    description: Optional[str] = None
    is_completed: bool = False