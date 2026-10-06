from dataclasses import replace

import pytest
from asgi_lifespan import LifespanManager
from pydantic import PostgresDsn

from app.config import Settings
from app.database import Connection
from app.main import create_app
from app.trips import repository
from app.trips.seed import SeedConflictError
from tests.seed_trips import SEED_TRIPS, T9


async def stored_ids(connection: Connection) -> list[str]:
    cursor = await connection.execute("SELECT id FROM trips ORDER BY id")
    return [row[0] for row in await cursor.fetchall()]


@pytest.fixture
def settings(database_url: str) -> Settings:
    return Settings(database_url=PostgresDsn(database_url))


async def test_restart_loads_trips_json_once(settings: Settings, connection: Connection) -> None:
    for _ in range(2):
        async with LifespanManager(create_app(settings)):
            pass

    assert await stored_ids(connection) == sorted(trip.id for trip in SEED_TRIPS)


async def test_startup_stops_at_a_trip_stored_with_other_data(
    settings: Settings, connection: Connection
) -> None:
    edited = replace(T9, amount=T9.amount + 100)
    await repository.insert_if_absent(connection, edited)

    with pytest.raises(SeedConflictError):
        async with LifespanManager(create_app(settings)):
            pass

    assert await stored_ids(connection) == [edited.id]
    assert await repository.insert_if_absent(connection, T9) == edited
