from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.user_device import UserDevice
from app.middleware.auth import get_current_user

router = APIRouter()


class DeviceRegisterRequest(BaseModel):
    fcm_token: str
    platform: str = "android"


@router.post("/register")
async def register_device(
    payload: DeviceRegisterRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Check if token already exists for this user
    result = await db.execute(
        select(UserDevice).where(
            UserDevice.user_id == user.id,
            UserDevice.fcm_token == payload.fcm_token,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        existing.is_active = True
        existing.platform = payload.platform
        await db.commit()
        return {"message": "Device already registered", "device_id": existing.id}

    device = UserDevice(
        user_id=user.id,
        fcm_token=payload.fcm_token,
        platform=payload.platform,
    )
    db.add(device)
    await db.commit()
    await db.refresh(device)
    return {"message": "Device registered", "device_id": device.id}


@router.delete("/unregister")
async def unregister_device(
    payload: DeviceRegisterRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserDevice).where(
            UserDevice.user_id == user.id,
            UserDevice.fcm_token == payload.fcm_token,
        )
    )
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    device.is_active = False
    await db.commit()
    return {"message": "Device unregistered"}
