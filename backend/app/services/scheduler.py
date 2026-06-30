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
from app.services.gemini_service import get_ai_task_ordering


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

        # 5. Build time blocks — sleep window comes from the user's own
        # profile instead of being hardcoded, so "Sleep and preferences"
        # from onboarding actually has an effect.
        wake_time = profile.wake_time or time(6, 30)
        bedtime = profile.bedtime or time(22, 30)

        day_start = datetime.combine(target_date, wake_time, tzinfo=timezone.utc)
        sleep_start = datetime.combine(target_date, bedtime, tzinfo=timezone.utc)
        if bedtime <= wake_time:
            sleep_start = datetime.combine(target_date, bedtime, tzinfo=timezone.utc) + timedelta(days=1)
        sleep_end = datetime.combine(target_date + timedelta(days=1), wake_time, tzinfo=timezone.utc)
        day_end = sleep_start  # the day's active window runs until bedtime

        blocks: list[dict] = []

        # Add sleep block
        blocks.append(self._make_block(
            "sleep", "Sleep", sleep_start, sleep_end,
            item_type="sleep"
        ))

        # Wind-down block — 20 minutes before bedtime, screens off
        winddown_start = sleep_start - timedelta(minutes=20)
        blocks.append(self._make_block(
            "winddown", "Wind-down (no screens)", winddown_start, sleep_start,
            item_type="break"
        ))

        # Morning hygiene (shower/getting ready) — separate from breakfast
        # so it's individually trackable.
        hygiene_end = day_start + timedelta(minutes=20)
        blocks.append(self._make_block(
            "morning_hygiene", "Morning hygiene (shower, getting ready)",
            day_start, hygiene_end, item_type="bath"
        ))

        # Breakfast — separate block from hygiene
        breakfast_end = hygiene_end + timedelta(minutes=20)
        blocks.append(self._make_block(
            "breakfast", "Breakfast", hygiene_end, breakfast_end, item_type="meal"
        ))

        current_time = breakfast_end

        # Add commute if applicable
        if profile.commute_time_minutes and profile.commute_time_minutes > 0:
            commute_end = current_time + timedelta(minutes=int(profile.commute_time_minutes))
            blocks.append(self._make_block(
                "commute", "Travel", current_time, commute_end, item_type="travel"
            ))
            current_time = commute_end

        # Place fixed events
        for event in fixed_events:
            event_start = datetime.combine(target_date, event.start_time, tzinfo=timezone.utc)
            event_end = datetime.combine(target_date, event.end_time, tzinfo=timezone.utc)

            if event_start < current_time:
                event_start = current_time

            if event_end > event_start:
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

        # Reserve the last 30 minutes of the day for evening hygiene (10 min)
        # + wind-down (20 min) so tasks don't crowd out bedtime prep.
        evening_routine_minutes = 30
        tasks_cutoff = sleep_start - timedelta(minutes=evening_routine_minutes)

        # Sort by priority (1 = highest) as the guaranteed fallback —
        # this line ALWAYS runs so the day is buildable even if Gemini
        # is unreachable, unconfigured, or returns garbage.
        tasks_to_schedule.sort(key=lambda t: (t.priority, t.due_date or date.max))

        # Ask Gemini to refine the ordering / selection given the actual
        # free time available today. This never raises — on any failure
        # it returns None and we keep the rule-based order above.
        free_minutes_today = max(0, int((tasks_cutoff - current_time).total_seconds() / 60))
        ai_ordering = await get_ai_task_ordering(
            tasks=[
                {
                    "id": t.id,
                    "title": t.title,
                    "category": t.category,
                    "priority": t.priority,
                    "estimated_duration_minutes": t.estimated_duration_minutes,
                    "due_date": t.due_date.isoformat() if t.due_date else None,
                }
                for t in tasks_to_schedule
            ],
            free_minutes_today=free_minutes_today,
            target_date=target_date,
            profile_summary={
                "occupation": profile.occupation,
                "hobbies": profile.hobbies or [],
                "skills_learning": profile.skills_learning or [],
            },
        )
        if ai_ordering:
            tasks_by_id = {t.id: t for t in tasks_to_schedule}
            reordered = [tasks_by_id[tid] for tid in ai_ordering if tid in tasks_by_id]
            remaining = [t for t in tasks_to_schedule if t.id not in set(ai_ordering)]
            tasks_to_schedule = reordered + remaining

        for task in tasks_to_schedule:
            if current_time >= tasks_cutoff - timedelta(hours=1):
                break  # Not enough time left

            duration = timedelta(minutes=task.estimated_duration_minutes or 30)
            task_end = min(current_time + duration, tasks_cutoff)
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
            if current_time < tasks_cutoff - timedelta(minutes=10):
                break_end = min(current_time + timedelta(minutes=5), tasks_cutoff)
                blocks.append(self._make_block(
                    "break", "Short Break", current_time, break_end, item_type="break"
                ))
                current_time = break_end

        # Evening hygiene — fills the gap between the last task and
        # wind-down (brush teeth, skincare, lay out tomorrow's things).
        evening_hygiene_start = max(current_time, sleep_start - timedelta(minutes=evening_routine_minutes))
        evening_hygiene_end = sleep_start - timedelta(minutes=20)  # leaves 20 min for wind-down
        if evening_hygiene_end > evening_hygiene_start:
            if evening_hygiene_start > current_time:
                blocks.append(self._make_block(
                    "gap", "Free Time", current_time, evening_hygiene_start, item_type="free"
                ))
            blocks.append(self._make_block(
                "evening_hygiene", "Evening hygiene (brush, skincare)",
                evening_hygiene_start, evening_hygiene_end, item_type="bath"
            ))
            current_time = evening_hygiene_end

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
            await self.db.refresh(schedule, ['items'])
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
        schedule.is_balanced = total_scheduled <= total_free * 0.8

        await self.db.commit()

        result = await self.db.execute(
            select(DailySchedule)
            .where(DailySchedule.id == schedule.id)
            .options(selectinload(DailySchedule.items))
        )
        schedule = result.scalar_one()

        await self._generate_checklist(user, schedule)
        await self._generate_reminders(user, schedule)

        return schedule

    async def _get_fixed_events(self, user_id: int, target_date: date) -> list[FixedEvent]:
        weekday = (target_date.isoweekday() % 7)
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