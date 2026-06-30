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
        """Reschedule all unchecked items to upcoming days.

        Completed items were already synced to Task.is_completed by the
        checklist router, so generate_daily_schedule() will naturally skip
        them. For items still unchecked, we bump the task's priority so it
        surfaces first in the next schedule generation, and record the
        move so the UI / weekly review can show what got pushed.
        """
        unchecked_items = [
            item for item in checklist.items
            if not item.is_checked and item.schedule_item_id
        ]

        target_day = checklist.checklist_date + timedelta(days=1)
        bumped_task_ids: set[int] = set()

        for checklist_item in unchecked_items:
            schedule_item = await self._get_schedule_item(checklist_item.schedule_item_id)
            if not schedule_item:
                continue

            if schedule_item.item_type != "task":
                continue

            if not schedule_item.task_id or schedule_item.task_id in bumped_task_ids:
                continue

            task = await self._get_task(schedule_item.task_id)
            if not task or not task.is_flexible or task.is_completed:
                continue

            # Pick the actual target day: tomorrow, unless the task has an
            # earlier due_date that's already in the past relative to that.
            actual_target = target_day
            if task.due_date and task.due_date < target_day:
                actual_target = max(checklist.checklist_date, task.due_date)

            # Bump priority by one level (lower number = more urgent) so it
            # is picked up before other pending tasks when we regenerate.
            if task.priority > 1:
                task.priority -= 1
            bumped_task_ids.add(task.id)

            # Mark the missed schedule item explicitly.
            schedule_item.status = "missed"

            reschedule_record = RescheduledItem(
                schedule_item_id=schedule_item.id,
                original_date=checklist.checklist_date,
                rescheduled_to_date=actual_target,
                reason="not_completed",
            )
            self.db.add(reschedule_record)

        await self.db.commit()

        # Regenerate the next day's schedule — pending (incomplete) tasks,
        # now bumped in priority, will be slotted in first.
        scheduler = SchedulerService(self.db)
        await scheduler.generate_daily_schedule(user, target_day)

    async def _get_schedule_item(self, item_id: int) -> ScheduleItem | None:
        result = await self.db.execute(
            select(ScheduleItem).where(ScheduleItem.id == item_id)
        )
        return result.scalar_one_or_none()

    async def _get_task(self, task_id: int) -> Task | None:
        result = await self.db.execute(select(Task).where(Task.id == task_id))
        return result.scalar_one_or_none()