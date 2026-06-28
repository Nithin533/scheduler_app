# Scheduler App — Architecture Document

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — Cross-platform mobile |
| Backend | Python FastAPI |
| Database | MySQL 8.x |
| Auth | JWT tokens |
| Calendar | Google Calendar API |
| Push Notifications | Firebase Cloud Messaging |
| ORM | SQLAlchemy (async) |
| Migrations | Alembic |

---

## Project Structure

```
scheduler_app/
├── backend/
│   ├── app/
│   │   ├── main.py                 # FastAPI entry point
│   │   ├── config.py               # Environment config
│   │   ├── database.py             # DB connection & session
│   │   ├── models/                 # SQLAlchemy models
│   │   ├── schemas/                # Pydantic request/response schemas
│   │   ├── routers/                # API route handlers
│   │   │   ├── auth.py
│   │   │   ├── users.py
│   │   │   ├── tasks.py
│   │   │   ├── events.py
│   │   │   ├── schedules.py
│   │   │   ├── habits.py
│   │   │   ├── checklists.py
│   │   │   ├── questionnaire.py
│   │   │   └── google_calendar.py
│   │   ├── services/               # Business logic
│   │   │   ├── scheduler.py        # Core scheduling engine
│   │   │   ├── rescheduler.py      # Rescheduling logic
│   │   │   ├── questionnaire.py    # Onboarding logic
│   │   │   ├── reminders.py        # Reminder service
│   │   │   ├── checklist.py        # End-of-day logic
│   │   │   └── google_calendar.py  # Calendar sync
│   │   ├── utils/                  # Helpers
│   │   │   ├── priority.py
│   │   │   ├── time_utils.py
│   │   │   └── notifications.py
│   │   └── middleware/
│   │       ├── auth.py             # JWT middleware
│   │       └── cors.py
│   ├── alembic/                    # DB migrations
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart                # MaterialApp + routing
│   │   ├── config/                 # API config, constants
│   │   ├── models/                 # Dart model classes
│   │   ├── services/               # API client, auth service
│   │   ├── providers/              # State management (Riverpod)
│   │   ├── screens/                # Full screens
│   │   │   ├── splash/
│   │   │   ├── auth/
│   │   │   ├── onboarding/         # Initial questionnaire
│   │   │   ├── home/               # Daily view
│   │   │   ├── schedule/           # Full schedule view
│   │   │   ├── tasks/
│   │   │   ├── habits/
│   │   │   ├── checklist/          # End-of-day
│   │   │   └── settings/
│   │   ├── widgets/                # Reusable widgets
│   │   └── utils/                  # Date helpers, formatting
│   ├── pubspec.yaml
│   └── android/ ios/
└── docs/
    └── architecture.md
```

---

## Database Schema (MySQL)

### 1. `users`

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| email | VARCHAR(255) UNIQUE NOT NULL | |
| password_hash | VARCHAR(255) NOT NULL | |
| name | VARCHAR(100) | |
| created_at | DATETIME DEFAULT NOW() | |
| updated_at | DATETIME ON UPDATE NOW() | |

### 2. `user_profiles`

Stores the initial onboarding questionnaire + lifestyle data.

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| age | INT | |
| occupation | VARCHAR(100) | e.g. "College Student" |
| work_start_time | TIME | Fixed block start (e.g., 09:00) |
| work_end_time | TIME | Fixed block end (e.g., 17:00) |
| work_days | JSON | ["Mon","Tue","Wed","Thu","Fri"] |
| commute_time_minutes | INT | Default 30 |
| sports | JSON | [{"name":"swimming","days_per_week":2}, ...] |
| hobbies | JSON | [{"name":"dance","days_per_week":2}, ...] |
| skills_learning | JSON | [{"name":"cybersecurity","hours_per_week":5}, ...] |
| long_term_goals | JSON | [{"title":"Read book X","deadline":"2026-08-01","pages":300}, ...] |
| fitness_info | JSON | {"gym_days_per_week":3, "gym_duration_minutes":60} |
| diet_tracking | JSON | [{"item":"protein", "target":"30g","unit":"g","frequency":"daily"}, {"item":"seeds","target":"2tbsp","frequency":"daily"}] |
| sleep_target_hours | DECIMAL(3,1) | Default 8.0 |
| has_part_time_job | BOOLEAN | |
| part_time_start | TIME | |
| part_time_end | TIME | |
| part_time_days | JSON | |
| created_at | DATETIME | |
| updated_at | DATETIME | |

### 3. `fixed_events`

These are immutable calendar events that the scheduler must respect.

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| title | VARCHAR(200) | |
| description | TEXT | |
| day_of_week | TINYINT | 0=Sun, 1=Mon ... 6=Sat |
| start_time | TIME | |
| end_time | TIME | |
| start_date | DATE | If not recurring |
| end_date | DATE | If not recurring |
| is_recurring | BOOLEAN | |
| recurrence_rule | VARCHAR(255) | RRULE or "weekly" |
| category | ENUM('college','work','part_time','other') | |
| color | VARCHAR(7) | Hex color |
| is_active | BOOLEAN | |
| created_at | DATETIME | |

### 4. `tasks`

Flexible tasks that the scheduler can place dynamically.

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| title | VARCHAR(200) | |
| description | TEXT | |
| priority | TINYINT | 1 (urgent) to 5 (can wait) |
| estimated_duration_minutes | INT | |
| category | ENUM('hobby','skill','fitness','career','health','other') | |
| due_date | DATE | |
| is_completed | BOOLEAN DEFAULT FALSE | |
| is_recurring | BOOLEAN | |
| recurrence_rule | VARCHAR(255) | |
| is_flexible | BOOLEAN DEFAULT TRUE | FALSE = try to keep same slot |
| preferred_time_slot | ENUM('morning','afternoon','evening','any') | |
| min_times_per_week | INT | e.g., hobbies must happen ≥2x/week |
| deadline_vs_effort | ENUM('effort','deadline') | How to prioritize |
| parent_goal_id | INT FK → tasks.id | Link to reading goal etc. |
| progress | DECIMAL(5,2) | % complete for long-term goals |
| created_at | DATETIME | |
| updated_at | DATETIME | |

### 5. `habits`

Trackable daily habits (protein, seeds, water, etc.)

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| name | VARCHAR(100) | |
| description | TEXT | |
| unit | VARCHAR(50) | "g", "tbsp", "cups" |
| target_value | DECIMAL(10,2) | |
| frequency | ENUM('daily','weekly','per_meal') | |
| icon | VARCHAR(50) | Icon name |
| created_at | DATETIME | |

### 6. `habit_logs`

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| habit_id | INT FK → habits.id | |
| user_id | INT FK → users.id | |
| log_date | DATE | |
| value | DECIMAL(10,2) | |
| notes | TEXT | |
| created_at | DATETIME | |

### 7. `daily_schedules`

Generated daily plan.

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| schedule_date | DATE | |
| is_confirmed | BOOLEAN DEFAULT FALSE | User has reviewed/approved |
| total_free_hours | DECIMAL(4,1) | |
| total_scheduled_hours | DECIMAL(4,1) | |
| is_balanced | BOOLEAN | Health check passed |
| generated_at | DATETIME | |
| updated_at | DATETIME | |

### 8. `schedule_items`

Individual time blocks in a day's schedule.

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| schedule_id | INT FK → daily_schedules.id | |
| title | VARCHAR(200) | |
| start_time | DATETIME | |
| end_time | DATETIME | |
| duration_minutes | INT | |
| item_type | ENUM('fixed_event','task','habit','break','meal','travel','sleep','bath','free') | |
| task_id | INT FK → tasks.id NULLABLE | |
| event_id | INT FK → fixed_events.id NULLABLE | |
| habit_id | INT FK → habits.id NULLABLE | |
| status | ENUM('scheduled','completed','missed','rescheduled') DEFAULT 'scheduled' | |
| completed_at | DATETIME NULLABLE | |
| priority_at_schedule | TINYINT | Priority level when scheduled |
| created_at | DATETIME | |

### 9. `end_of_day_checklists`

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| checklist_date | DATE | |
| is_completed | BOOLEAN DEFAULT FALSE | All items checked |
| completed_at | DATETIME | |
| created_at | DATETIME | |

### 10. `checklist_items`

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| checklist_id | INT FK → end_of_day_checklists.id | |
| schedule_item_id | INT FK → schedule_items.id | |
| title | VARCHAR(200) | |
| is_checked | BOOLEAN DEFAULT FALSE | |
| checked_at | DATETIME | |

### 11. `rescheduled_items`

Tracks items rescheduled from one day to another.

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| schedule_item_id | INT FK → schedule_items.id | |
| original_date | DATE | |
| rescheduled_to_date | DATE | |
| reason | ENUM('not_completed','conflict','user_request') | |
| created_at | DATETIME | |

### 12. `reminders`

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| schedule_item_id | INT FK → schedule_items.id | |
| reminder_time | DATETIME | |
| is_sent | BOOLEAN DEFAULT FALSE | |
| sent_at | DATETIME | |
| type | ENUM('pre_task','bedtime','habit','daily_review') | |

### 13. `google_calendar_sync`

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| access_token | TEXT | Encrypted |
| refresh_token | TEXT | Encrypted |
| token_expiry | DATETIME | |
| google_calendar_id | VARCHAR(255) | "primary" or custom |
| last_synced_at | DATETIME | |
| sync_enabled | BOOLEAN DEFAULT TRUE | |

---

## API Endpoints

### Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/auth/register | Create account |
| POST | /api/auth/login | Login → JWT |
| POST | /api/auth/refresh | Refresh token |

### User Profile / Onboarding
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/users/me | Get current user |
| PUT | /api/users/me | Update user |
| GET | /api/users/me/profile | Get full profile |
| POST | /api/users/me/profile | Create/onboard profile |
| PUT | /api/users/me/profile | Update profile |
| POST | /api/users/me/questionnaire | Submit onboarding answers |

### Fixed Events
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/events | List fixed events |
| POST | /api/events | Create fixed event |
| PUT | /api/events/{id} | Update event |
| DELETE | /api/events/{id} | Delete event |

### Tasks
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/tasks | List tasks (filterable) |
| POST | /api/tasks | Create task |
| PUT | /api/tasks/{id} | Update task |
| DELETE | /api/tasks/{id} | Delete task |
| PATCH | /api/tasks/{id}/complete | Mark complete |
| POST | /api/tasks/{id}/reschedule | Reschedule task |

### Schedules
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/schedules/today | Get today's schedule |
| GET | /api/schedules/{date} | Get schedule for date |
| POST | /api/schedules/generate | Generate schedule (with date range) |
| POST | /api/schedules/{id}/confirm | Confirm/approve schedule |
| GET | /api/schedules/week | Get weekly view |
| POST | /api/schedules/{id}/items/{item_id}/reorder | Drag & drop reorder |

### Habits
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/habits | List habits |
| POST | /api/habits | Create habit |
| PUT | /api/habits/{id} | Update habit |
| POST | /api/habits/{id}/log | Log daily value |
| GET | /api/habits/{id}/logs | Get habit logs (date range) |
| GET | /api/habits/{id}/weekly-report | Weekly summary |

### End-of-Day Checklist
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/checklists/today | Get today's checklist |
| GET | /api/checklists/{date} | Get checklist for date |
| PATCH | /api/checklists/{id}/items/{item_id} | Check/uncheck item |
| POST | /api/checklists/{id}/complete | Finalize checklist |
| POST | /api/checklists/{id}/reschedule-missed | Reschedule all unchecked |

### Google Calendar
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/calendar/auth-url | Get OAuth URL |
| POST | /api/calendar/callback | Handle OAuth callback |
| POST | /api/calendar/sync | Push schedule to GCal |
| GET | /api/calendar/events | Fetch GCal events |
| POST | /api/calendar/import | Import GCal events as fixed events |
| DELETE | /api/calendar/disconnect | Disconnect GCal |

### Reminders
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/reminders | List upcoming reminders |
| POST | /api/reminders | Create reminder |
| PUT | /api/reminders/{id} | Update |
| DELETE | /api/reminders/{id} | Delete |

---

## Scheduling Algorithm (Core Logic)

### Inputs
- Fixed events (college 9-5, job 6-8, etc.)
- Flexible tasks with priorities, durations, due dates
- User profile constraints (sleep, food, bath, travel time, commute)
- Habit tracking requirements
- Long-term goals (reading a book: N pages/day)

### Algorithm Steps

```
FUNCTION generate_daily_schedule(user, date):
  1. LOAD fixed events for date → mark as IMMUTABLE blocks
  2. LOAD incomplete tasks from today + backlog (priority sorted)
  3. LOAD user profile constraints:
     - Sleep: block 10PM–6AM (configurable)
     - Meal times: 30min breakfast, 45min lunch, 30min dinner
     - Bath: 20min (morning)
     - Commute/travel: buffer blocks
  4. CREATE "free slots" = time between fixed + mandatory blocks
  5. CLASSIFY free slots:
     - Morning (6-12): focus/career tasks
     - Afternoon (12-5): moderate tasks
     - Evening (5-10): hobbies, light tasks
  6. PLACE tasks into free slots:
     - Sort by priority (1 = highest)
     - Respect preferred_time_slot
     - Ensure hobbies ≥ 2x/week
     - Long-term goals get small daily allocations
  7. HEALTH CHECK:
     - Total hours ≤ 16 active hours
     - Buffer at least 30min between activities
     - Sleep block ≥ user's target
  8. GENERATE reminder timestamps (15min before each task)
  9. SAVE daily_schedule + schedule_items
```

### Rescheduling Logic (End of Day)

```
FUNCTION reschedule_missed_items(user, date):
  1. Get checklist for date → find all unchecked items
  2. For each unchecked item:
     a. If task.flexible → schedule to next day with highest priority
     b. If task has deadline → schedule to nearest slot before deadline
     c. If habit → carry forward with note
  3. Mark original schedule_items as "rescheduled"
  4. RE-GENERATE next day's schedule with new load
```

### Weekly Scheduling

```
FUNCTION generate_weekly_schedule(user, week_start):
  1. For each day of the week (Mon–Sun):
     a. Apply daily schedule generation
     b. Track weekly counters (hobbies, gym)
  2. DISTRIBUTE weekly tasks evenly:
     - Hobby ≥ 2 slots across week
     - Skill development ≥ X hours
     - Reading: pages_per_day = total_pages / days_until_deadline
  3. BALANCE workload:
     - No day should exceed 80% of total free time
     - Heavier tasks on free days (weekends)
```

---

## Flutter App Structure

### Screens
1. **SplashScreen** → Auto-login check
2. **LoginScreen / RegisterScreen** → Auth
3. **OnboardingWizard** → Multi-step questionnaire (personality/lifestyle)
4. **HomeScreen** → Today's schedule timeline (vertical list of cards)
5. **FullScheduleScreen** → Week view (horizontal swipe)
6. **TaskListScreen** → All tasks with filters (priority, category, status)
7. **TaskDetailScreen** → Edit/create task
8. **HabitTrackerScreen** → Checkboxes + progress charts
9. **ChecklistScreen** → End-of-day review
10. **SettingsScreen** → Profile, integrations, preferences
11. **CalendarSyncScreen** → GCal connection status

### State Management
- **Riverpod** for global state
- Each feature has a Provider + Notifier
- API layer uses a shared Dio/ApiClient

### Key Widgets
- `ScheduleTimeline` — DnD timeline
- `PriorityBadge` — Colored priority indicator
- `TaskCard` — Swipeable task
- `DayChecklist` — Checkable item list
- `HabitTile` — Daily habit tracker
- `WeeklyCalendar` — Mini calendar header
- `OnboardingStep` — Reusable questionnaire page

---

## Push Notifications

### Architecture
```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Scheduler   │────▶│   Reminders  │────▶│ Notification    │
│  (generates) │     │   Table (DB) │     │ Service         │
└─────────────┘     └──────────────┘     │ (checks every   │
                                          │  15s via        │
┌─────────────┐     ┌──────────────┐     │  background     │
│  Flutter     │◀────│ Firebase     │◀────│  task)          │
│  App (FCM)  │     │ Cloud        │     └─────────────────┘
└─────────────┘     │ Messaging    │
                    └──────────────┘
```

### Flow
1. **Schedule generation** → creates reminder records in DB with `reminder_time`
2. **Background checker** (`app/main.py` → `reminder_loop()`) runs every 15 seconds as an asyncio task
3. **When a reminder is due**: the `NotificationService.send_push_notification()` sends via Firebase Admin SDK
4. **Flutter app** receives the notification via FCM
   - **Foreground**: shown as local notification via `flutter_local_notifications`
   - **Background/Terminated**: shown as system notification, tap opens relevant screen

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| `UserDevice` model | `backend/app/models/user_device.py` | Stores FCM tokens per user |
| `NotificationService` | `backend/app/services/notification_service.py` | Firebase Admin SDK init + sending |
| `reminder_loop()` | `backend/app/main.py` | Background asyncio task (15s interval) |
| `devices` router | `backend/app/routers/devices.py` | Register/unregister FCM tokens |
| `NotificationService` (Dart) | `mobile/lib/services/notification_service.dart` | FCM init, permission request, foreground handler |
| `onNotificationTap` | `mobile/lib/app.dart` | Navigate on notification tap |

### Firebase Setup

**Backend:**
1. Create a Firebase project at https://console.firebase.google.com
2. Project Settings → Service accounts → Generate new private key
3. Save as `backend/firebase-service-account.json`
4. Set `FIREBASE_CREDENTIALS_PATH=./firebase-service-account.json` in `.env`

**Mobile:**
1. In Firebase console, add Android app (package name from `android/app/build.gradle`)
2. Download `google-services.json` → place in `mobile/android/app/`
3. For iOS, add iOS app → download `GoogleService-Info.plist` → place in `mobile/ios/Runner/`
4. The `firebase_core` and `firebase_messaging` packages handle the rest

## Deployment

### Backend
- Docker container with FastAPI + Uvicorn
- MySQL on Docker or managed (PlanetScale, AWS RDS)
- Redis for task queue (reminders, auto-generation)

### Mobile
- Flutter build → APK / AAB for Android
- iOS build via Xcode (if needed later)
- Firebase for push notifications + crashlytics

---

## Future Considerations
- AI priority scoring (learn user behavior over time)
- Collaborative scheduling (share tasks with others)
- Pomodoro timer integration
- Offline-first with local SQLite sync
- Apple Calendar / Outlook integration
