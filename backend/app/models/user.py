from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Time, DECIMAL, JSON, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(100))

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    profile = relationship("UserProfile", uselist=False, back_populates="user", cascade="all, delete-orphan")
    fixed_events = relationship("FixedEvent", back_populates="user", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    habits = relationship("Habit", back_populates="user", cascade="all, delete-orphan")
    schedules = relationship("DailySchedule", back_populates="user", cascade="all, delete-orphan")
    reminders = relationship("Reminder", back_populates="user", cascade="all, delete-orphan")


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)

    age = Column(Integer)
    occupation = Column(String(100))
    work_start_time = Column(Time)
    work_end_time = Column(Time)
    work_days = Column(JSON)
    commute_time_minutes = Column(Integer, default=30)

    sports = Column(JSON)
    hobbies = Column(JSON)
    skills_learning = Column(JSON)
    long_term_goals = Column(JSON)
    fitness_info = Column(JSON)
    diet_tracking = Column(JSON)

    sleep_target_hours = Column(DECIMAL(3, 1), default=8.0)

    has_part_time_job = Column(Boolean, default=False)
    part_time_start = Column(Time)
    part_time_end = Column(Time)
    part_time_days = Column(JSON)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="profile")
