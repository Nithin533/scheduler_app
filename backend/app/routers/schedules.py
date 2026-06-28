from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.user import User
from app.models.schedule import DailySchedule
from app.schemas.schedule import DailyScheduleResponse
from app.middleware.auth import get_current_user
from app.services.scheduler import SchedulerService

router = APIRouter()


@router.get("/today", response_model=DailyScheduleResponse)
async def get_today_schedule(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    result = await db.execute(
        select(DailySchedule)
        .where(DailySchedule.user_id == user.id, DailySchedule.schedule_date == today)
        .options(selectinload(DailySchedule.items))
    )
    schedule = result.scalar_one_or_none()

    if not schedule:
        scheduler = SchedulerService(db)
        schedule = await scheduler.generate_daily_schedule(user, today)

    return schedule


@router.get("/{schedule_date}", response_model=DailyScheduleResponse)
async def get_schedule(
    schedule_date: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = date.fromisoformat(schedule_date)
    result = await db.execute(
        select(DailySchedule)
        .where(DailySchedule.user_id == user.id, DailySchedule.schedule_date == target_date)
        .options(selectinload(DailySchedule.items))
    )
    schedule = result.scalar_one_or_none()

    if not schedule:
        scheduler = SchedulerService(db)
        schedule = await scheduler.generate_daily_schedule(user, target_date)

    return schedule


@router.post("/generate", response_model=DailyScheduleResponse)
async def generate_schedule(
    schedule_date: str = Query(..., description="Date in YYYY-MM-DD format"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = date.fromisoformat(schedule_date)
    scheduler = SchedulerService(db)
    schedule = await scheduler.generate_daily_schedule(user, target_date)
    return schedule


@router.post("/{schedule_id}/confirm")
async def confirm_schedule(
    schedule_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DailySchedule).where(DailySchedule.id == schedule_id, DailySchedule.user_id == user.id)
    )
    schedule = result.scalar_one_or_none()
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")

    schedule.is_confirmed = True
    await db.commit()
    return {"message": "Schedule confirmed"}
