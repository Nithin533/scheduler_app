from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.reminder import Reminder
from app.middleware.auth import get_current_user

router = APIRouter()


@router.get("/")
async def list_reminders(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Reminder)
        .where(Reminder.user_id == user.id, Reminder.is_sent == False)
        .order_by(Reminder.reminder_time)
    )
    return result.scalars().all()
