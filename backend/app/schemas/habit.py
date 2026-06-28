from datetime import datetime, date
from pydantic import BaseModel
from typing import Optional


class HabitCreate(BaseModel):
    name: str
    description: Optional[str] = None
    unit: Optional[str] = None
    target_value: Optional[float] = None
    frequency: str = "daily"
    icon: Optional[str] = None


class HabitResponse(BaseModel):
    id: int
    user_id: int
    name: str
    description: Optional[str]
    unit: Optional[str]
    target_value: Optional[float]
    frequency: str
    icon: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class HabitLogCreate(BaseModel):
    habit_id: int
    log_date: str
    value: Optional[float] = None
    notes: Optional[str] = None


class HabitLogResponse(BaseModel):
    id: int
    habit_id: int
    log_date: date
    value: Optional[float]
    notes: Optional[str]

    class Config:
        from_attributes = True
