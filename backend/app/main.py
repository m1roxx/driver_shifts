from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager
from datetime import UTC, datetime
from typing import TypedDict

from fastapi import FastAPI

from app.config import Settings, get_settings
from app.database import Pool, create_pool
from app.trips import demo, repository, seed
from app.trips.router import router as trips_router
from app.trips.service import TripsService

type Clock = Callable[[], datetime]


class State(TypedDict):
    pool: Pool
    settings: Settings


def system_clock() -> datetime:
    return datetime.now(UTC)


def create_app(settings: Settings | None = None, clock: Clock = system_clock) -> FastAPI:
    @asynccontextmanager
    async def lifespan(_app: FastAPI) -> AsyncIterator[State]:
        resolved = settings if settings is not None else get_settings()
        tz = resolved.driver_tz
        trips = seed.read_trips(resolved.trips_file)
        demo_trips = demo.demo_trips(clock(), tz, resolved.demo_days, demo.days_of(trips, tz))
        async with create_pool(str(resolved.database_url), resolved.database_pool_max_size) as pool:
            async with pool.connection() as connection:
                await repository.lock_startup(connection)
                await repository.create_schema(connection)
                service = TripsService(connection, tz)
                await seed.load_trips(service, trips)
                await demo.load_trips(service, demo_trips)
            yield {"pool": pool, "settings": resolved}

    app = FastAPI(title="Driver shifts", lifespan=lifespan)
    app.include_router(trips_router, prefix="/api/v1")
    return app


app = create_app()
