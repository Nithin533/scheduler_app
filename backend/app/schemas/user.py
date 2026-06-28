from datetime import datetime
from pydantic import BaseModel, EmailStr
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
    has_part_time_job: bool = False
    part_time_start: Optional[str] = None
    part_time_end: Optional[str] = None
    part_time_days: Optional[list[str]] = None


class UserProfileResponse(BaseModel):
    id: int
    user_id: int
    age: Optional[int]
    occupation: Optional[str]
    sleep_target_hours: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
