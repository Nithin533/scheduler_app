from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.user import User
from app.models.checklist import EndOfDayChecklist, ChecklistItem
from app.schemas.checklist import CheckListResponse, ChecklistItemUpdate
from app.middleware.auth import get_current_user

router = APIRouter()


@router.get("/today", response_model=CheckListResponse)
async def get_today_checklist(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    result = await db.execute(
        select(EndOfDayChecklist)
        .where(EndOfDayChecklist.user_id == user.id, EndOfDayChecklist.checklist_date == today)
        .options(selectinload(EndOfDayChecklist.items))
    )
    checklist = result.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="No checklist for today. Generate a schedule first.")
    return checklist


@router.patch("/{checklist_id}/items/{item_id}", response_model=CheckListResponse)
async def toggle_checklist_item(
    checklist_id: int,
    item_id: int,
    payload: ChecklistItemUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ChecklistItem).where(ChecklistItem.id == item_id, ChecklistItem.checklist_id == checklist_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Checklist item not found")

    item.is_checked = payload.is_checked
    item.checked_at = datetime.now(timezone.utc) if payload.is_checked else None

    await db.commit()

    result = await db.execute(
        select(EndOfDayChecklist)
        .where(EndOfDayChecklist.id == checklist_id)
        .options(selectinload(EndOfDayChecklist.items))
    )
    return result.scalar_one()


@router.post("/{checklist_id}/complete")
async def complete_checklist(
    checklist_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(EndOfDayChecklist).where(EndOfDayChecklist.id == checklist_id, EndOfDayChecklist.user_id == user.id)
    )
    checklist = result.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="Checklist not found")

    checklist.is_completed = True
    checklist.completed_at = datetime.now(timezone.utc)
    await db.commit()

    from app.services.rescheduler import ReschedulerService
    rescheduler = ReschedulerService(db)
    await rescheduler.reschedule_missed(user, checklist)

    return {"message": "Checklist completed. Missed items rescheduled."}
