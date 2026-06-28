from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, Time, Date, Boolean, DateTime, Enum, SmallInteger, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class FixedEvent(Base):
    __tablename__ = "fixed_events"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    title = Column(String(200), nullable=False)
    description = Column(Text)

    day_of_week = Column(SmallInteger, comment="0=Sun .. 6=Sat")
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    start_date = Column(Date)
    end_date = Column(Date)
    is_recurring = Column(Boolean, default=False)
    recurrence_rule = Column(String(255))

    category = Column(Enum("college", "work", "part_time", "appointment", "other", name="event_category"), nullable=False, default="other")
    color = Column(String(7), default="#3788d8")
    is_active = Column(Boolean, default=True)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="fixed_events")
