from datetime import datetime, timezone
from sqlalchemy import Column, Integer, DateTime, Boolean, ForeignKey, Enum
from sqlalchemy.orm import relationship

from app.database import Base


class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    schedule_item_id = Column(Integer, ForeignKey("schedule_items.id", ondelete="CASCADE"))

    reminder_time = Column(DateTime(timezone=True), nullable=False)
    is_sent = Column(Boolean, default=False)
    sent_at = Column(DateTime(timezone=True))

    type = Column(Enum(
        "pre_task", "bedtime", "habit", "daily_review", "wake_up",
        name="reminder_type"
    ), nullable=False, default="pre_task")

    user = relationship("User", back_populates="reminders")
