from datetime import time
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User, UserProfile
from app.schemas.user import UserResponse, UserProfileCreate, UserProfileResponse
from app.middleware.auth import get_current_user

router = APIRouter()

TIME_FIELDS = ("work_start_time", "work_end_time", "part_time_start", "part_time_end", "bedtime", "wake_time")


def _parse_profile_payload(payload: UserProfileCreate) -> dict:
    data = payload.model_dump(exclude_none=True)
    for field in TIME_FIELDS:
        if field in data and isinstance(data[field], str):
            data[field] = time.fromisoformat(data[field])
    return data


@router.get("/me", response_model=UserResponse)
async def get_me(user: User = Depends(get_current_user)):
    return user


@router.get("/me/profile", response_model=UserProfileResponse)
async def get_profile(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    profile = user.profile
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found. Complete onboarding first.")
    return profile


@router.post("/me/profile", response_model=UserProfileResponse, status_code=201)
async def create_profile(
    payload: UserProfileCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user.profile:
        raise HTTPException(status_code=400, detail="Profile already exists")

    profile = UserProfile(user_id=user.id, **_parse_profile_payload(payload))
    db.add(profile)
    await db.commit()
    await db.refresh(profile)
    return profile


@router.put("/me/profile", response_model=UserProfileResponse)
async def update_profile(
    payload: UserProfileCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not user.profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    for key, value in _parse_profile_payload(payload).items():
        setattr(user.profile, key, value)

    await db.commit()
    await db.refresh(user.profile)
    return user.profile