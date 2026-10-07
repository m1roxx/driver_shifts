from datetime import date, timedelta
from typing import Any

import pytest
from httpx import AsyncClient

from app.database import Connection
from app.trips import repository
from tests.integration.test_days_api import summary, trip_starting_at

EMPTY = summary(0, 0, 0, 0, 0, 0)
NO_STATS = {"average_trip": None, "net_per_hour": None, "best_day": None}


async def get_period(client: AsyncClient, start: str, end: str) -> dict[str, Any]:
    response = await client.get(f"/api/v1/periods/{start}/{end}")
    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    return body


async def test_seed_week_matches_data_readme(client: AsyncClient) -> None:
    assert await get_period(client, "2026-09-28", "2026-10-04") == {
        "start": "2026-09-28",
        "end": "2026-10-04",
        "timezone": "Asia/Almaty",
        "summary": summary(9, 21040, 3156, 17884, 8900, 12140),
        "days": [
            {"date": "2026-09-28", "summary": EMPTY},
            {"date": "2026-09-29", "summary": EMPTY},
            {"date": "2026-09-30", "summary": summary(3, 7100, 1065, 6035, 3200, 3900)},
            {"date": "2026-10-01", "summary": summary(2, 3900, 585, 3315, 1500, 2400)},
            {"date": "2026-10-02", "summary": summary(3, 8540, 1281, 7259, 2700, 5840)},
            {"date": "2026-10-03", "summary": summary(1, 1500, 225, 1275, 1500, 0)},
            {"date": "2026-10-04", "summary": EMPTY},
        ],
        "stats": {
            "average_trip": 2338,
            "net_per_hour": 4727,
            "best_day": {"date": "2026-10-02", "net": 7259},
        },
    }


@pytest.mark.parametrize("day", ["2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03"])
async def test_one_day_period_matches_the_day(client: AsyncClient, day: str) -> None:
    period = await get_period(client, day, day)
    day_response = await client.get(f"/api/v1/days/{day}")

    assert period["summary"] == day_response.json()["summary"]
    assert period["days"] == [{"date": day, "summary": day_response.json()["summary"]}]


async def test_period_runs_from_the_first_almaty_midnight_to_the_one_after_the_last_day(
    client: AsyncClient, connection: Connection
) -> None:
    for trip in [
        trip_starting_at("before", "2026-11-09T18:59:59.999999Z"),
        trip_starting_at("first-midnight", "2026-11-09T19:00:00Z"),
        trip_starting_at("last-microsecond", "2026-11-11T18:59:59.999999Z"),
        trip_starting_at("after", "2026-11-11T19:00:00Z"),
    ]:
        await repository.insert_if_absent(connection, trip)

    body = await get_period(client, "2026-11-10", "2026-11-11")

    assert [(day["date"], day["summary"]["trips_count"]) for day in body["days"]] == [
        ("2026-11-10", 1),
        ("2026-11-11", 1),
    ]
    assert body["summary"]["trips_count"] == 2


async def test_longest_period_is_31_days(client: AsyncClient) -> None:
    body = await get_period(client, "2026-10-01", "2026-10-31")

    assert [day["date"] for day in body["days"]] == [
        (date(2026, 10, 1) + timedelta(days=offset)).isoformat() for offset in range(31)
    ]
    assert body["summary"] == summary(6, 13940, 2091, 11849, 5700, 8240)


@pytest.mark.parametrize(
    ("start", "end", "error_type"),
    [
        pytest.param("2026-10-02", "2026-10-01", "period_end_before_start", id="end before start"),
        pytest.param("2026-10-01", "2026-11-01", "period_too_long", id="32 days"),
        pytest.param("0001-01-02", "9999-12-30", "period_too_long", id="whole range"),
    ],
)
async def test_bad_range_is_rejected_at_the_end(
    client: AsyncClient, start: str, end: str, error_type: str
) -> None:
    response = await client.get(f"/api/v1/periods/{start}/{end}")

    assert response.status_code == 422
    assert [(error["loc"], error["type"]) for error in response.json()["detail"]] == [
        (["path", "end"], error_type)
    ]


@pytest.mark.parametrize(
    ("start", "end", "errors"),
    [
        pytest.param(
            "2026-10-1", "2026-10-07", [(["path", "start"], "date_format")], id="short start"
        ),
        pytest.param("2026-10-01", "1790812800", [(["path", "end"], "date_format")], id="unix end"),
        pytest.param(
            "0001-01-01",
            "0001-01-03",
            [(["path", "start"], "date_out_of_range")],
            id="start without a midnight before",
        ),
        pytest.param(
            "9999-12-30",
            "9999-12-31",
            [(["path", "end"], "date_out_of_range")],
            id="end without a midnight after",
        ),
        pytest.param(
            "today",
            "tomorrow",
            [(["path", "start"], "date_format"), (["path", "end"], "date_format")],
            id="both",
        ),
    ],
)
async def test_malformed_dates_are_rejected(
    client: AsyncClient, start: str, end: str, errors: list[tuple[list[str], str]]
) -> None:
    response = await client.get(f"/api/v1/periods/{start}/{end}")

    assert response.status_code == 422
    assert [(error["loc"], error["type"]) for error in response.json()["detail"]] == errors


async def test_edges_of_the_supported_range_are_empty(client: AsyncClient) -> None:
    first = await get_period(client, "0001-01-02", "0001-01-02")
    last = await get_period(client, "9999-12-30", "9999-12-30")

    assert first["summary"] == last["summary"] == EMPTY
    assert first["stats"] == last["stats"] == NO_STATS


async def test_trip_past_midnight_counts_fully_to_its_start_day_in_net_per_hour(
    client: AsyncClient,
) -> None:
    body = await get_period(client, "2026-10-02", "2026-10-02")

    assert body["stats"] == {
        "average_trip": 2847,
        "net_per_hour": 5444,
        "best_day": {"date": "2026-10-02", "net": 7259},
    }
