import boto3
from typing import List, Optional
from app.ports.task_repo import ITaskRepository
from app.domain.models import Task
import uuid
import os

class DynamoDBTaskRepository(ITaskRepository):
    def __init__(self, table_name: str):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(table_name)

    def save(self, task: Task) -> Task:
        if not task.id:
            task.id = str(uuid.uuid4())
        
        self.table.put_item(Item=task.model_dump())
        return task

    def get_all(self) -> List[Task]:
        response = self.table.scan()
        return [Task(**item) for item in response.get('Items', [])]
    
    def get_by_id(self, task_id: str) -> Optional[Task]:
        response = self.table.get_item(Key={'id': task_id})
        item = response.get('Item')
        return Task(**item) if item else None