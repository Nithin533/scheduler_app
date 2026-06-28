from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey

from app.database import Base


class GoogleCalendarSync(Base):
    __tablename__ = "google_calendar_sync"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)

    access_token = Column(Text)
    refresh_token = Column(Text)
    token_expiry = Column(DateTime)

    google_calendar_id = Column(String(255), default="primary")
    last_synced_at = Column(DateTime)
    sync_enabled = Column(Boolean, default=True)
