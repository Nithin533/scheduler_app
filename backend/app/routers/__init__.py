from app.routers.auth import router as auth_router
from app.routers.users import router as users_router
from app.routers.events import router as events_router
from app.routers.tasks import router as tasks_router
from app.routers.habits import router as habits_router
from app.routers.schedules import router as schedules_router
from app.routers.checklists import router as checklists_router
from app.routers.reminders import router as reminders_router
from app.routers.devices import router as devices_router

routers = [
    (auth_router, "/api/auth"),
    (users_router, "/api/users"),
    (events_router, "/api/events"),
    (tasks_router, "/api/tasks"),
    (habits_router, "/api/habits"),
    (schedules_router, "/api/schedules"),
    (checklists_router, "/api/checklists"),
    (reminders_router, "/api/reminders"),
    (devices_router, "/api/devices"),
]
