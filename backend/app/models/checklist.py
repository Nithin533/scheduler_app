from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Date, Boolean, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class EndOfDayChecklist(Base):
    __tablename__ = "end_of_day_checklists"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, nullable=False)

    checklist_date = Column(Date, nullable=False)

    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    items = relationship("ChecklistItem", back_populates="checklist", cascade="all, delete-orphan")


class ChecklistItem(Base):
    __tablename__ = "checklist_items"

    id = Column(Integer, primary_key=True, autoincrement=True)
    checklist_id = Column(Integer, ForeignKey("end_of_day_checklists.id", ondelete="CASCADE"), nullable=False)
    schedule_item_id = Column(Integer, ForeignKey("schedule_items.id", ondelete="SET NULL"))

    title = Column(String(200), nullable=False)
    is_checked = Column(Boolean, default=False)
    checked_at = Column(DateTime)

    checklist = relationship("EndOfDayChecklist", back_populates="items")
