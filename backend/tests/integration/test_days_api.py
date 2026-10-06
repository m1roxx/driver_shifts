from datetime import datetime, timedelta
from typing import Any

import pytest
from httpx import AsyncClient

from app.database import Connection
from app.trips import repository
from app.trips.domain import PaymentMethod, Trip

TASK_EXAMPLE_DAY = {
    "date": "2026-10-01",
    "timezone": "Asia/Almaty",
    "summary": {
        "trips_count": 2,
        "revenue": 3900,
        "commission": 585,
        "net": 3315,
        "by_payment": {"cash": 1500, "card": 2400},
    },
    "trips": [
        {
            "id": "t1",
            "start": "2026-10-01T08:10:00+05:00",
            "end": "2026-10-01T08:32:00+05:00",
            "amount": 2400,
            "payment": "card",
            "commission": 360,
        },
        {
            "id": "t2",
            "start": "2026-10-01T09:05:00+05:00",
            "end": "2026-10-01T09:20:00+05:00",
            "amount": 1500,
            "payment": "cash",
            "commission": 225,
        },
    ],
}


def summary(
    trips_count: int, revenue: int, commission: int, net: int, cash: int, card: int
) -> dict[str, Any]:
    return {
        "trips_count": trips_count,
        "revenue": revenue,
        "commission": commission,
        "net": net,
        "by_payment": {"cash": cash, "card": card},
    }


async def get_day(client: AsyncClient, day: str) -> dict[str, Any]:
    response = await client.get(f"/api/v1/days/{day}")
    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    return body


async def test_task_example_day_matches_the_contract(client: AsyncClient) -> None:
    assert await get_day(client, "2026-10-01") == TASK_EXAMPLE_DAY


@pytest.mark.parametrize(
    ("day", "expected_summary", "trip_ids"),
    [
        pytest.param(
            "2026-09-30",
            summary(3, 7100, 1065, 6035, 3200, 3900),
            ["t3", "t4", "t5"],
            id="2026-09-30",
        ),
        pytest.param(
            "2026-10-01", summary(2, 3900, 585, 3315, 1500, 2400), ["t1", "t2"], id="2026-10-01"
        ),
        pytest.param(
            "2026-10-02",
            summary(3, 8540, 1281, 7259, 2700, 5840),
            ["t6", "t7", "t8"],
            id="2026-10-02",
        ),
        pytest.param("2026-10-03", summary(1, 1500, 225, 1275, 1500, 0), ["t9"], id="2026-10-03"),
    ],
)
async def test_seed_day_matches_data_readme(
    client: AsyncClient, day: str, expected_summary: dict[str, Any], trip_ids: list[str]
) -> None:
    body = await get_day(client, day)

    assert body["summary"] == expected_summary
    assert [trip["id"] for trip in body["trips"]] == trip_ids


@pytest.mark.parametrize("day", ["2026-10-04", "0001-01-02", "9999-12-30"])
async def test_day_without_trips_is_all_zeros(client: AsyncClient, day: str) -> None:
    assert await get_day(client, day) == {
        "date": day,
        "timezone": "Asia/Almaty",
        "summary": summary(0, 0, 0, 0, 0, 0),
        "trips": [],
    }


def trip_starting_at(trip_id: str, start: str) -> Trip:
    moment = datetime.fromisoformat(start)
    return Trip(
        id=trip_id,
        start=moment,
        end=moment + timedelta(minutes=20),
        amount=1000,
        payment=PaymentMethod.CASH,
        commission=150,
    )


async def test_day_runs_from_almaty_midnight_to_the_next(
    client: AsyncClient, connection: Connection
) -> None:
    for trip in [
        trip_starting_at("next-midnight", "2026-10-10T19:00:00Z"),
        trip_starting_at("last-microsecond", "2026-10-10T18:59:59.999999Z"),
        trip_starting_at("across-midnight", "2026-10-10T18:50:00Z"),
        trip_starting_at("half-past-midnight", "2026-10-09T19:30:00Z"),
        trip_starting_at("midnight", "2026-10-09T19:00:00Z"),
        trip_starting_at("previous-day", "2026-10-09T18:59:59.999999Z"),
    ]:
        await repository.insert_if_absent(connection, trip)

    body = await get_day(client, "2026-10-10")

    assert [(trip["id"], trip["start"]) for trip in body["trips"]] == [
        ("midnight", "2026-10-10T00:00:00+05:00"),
        ("half-past-midnight", "2026-10-10T00:30:00+05:00"),
        ("across-midnight", "2026-10-10T23:50:00+05:00"),
        ("last-microsecond", "2026-10-10T23:59:59.999999+05:00"),
    ]


@pytest.mark.parametrize(
    "day",
    [
        "2026-13-01",
        "2026-02-30",
        "2026-10-1",
        "01.10.2026",
        "today",
        "2026-10-01T00:00:00+05:00",
        "1790812800",
    ],
)
async def test_malformed_date_is_rejected(client: AsyncClient, day: str) -> None:
    response = await client.get(f"/api/v1/days/{day}")

    assert response.status_code == 422
    assert [error["loc"] for error in response.json()["detail"]] == [["path", "date"]]


@pytest.mark.parametrize("day", ["0001-01-01", "9999-12-31"])
async def test_day_without_a_midnight_on_one_side_is_rejected(
    client: AsyncClient, day: str
) -> None:
    response = await client.get(f"/api/v1/days/{day}")

    assert response.status_code == 422
    assert response.json()["detail"] == [
        {
            "type": "date_out_of_range",
            "loc": ["path", "date"],
            "msg": "Date should be between 0001-01-02 and 9999-12-30",
            "input": day,
        }
    ]
