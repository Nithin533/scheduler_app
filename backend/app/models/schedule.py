from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Date, Boolean, Enum, SmallInteger, DECIMAL, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class DailySchedule(Base):
    __tablename__ = "daily_schedules"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    schedule_date = Column(Date, nullable=False)

    is_confirmed = Column(Boolean, default=False)
    total_free_hours = Column(DECIMAL(4, 1))
    total_scheduled_hours = Column(DECIMAL(4, 1))
    is_balanced = Column(Boolean, comment="health check passed")

    generated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="schedules")
    items = relationship("ScheduleItem", back_populates="schedule", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("user_id", "schedule_date", name="uq_daily_schedule"),)


class ScheduleItem(Base):
    __tablename__ = "schedule_items"

    id = Column(Integer, primary_key=True, autoincrement=True)
    schedule_id = Column(Integer, ForeignKey("daily_schedules.id", ondelete="CASCADE"), nullable=False)

    title = Column(String(200), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, nullable=False)

    item_type = Column(Enum(
        "fixed_event", "task", "habit", "break", "meal",
        "travel", "sleep", "bath", "free", "gym",
        name="item_type"
    ), nullable=False)

    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="SET NULL"))
    event_id = Column(Integer, ForeignKey("fixed_events.id", ondelete="SET NULL"))
    habit_id = Column(Integer, ForeignKey("habits.id", ondelete="SET NULL"))

    status = Column(Enum("scheduled", "completed", "missed", "rescheduled", name="item_status"), nullable=False, default="scheduled")
    completed_at = Column(DateTime)
    priority_at_schedule = Column(SmallInteger)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    schedule = relationship("DailySchedule", back_populates="items")
    rescheduled_records = relationship("RescheduledItem", back_populates="schedule_item", cascade="all, delete-orphan")


class RescheduledItem(Base):
    __tablename__ = "rescheduled_items"

    id = Column(Integer, primary_key=True, autoincrement=True)
    schedule_item_id = Column(Integer, ForeignKey("schedule_items.id", ondelete="CASCADE"), nullable=False)

    original_date = Column(Date, nullable=False)
    rescheduled_to_date = Column(Date, nullable=False)

    reason = Column(Enum("not_completed", "conflict", "user_request", name="reschedule_reason"), nullable=False, default="not_completed")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    schedule_item = relationship("ScheduleItem", back_populates="rescheduled_records")
