from collections.abc import AsyncIterator
from dataclasses import replace
from datetime import date, datetime, timedelta

import pytest
from asgi_lifespan import LifespanManager
from httpx import AsyncClient
from pydantic import PostgresDsn
from starlette.types import ASGIApp

from app.config import Settings
from app.database import Connection
from app.main import Clock, create_app
from app.trips import repository
from app.trips.demo import days_of, demo_trips
from app.trips.domain import Trip
from app.trips.schemas import TripOut
from tests.integration.test_days_api import TASK_EXAMPLE_DAY
from tests.seed_trips import ALMATY, SEED_TRIPS

NOW = datetime(2026, 10, 7, 12, 30, tzinfo=ALMATY)
DEMO_DAYS = 14
EXPECTED_DEMO = demo_trips(NOW, ALMATY, DEMO_DAYS, days_of(SEED_TRIPS, ALMATY))


def at(moment: datetime) -> Clock:
    return lambda: moment


def on_day(trips: list[Trip], day: date) -> list[Trip]:
    return [trip for trip in trips if trip.start.astimezone(ALMATY).date() == day]


async def stored_ids(connection: Connection) -> list[str]:
    cursor = await connection.execute("SELECT id FROM trips ORDER BY id")
    return [row[0] for row in await cursor.fetchall()]


async def start_and_stop(settings: Settings, moment: datetime) -> None:
    async with LifespanManager(create_app(settings, at(moment))):
        pass


@pytest.fixture
def settings(database_url: str) -> Settings:
    return Settings(database_url=PostgresDsn(database_url), demo_days=DEMO_DAYS)


@pytest.fixture
async def app(settings: Settings, connection: Connection) -> AsyncIterator[ASGIApp]:
    async with LifespanManager(create_app(settings, at(NOW))) as manager:
        yield manager.app


async def test_a_demo_day_returns_its_demo_trips(client: AsyncClient) -> None:
    expected = on_day(EXPECTED_DEMO, date(2026, 10, 6))

    response = await client.get("/api/v1/days/2026-10-06")

    assert response.status_code == 200
    body = response.json()
    assert body["summary"]["trips_count"] == len(expected) >= 3
    assert body["trips"] == [
        TripOut.from_domain(trip, ALMATY).model_dump(mode="json") for trip in expected
    ]


async def test_today_shows_only_the_trips_that_have_ended(client: AsyncClient) -> None:
    response = await client.get("/api/v1/days/2026-10-07")

    assert [trip["id"] for trip in response.json()["trips"]] == ["demo-2026-10-07-1"]


async def test_the_assignment_day_stays_as_in_the_assignment(client: AsyncClient) -> None:
    response = await client.get("/api/v1/days/2026-10-01")

    assert response.json() == TASK_EXAMPLE_DAY


async def test_the_days_around_the_seed_get_demo_trips(client: AsyncClient) -> None:
    for day in ("2026-09-29", "2026-10-04"):
        response = await client.get(f"/api/v1/days/{day}")

        ids = [trip["id"] for trip in response.json()["trips"]]
        assert ids
        assert all(trip_id.startswith(f"demo-{day}-") for trip_id in ids)


async def test_restarts_do_not_duplicate_and_roll_the_window_forward(
    settings: Settings, connection: Connection
) -> None:
    seed_ids = [trip.id for trip in SEED_TRIPS]

    for _ in range(2):
        await start_and_stop(settings, NOW)
    assert await stored_ids(connection) == sorted(seed_ids + [trip.id for trip in EXPECTED_DEMO])

    later = NOW + timedelta(days=1)
    await start_and_stop(settings, later)
    rolled = demo_trips(later, ALMATY, DEMO_DAYS, days_of(SEED_TRIPS, ALMATY))
    assert await stored_ids(connection) == sorted(
        {*seed_ids, *(trip.id for trip in EXPECTED_DEMO), *(trip.id for trip in rolled)}
    )


async def test_a_demo_id_stored_with_other_data_is_skipped(
    settings: Settings, connection: Connection, caplog: pytest.LogCaptureFixture
) -> None:
    first = EXPECTED_DEMO[0]
    edited = replace(first, amount=first.amount + 100)
    await repository.insert_if_absent(connection, edited)

    await start_and_stop(settings, NOW)

    assert await repository.insert_if_absent(connection, first) == edited
    assert len(await stored_ids(connection)) == len(SEED_TRIPS) + len(EXPECTED_DEMO)
    assert any(
        record.levelname == "WARNING" and first.id in record.getMessage()
        for record in caplog.records
    )
