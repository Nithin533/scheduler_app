from datetime import datetime, date
from pydantic import BaseModel
from typing import Optional


class ScheduleItemResponse(BaseModel):
    id: int
    schedule_id: int
    title: str
    start_time: datetime
    end_time: datetime
    duration_minutes: int
    item_type: str
    task_id: Optional[int]
    event_id: Optional[int]
    habit_id: Optional[int]
    status: str
    completed_at: Optional[datetime]
    priority_at_schedule: Optional[int]

    class Config:
        from_attributes = True


class DailyScheduleResponse(BaseModel):
    id: int
    user_id: int
    schedule_date: date
    is_confirmed: bool
    total_free_hours: Optional[float]
    total_scheduled_hours: Optional[float]
    is_balanced: Optional[bool]
    items: list[ScheduleItemResponse] = []

    class Config:
        from_attributes = True
