import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import init_db, async_session
from app.routers import routers
from app.services.notification_service import check_and_send_reminders

logger = logging.getLogger(__name__)


async def reminder_loop():
    """Background task that checks for due reminders every 15 seconds."""
    while True:
        try:
            async with async_session() as db:
                count = await check_and_send_reminders(db)
                if count > 0:
                    logger.info(f"Sent {count} reminder(s)")
        except Exception as e:
            logger.error(f"Reminder check error: {e}")
        await asyncio.sleep(15)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    task = asyncio.create_task(reminder_loop())
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title="Scheduler App API",
    description="Smart priority-based scheduling API with health-aware planning",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8000", "http://10.0.2.2:8000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

for router, prefix in routers:
    app.include_router(router, prefix=prefix)


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "1.0.0"}
