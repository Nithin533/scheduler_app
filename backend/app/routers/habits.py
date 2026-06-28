from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.habit import Habit, HabitLog
from app.schemas.habit import HabitCreate, HabitResponse, HabitLogCreate, HabitLogResponse
from app.middleware.auth import get_current_user

router = APIRouter()


@router.get("/", response_model=list[HabitResponse])
async def list_habits(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Habit).where(Habit.user_id == user.id, Habit.is_active == True))
    return result.scalars().all()


@router.post("/", response_model=HabitResponse, status_code=201)
async def create_habit(
    payload: HabitCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    habit = Habit(user_id=user.id, **payload.model_dump())
    db.add(habit)
    await db.commit()
    await db.refresh(habit)
    return habit


@router.post("/log", response_model=HabitLogResponse, status_code=201)
async def log_habit(
    payload: HabitLogCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import date
    log_date = date.fromisoformat(payload.log_date) if isinstance(payload.log_date, str) else payload.log_date

    log = HabitLog(
        habit_id=payload.habit_id,
        user_id=user.id,
        log_date=log_date,
        value=payload.value,
        notes=payload.notes,
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return log


@router.get("/{habit_id}/logs", response_model=list[HabitLogResponse])
async def get_habit_logs(
    habit_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HabitLog).where(HabitLog.habit_id == habit_id, HabitLog.user_id == user.id)
        .order_by(HabitLog.log_date.desc())
    )
    return result.scalars().all()
