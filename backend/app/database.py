from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

# statement_cache_size=0 is required when connecting through Supabase's
# connection pooler (port 6543, PgBouncer in "transaction" mode). PgBouncer
# in that mode doesn't support server-side prepared statements — asyncpg
# creates one per unique query by default, which collides across pooled
# connections and raises DuplicatePreparedStatementError. Disabling the
# cache makes every query a plain (unprepared) statement instead, which
# is the officially recommended workaround. This has no effect (and is
# harmless) if you're connecting directly on port 5432 instead.
engine = create_async_engine(
    settings.database_url,
    echo=False,
    connect_args={"statement_cache_size": 0},
)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Dev convenience only — creates tables directly from models without
    going through Alembic. Safe for a fresh local SQLite/Postgres during
    early development, but once you have real data (e.g. in Supabase),
    schema changes MUST go through `alembic upgrade head` instead, or
    you'll silently lose migration history and risk data loss on the
    next manual change. main.py's lifespan no longer calls this — see
    the README for the `alembic upgrade head` deploy step.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)