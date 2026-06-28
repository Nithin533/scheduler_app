from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, Date, Boolean, DateTime, Enum, SmallInteger, DECIMAL, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    title = Column(String(200), nullable=False)
    description = Column(Text)

    priority = Column(SmallInteger, nullable=False, default=3, comment="1=urgent .. 5=can wait")
    estimated_duration_minutes = Column(Integer, nullable=False, default=30)

    category = Column(Enum("hobby", "skill", "fitness", "career", "health", "academic", "chore", "other", name="task_category"), nullable=False, default="other")

    due_date = Column(Date)
    is_completed = Column(Boolean, default=False)
    is_recurring = Column(Boolean, default=False)
    recurrence_rule = Column(String(255))
    is_flexible = Column(Boolean, default=True)
    preferred_time_slot = Column(Enum("morning", "afternoon", "evening", "any", name="time_slot"), default="any")

    min_times_per_week = Column(Integer)

    parent_goal_id = Column(Integer, ForeignKey("tasks.id", ondelete="SET NULL"))
    progress = Column(DECIMAL(5, 2), default=0.00)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="tasks")
