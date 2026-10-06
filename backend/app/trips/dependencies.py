from collections.abc import AsyncIterator
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import Depends, Request

from app.config import Settings
from app.database import Connection, Pool
from app.trips.service import TripsService


async def get_connection(request: Request) -> AsyncIterator[Connection]:
    pool: Pool = request.state.pool
    async with pool.connection() as connection:
        yield connection


# scope="function" commits before the response goes out: a client that got its answer
# finds its write on the very next request.
ConnectionDep = Annotated[Connection, Depends(get_connection, scope="function")]


async def get_driver_tz(request: Request) -> ZoneInfo:
    settings: Settings = request.state.settings
    return settings.driver_tz


DriverTzDep = Annotated[ZoneInfo, Depends(get_driver_tz)]


async def get_trips_service(connection: ConnectionDep, driver_tz: DriverTzDep) -> TripsService:
    return TripsService(connection, driver_tz)


TripsServiceDep = Annotated[TripsService, Depends(get_trips_service)]
