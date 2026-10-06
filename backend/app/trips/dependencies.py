from collections.abc import AsyncIterator
from typing import Annotated

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


async def get_trips_service(request: Request, connection: ConnectionDep) -> TripsService:
    settings: Settings = request.state.settings
    return TripsService(connection, settings.driver_tz)


TripsServiceDep = Annotated[TripsService, Depends(get_trips_service)]
