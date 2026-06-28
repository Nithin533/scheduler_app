from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.event import FixedEvent
from app.schemas.event import FixedEventCreate, FixedEventResponse
from app.middleware.auth import get_current_user

router = APIRouter()


@router.get("/", response_model=list[FixedEventResponse])
async def list_events(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(FixedEvent).where(FixedEvent.user_id == user.id, FixedEvent.is_active == True))
    return result.scalars().all()


@router.post("/", response_model=FixedEventResponse, status_code=201)
async def create_event(
    payload: FixedEventCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = FixedEvent(user_id=user.id, **payload.model_dump())
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return event


@router.put("/{event_id}", response_model=FixedEventResponse)
async def update_event(
    event_id: int,
    payload: FixedEventCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(FixedEvent).where(FixedEvent.id == event_id, FixedEvent.user_id == user.id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    for key, value in payload.model_dump(exclude_none=True).items():
        setattr(event, key, value)

    await db.commit()
    await db.refresh(event)
    return event


@router.delete("/{event_id}", status_code=204)
async def delete_event(
    event_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(FixedEvent).where(FixedEvent.id == event_id, FixedEvent.user_id == user.id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    await db.delete(event)
    await db.commit()
