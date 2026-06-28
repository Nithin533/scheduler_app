from datetime import datetime, date
from pydantic import BaseModel
from typing import Optional


class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    priority: int = 3
    estimated_duration_minutes: int = 30
    category: str = "other"
    due_date: Optional[str] = None
    is_recurring: bool = False
    recurrence_rule: Optional[str] = None
    is_flexible: bool = True
    preferred_time_slot: str = "any"
    min_times_per_week: Optional[int] = None
    parent_goal_id: Optional[int] = None


class TaskResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str]
    priority: int
    estimated_duration_minutes: int
    category: str
    due_date: Optional[date]
    is_completed: bool
    is_flexible: bool
    preferred_time_slot: str
    min_times_per_week: Optional[int]
    progress: float
    created_at: datetime

    class Config:
        from_attributes = True
