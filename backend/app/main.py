from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import TypedDict

from fastapi import FastAPI

from app.config import Settings, get_settings
from app.database import Pool, create_pool
from app.trips import repository, seed
from app.trips.router import router as trips_router
from app.trips.service import TripsService


class State(TypedDict):
    pool: Pool
    settings: Settings


def create_app(settings: Settings | None = None) -> FastAPI:
    @asynccontextmanager
    async def lifespan(_app: FastAPI) -> AsyncIterator[State]:
        resolved = settings if settings is not None else get_settings()
        trips = seed.read_trips(resolved.trips_file)
        async with create_pool(str(resolved.database_url)) as pool:
            async with pool.connection() as connection:
                await repository.create_schema(connection)
                await seed.load_trips(TripsService(connection, resolved.driver_tz), trips)
            yield {"pool": pool, "settings": resolved}

    app = FastAPI(title="Driver shifts", lifespan=lifespan)
    app.include_router(trips_router, prefix="/api/v1")
    return app


app = create_app()
