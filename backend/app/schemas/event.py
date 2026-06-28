from datetime import time, date
from pydantic import BaseModel
from typing import Optional


class FixedEventCreate(BaseModel):
    title: str
    description: Optional[str] = None
    day_of_week: Optional[int] = None
    start_time: str
    end_time: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_recurring: bool = False
    recurrence_rule: Optional[str] = None
    category: str = "other"
    color: str = "#3788d8"


class FixedEventResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str]
    day_of_week: Optional[int]
    start_time: time
    end_time: time
    is_recurring: bool
    category: str
    color: Optional[str]

    class Config:
        from_attributes = True
