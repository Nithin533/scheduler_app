from datetime import date, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user import User
from app.models.checklist import EndOfDayChecklist, ChecklistItem
from app.models.schedule import RescheduledItem, ScheduleItem
from app.models.task import Task
from app.services.scheduler import SchedulerService


class ReschedulerService:
    """Handles end-of-day rescheduling of uncompleted tasks."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def reschedule_missed(self, user: User, checklist: EndOfDayChecklist):
        """Reschedule all unchecked items to upcoming days."""
        unchecked_items = [
            item for item in checklist.items
            if not item.is_checked and item.schedule_item_id
        ]

        for checklist_item in unchecked_items:
            schedule_item = await self._get_schedule_item(checklist_item.schedule_item_id)
            if not schedule_item:
                continue

            if schedule_item.item_type != "task":
                continue

            # Find original task
            if not schedule_item.task_id:
                continue

            task = await self._get_task(schedule_item.task_id)
            if not task or not task.is_flexible:
                continue

            # Schedule to next day
            next_day = checklist.checklist_date + timedelta(days=1)
            max_days = 7
            for day_offset in range(1, max_days + 1):
                target_day = checklist.checklist_date + timedelta(days=day_offset)
                if task.due_date and target_day > task.due_date:
                    target_day = task.due_date
                    break

            # Record rescheduling
            reschedule_record = RescheduledItem(
                schedule_item_id=schedule_item.id,
                original_date=checklist.checklist_date,
                rescheduled_to_date=target_day,
                reason="not_completed",
            )
            self.db.add(reschedule_record)

            # Mark original item as rescheduled
            schedule_item.status = "rescheduled"

        await self.db.commit()

        # Regenerate next day's schedule
        next_day = checklist.checklist_date + timedelta(days=1)
        scheduler = SchedulerService(self.db)
        await scheduler.generate_daily_schedule(user, next_day)

    async def _get_schedule_item(self, item_id: int) -> ScheduleItem | None:
        result = await self.db.execute(
            select(ScheduleItem).where(ScheduleItem.id == item_id)
        )
        return result.scalar_one_or_none()

    async def _get_task(self, task_id: int) -> Task | None:
        result = await self.db.execute(select(Task).where(Task.id == task_id))
        return result.scalar_one_or_none()
