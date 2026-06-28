from datetime import datetime, date
from pydantic import BaseModel
from typing import Optional


class ChecklistItemUpdate(BaseModel):
    is_checked: bool


class ChecklistItemResponse(BaseModel):
    id: int
    checklist_id: int
    schedule_item_id: Optional[int]
    title: str
    is_checked: bool
    checked_at: Optional[datetime]

    class Config:
        from_attributes = True


class CheckListResponse(BaseModel):
    id: int
    user_id: int
    checklist_date: date
    is_completed: bool
    completed_at: Optional[datetime]
    items: list[ChecklistItemResponse] = []

    class Config:
        from_attributes = True
