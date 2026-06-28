from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, Date, Boolean, DateTime, Enum, DECIMAL, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class Habit(Base):
    __tablename__ = "habits"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    name = Column(String(100), nullable=False)
    description = Column(Text)
    unit = Column(String(50))
    target_value = Column(DECIMAL(10, 2))

    frequency = Column(Enum("daily", "weekly", "per_meal", name="habit_frequency"), nullable=False, default="daily")
    icon = Column(String(50))
    is_active = Column(Boolean, default=True)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="habits")
    logs = relationship("HabitLog", back_populates="habit", cascade="all, delete-orphan")


class HabitLog(Base):
    __tablename__ = "habit_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    habit_id = Column(Integer, ForeignKey("habits.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    log_date = Column(Date, nullable=False)
    value = Column(DECIMAL(10, 2))
    notes = Column(Text)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    habit = relationship("Habit", back_populates="logs")

    __table_args__ = (UniqueConstraint("habit_id", "log_date", name="uq_habit_log"),)
