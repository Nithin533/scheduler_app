from datetime import datetime, time as time_type
from pydantic import BaseModel, EmailStr, field_serializer
from typing import Optional, Any


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    name: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class UserProfileCreate(BaseModel):
    age: Optional[int] = None
    occupation: Optional[str] = None
    work_start_time: Optional[str] = None
    work_end_time: Optional[str] = None
    work_days: Optional[list[str]] = None
    commute_time_minutes: int = 30
    sports: Optional[list[Any]] = None
    hobbies: Optional[list[Any]] = None
    skills_learning: Optional[list[Any]] = None
    long_term_goals: Optional[list[Any]] = None
    fitness_info: Optional[dict] = None
    diet_tracking: Optional[list[Any]] = None
    sleep_target_hours: float = 8.0
    bedtime: Optional[str] = None
    wake_time: Optional[str] = None
    has_part_time_job: bool = False
    part_time_start: Optional[str] = None
    part_time_end: Optional[str] = None
    part_time_days: Optional[list[str]] = None


class UserProfileResponse(BaseModel):
    id: int
    user_id: int
    age: Optional[int]
    occupation: Optional[str]
    work_start_time: Optional[Any] = None
    work_end_time: Optional[Any] = None
    has_part_time_job: bool = False
    part_time_start: Optional[Any] = None
    part_time_end: Optional[Any] = None
    sleep_target_hours: float
    bedtime: Optional[Any] = None
    wake_time: Optional[Any] = None
    created_at: datetime
    updated_at: datetime

    @field_serializer(
        "work_start_time", "work_end_time",
        "part_time_start", "part_time_end",
        "bedtime", "wake_time",
    )
    def _serialize_time(self, value):
        if value is None:
            return None
        if isinstance(value, time_type):
            return value.strftime("%H:%M")
        return value

    class Config:
        from_attributes = True