import json
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user_device import UserDevice
from app.models.reminder import Reminder

logger = logging.getLogger(__name__)

_firebase_initialized = False


async def _ensure_firebase():
    """Lazy-initialize Firebase Admin SDK when first notification is sent."""
    global _firebase_initialized
    if _firebase_initialized:
        return True

    if not settings.firebase_credentials_path:
        logger.warning("Firebase credentials not configured — notifications disabled")
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        return False


async def send_push_notification(
    db: AsyncSession,
    user_id: int,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> int:
    """Send a push notification to all active devices of a user. Returns count of devices notified."""
    if not await _ensure_firebase():
        return 0

    from firebase_admin import messaging

    # Get user's active devices
    result = await db.execute(
        select(UserDevice).where(
            UserDevice.user_id == user_id,
            UserDevice.is_active == True,
        )
    )
    devices = result.scalars().all()
    if not devices:
        logger.debug(f"No active devices for user {user_id}")
        return 0

    message_data = {"click_action": "FLUTTER_NOTIFICATION_CLICK"}
    if data:
        message_data.update({k: str(v) for k, v in data.items()})

    sent_count = 0
    for device in devices:
        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=message_data,
                token=device.fcm_token,
            )
            messaging.send(message)
            sent_count += 1
        except Exception as e:
            logger.error(f"Failed to send to device {device.id}: {e}")
            # Deactivate invalid tokens
            if "UNREGISTERED" in str(e) or "NOT_FOUND" in str(e):
                device.is_active = False

    await db.commit()
    return sent_count


async def check_and_send_reminders(db: AsyncSession):
    """Check for due unsent reminders and send push notifications."""
    now = datetime.now(timezone.utc)
    window_end = now + timedelta(seconds=5)

    result = await db.execute(
        select(Reminder)
        .where(
            Reminder.is_sent == False,
            Reminder.reminder_time >= now,
            Reminder.reminder_time <= window_end,
        )
    )
    reminders = result.scalars().all()

    for reminder in reminders:
        title = ""
        body = ""
        data = {}

        if reminder.type == "pre_task":
            # Get the item title for a meaningful notification
            schedule_item = await db.execute(
                select(Reminder).where(Reminder.id == reminder.id)
            )
            title = "⏰ Upcoming Activity"
            body = "Your scheduled activity is starting soon"
            data = {"type": "task", "schedule_item_id": str(reminder.schedule_item_id or "")}

            if reminder.schedule_item_id:
                from app.models.schedule import ScheduleItem
                item_result = await db.execute(
                    select(ScheduleItem).where(ScheduleItem.id == reminder.schedule_item_id)
                )
                item = item_result.scalar_one_or_none()
                if item:
                    body = f'"{item.title}" starts at {item.start_time.strftime("%I:%M %p")}'
        elif reminder.type == "bedtime":
            title = "Bedtime Reminder"
            body = "Time to wind down and get ready for sleep"
            data = {"type": "bedtime"}
        elif reminder.type == "habit":
            title = "Habit Reminder"
            body = "Don't forget to track your habit today"
            data = {"type": "habit"}
        elif reminder.type == "daily_review":
            title = "Daily Review"
            body = "Time to review your day and check off completed tasks"
            data = {"type": "daily_review"}
        elif reminder.type == "wake_up":
            title = "Good Morning!"
            body = "Time to start your day"
            data = {"type": "wake_up"}

        await send_push_notification(db, reminder.user_id, title, body, data)

        reminder.is_sent = True
        reminder.sent_at = datetime.now(timezone.utc)

    await db.commit()
    return len(reminders)
