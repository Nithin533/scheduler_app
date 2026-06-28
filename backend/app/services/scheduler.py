import json
from datetime import date, datetime, time, timedelta, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user import User, UserProfile
from app.models.event import FixedEvent
from app.models.task import Task
from app.models.habit import Habit
from app.models.schedule import DailySchedule, ScheduleItem
from app.models.checklist import EndOfDayChecklist, ChecklistItem
from app.models.reminder import Reminder


class SchedulerService:
    """Core scheduling engine that generates optimal daily schedules."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def generate_daily_schedule(self, user: User, target_date: date) -> DailySchedule:
        # 1. Load profile & constraints
        profile = user.profile
        if not profile:
            return await self._create_empty_schedule(user, target_date)

        # 2. Load fixed events for the day
        fixed_events = await self._get_fixed_events(user.id, target_date)

        # 3. Load incomplete tasks (prioritized)
        tasks = await self._get_pending_tasks(user.id)

        # 4. Load habits
        habits = await self._get_active_habits(user.id)

        # 5. Build time blocks
        day_start = datetime.combine(target_date, time(6, 0), tzinfo=timezone.utc)   # 6 AM
        day_end = datetime.combine(target_date, time(22, 0), tzinfo=timezone.utc)    # 10 PM
        sleep_start = datetime.combine(target_date, time(22, 0), tzinfo=timezone.utc)
        sleep_end = datetime.combine(target_date + timedelta(days=1), time(6, 0), tzinfo=timezone.utc)

        blocks: list[dict] = []
        mandatory_block = False

        # Add sleep block
        blocks.append(self._make_block(
            "sleep", "Sleep", sleep_start, sleep_end,
            item_type="sleep"
        ))

        # Add morning routine (bath 20min, breakfast 30min)
        morning_routine_end = day_start + timedelta(minutes=50)
        blocks.append(self._make_block(
            "morning_routine", "Morning Routine (Bath + Breakfast)",
            day_start, morning_routine_end, item_type="meal"
        ))

        current_time = morning_routine_end

        # Add commute if applicable
        if profile.commute_time_minutes and profile.commute_time_minutes > 0:
            commute_end = current_time + timedelta(minutes=int(profile.commute_time_minutes))
            blocks.append(self._make_block(
                "commute", "Travel", current_time, commute_end, item_type="travel"
            ))
            current_time = commute_end

        # Place fixed events
        for event in fixed_events:
            event_start = datetime.combine(target_date, event.start_time)
            event_end = datetime.combine(target_date, event.end_time)

            if event_start < current_time:
                event_start = current_time

            if event_end > event_start:
                # Add gap before event if there's a gap
                if event_start > current_time:
                    blocks.append(self._make_block(
                        "gap", "Free Time", current_time, event_start, item_type="free"
                    ))

                blocks.append(self._make_block(
                    f"event_{event.id}",
                    event.title,
                    event_start,
                    event_end,
                    item_type="fixed_event",
                    event_id=event.id,
                ))
                current_time = event_end

        # Add lunch (12:00-12:45)
        lunch_start = max(current_time, datetime.combine(target_date, time(12, 0), tzinfo=timezone.utc))
        lunch_end = lunch_start + timedelta(minutes=45)
        if lunch_end <= day_end:
            if lunch_start > current_time:
                blocks.append(self._make_block(
                    "gap", "Free Time", current_time, lunch_start, item_type="free"
                ))
            blocks.append(self._make_block(
                "lunch", "Lunch Break", lunch_start, lunch_end, item_type="meal"
            ))
            current_time = lunch_end

        # Add dinner (19:00-19:30)
        dinner_start = max(current_time, datetime.combine(target_date, time(19, 0), tzinfo=timezone.utc))
        dinner_end = dinner_start + timedelta(minutes=30)
        if dinner_end <= day_end:
            if dinner_start > current_time:
                blocks.append(self._make_block(
                    "gap", "Free Time", current_time, dinner_start, item_type="free"
                ))
            blocks.append(self._make_block(
                "dinner", "Dinner", dinner_start, dinner_end, item_type="meal"
            ))
            current_time = dinner_end

        # Schedule remaining tasks in free time
        tasks_to_schedule = [t for t in tasks if not t.is_completed]

        # Sort by priority (1 = highest)
        tasks_to_schedule.sort(key=lambda t: (t.priority, t.due_date or date.max))

        for task in tasks_to_schedule:
            if current_time >= day_end - timedelta(hours=1):
                break  # Not enough time left

            duration = timedelta(minutes=task.estimated_duration_minutes or 30)
            task_end = min(current_time + duration, day_end)
            task_duration = task_end - current_time

            if task_duration.total_seconds() < 300:  # Less than 5 min
                continue

            blocks.append(self._make_block(
                f"task_{task.id}",
                task.title,
                current_time,
                task_end,
                item_type="task",
                task_id=task.id,
                priority=task.priority,
            ))
            current_time = task_end

            # Add short break (5 min) between tasks
            if current_time < day_end - timedelta(minutes=10):
                break_end = min(current_time + timedelta(minutes=5), day_end)
                blocks.append(self._make_block(
                    "break", "Short Break", current_time, break_end, item_type="break"
                ))
                current_time = break_end

        # Create or update daily schedule
        existing_result = await self.db.execute(
            select(DailySchedule).where(
                DailySchedule.user_id == user.id,
                DailySchedule.schedule_date == target_date,
            )
        )
        existing = existing_result.scalar_one_or_none()

        if existing:
            schedule = existing
            # Eagerly load items to avoid MissingGreenlet
            await self.db.refresh(schedule, ['items'])
            # Remove old items
            for item in schedule.items:
                await self.db.delete(item)
            schedule.items = []
        else:
            schedule = DailySchedule(
                user_id=user.id,
                schedule_date=target_date,
            )
            self.db.add(schedule)

        await self.db.flush()

        # Create schedule items
        total_scheduled = 0
        for block in blocks:
            item = ScheduleItem(
                schedule_id=schedule.id,
                title=block["title"],
                start_time=block["start_time"],
                end_time=block["end_time"],
                duration_minutes=int((block["end_time"] - block["start_time"]).total_seconds() / 60),
                item_type=block["item_type"],
                task_id=block.get("task_id"),
                event_id=block.get("event_id"),
                habit_id=None,
                priority_at_schedule=block.get("priority"),
            )
            schedule.items.append(item)
            if block["item_type"] not in ("sleep", "free"):
                total_scheduled += item.duration_minutes

        total_free = int((day_end - day_start).total_seconds() / 60)
        schedule.total_free_hours = round(total_free / 60, 1)
        schedule.total_scheduled_hours = round(total_scheduled / 60, 1)
        schedule.is_balanced = total_scheduled <= total_free * 0.8  # Max 80% utilization

        await self.db.commit()

        # Reload with items eagerly loaded for response serialization
        result = await self.db.execute(
            select(DailySchedule)
            .where(DailySchedule.id == schedule.id)
            .options(selectinload(DailySchedule.items))
        )
        schedule = result.scalar_one()

        # Generate end-of-day checklist
        await self._generate_checklist(user, schedule)

        # Generate reminders
        await self._generate_reminders(user, schedule)

        return schedule

    async def _get_fixed_events(self, user_id: int, target_date: date) -> list[FixedEvent]:
        weekday = (target_date.isoweekday() % 7)  # 0=Sun .. 6=Sat (matching DB convention)
        result = await self.db.execute(
            select(FixedEvent).where(
                FixedEvent.user_id == user_id,
                FixedEvent.is_active == True,
            )
        )
        events = result.scalars().all()
        return [e for e in events if e.day_of_week == weekday and e.is_recurring]

    async def _get_pending_tasks(self, user_id: int) -> list[Task]:
        result = await self.db.execute(
            select(Task).where(
                Task.user_id == user_id,
                Task.is_completed == False,
            ).order_by(Task.priority, Task.due_date)
        )
        return result.scalars().all()

    async def _get_active_habits(self, user_id: int) -> list[Habit]:
        result = await self.db.execute(
            select(Habit).where(Habit.user_id == user_id, Habit.is_active == True)
        )
        return result.scalars().all()

    async def _create_empty_schedule(self, user: User, target_date: date) -> DailySchedule:
        schedule = DailySchedule(
            user_id=user.id,
            schedule_date=target_date,
            total_free_hours=16,
            total_scheduled_hours=0,
        )
        self.db.add(schedule)
        await self.db.commit()
        result = await self.db.execute(
            select(DailySchedule)
            .where(DailySchedule.id == schedule.id)
            .options(selectinload(DailySchedule.items))
        )
        return result.scalar_one()

    async def _generate_checklist(self, user: User, schedule: DailySchedule):
        existing_result = await self.db.execute(
            select(EndOfDayChecklist).where(
                EndOfDayChecklist.user_id == user.id,
                EndOfDayChecklist.checklist_date == schedule.schedule_date,
            )
        )
        if existing_result.scalar_one_or_none():
            return

        checklist = EndOfDayChecklist(
            user_id=user.id,
            checklist_date=schedule.schedule_date,
        )
        self.db.add(checklist)
        await self.db.flush()

        task_items = [item for item in schedule.items if item.item_type == "task"]
        for item in task_items:
            checklist_item = ChecklistItem(
                checklist_id=checklist.id,
                schedule_item_id=item.id,
                title=item.title,
            )
            self.db.add(checklist_item)

        await self.db.commit()

    async def _generate_reminders(self, user: User, schedule: DailySchedule):
        for item in schedule.items:
            if item.item_type not in ("task", "habit", "gym"):
                continue

            reminder_time = item.start_time - timedelta(minutes=15)
            now = datetime.now(timezone.utc)

            if reminder_time > now:
                reminder = Reminder(
                    user_id=user.id,
                    schedule_item_id=item.id,
                    reminder_time=reminder_time,
                    type="pre_task",
                )
                self.db.add(reminder)

        await self.db.commit()

    def _make_block(self, block_id: str, title: str, start_time: datetime, end_time: datetime, **kwargs) -> dict:
        return {
            "id": block_id,
            "title": title,
            "start_time": start_time,
            "end_time": end_time,
            **kwargs,
        }
