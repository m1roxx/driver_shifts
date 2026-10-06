from typing import Any

import pytest
from httpx import ASGITransport, AsyncClient, Response
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.database import Connection
from tests.seed_trips import SEED_TRIPS, T1, T1_JSON

TRIPS = "/api/v1/trips"
NEW_ID = "0199b4a2-3c1d-7e8f-9a0b-1c2d3e4f5a6b"
NEW_TRIP = {
    "id": NEW_ID,
    "start": "2026-10-01T18:40:00+05:00",
    "end": "2026-10-01T19:05:00+05:00",
    "amount": 1000,
    "payment": "cash",
    "commission": 150,
}


async def stored_rows(connection: Connection, trip_id: str) -> list[tuple[Any, ...]]:
    cursor = await connection.execute(
        """
        SELECT id, started_at, ended_at, amount, payment, commission
        FROM trips
        WHERE id = %s
        """,
        (trip_id,),
    )
    return await cursor.fetchall()


async def stored_ids(connection: Connection) -> list[str]:
    cursor = await connection.execute("SELECT id FROM trips ORDER BY id")
    return [row[0] for row in await cursor.fetchall()]


async def test_new_trip_is_created_and_counted_in_its_day(client: AsyncClient) -> None:
    response = await client.post(TRIPS, json=NEW_TRIP)

    assert response.status_code == 201
    assert response.json() == NEW_TRIP

    day = (await client.get("/api/v1/days/2026-10-01")).json()
    assert [trip["id"] for trip in day["trips"]] == ["t1", "t2", NEW_ID]
    assert day["summary"] == {
        "trips_count": 3,
        "revenue": 4900,
        "commission": 735,
        "net": 4165,
        "by_payment": {"cash": 2500, "card": 2400},
    }


async def test_trip_is_committed_before_the_response_is_sent(
    app: ASGIApp, connection: Connection
) -> None:
    # ASGITransport returns only when the app is done, so a GET after the POST would pass even
    # if the commit came after the response. The rows are counted as the response starts instead.
    rows_when_answered: list[int] = []

    async def app_counting_rows(scope: Scope, receive: Receive, send: Send) -> None:
        async def count_rows_then_send(message: Message) -> None:
            if message["type"] == "http.response.start":
                rows_when_answered.append(len(await stored_rows(connection, NEW_ID)))
            await send(message)

        await app(scope, receive, count_rows_then_send)

    async with AsyncClient(
        transport=ASGITransport(app=app_counting_rows), base_url="http://test"
    ) as client:
        response = await client.post(TRIPS, json=NEW_TRIP)

    assert response.status_code == 201
    assert rows_when_answered == [1]


async def test_repeat_returns_the_stored_trip_and_keeps_one_row(
    client: AsyncClient, connection: Connection
) -> None:
    first = await client.post(TRIPS, json=NEW_TRIP)
    repeat = await client.post(TRIPS, json=NEW_TRIP)

    assert (first.status_code, repeat.status_code) == (201, 200)
    assert repeat.json() == first.json() == NEW_TRIP
    assert len(await stored_rows(connection, NEW_ID)) == 1


@pytest.mark.parametrize(
    ("start", "end"),
    [
        pytest.param("2026-10-01T13:40:00Z", "2026-10-01T14:05:00Z", id="utc"),
        pytest.param("2026-10-01T09:40:00-04:00", "2026-10-01T10:05:00-04:00", id="utc-4"),
    ],
)
async def test_same_moments_in_another_offset_are_a_repeat(
    client: AsyncClient, connection: Connection, start: str, end: str
) -> None:
    await client.post(TRIPS, json=NEW_TRIP)

    repeat = await client.post(TRIPS, json=NEW_TRIP | {"start": start, "end": end})

    assert repeat.status_code == 200
    assert repeat.json() == NEW_TRIP
    assert len(await stored_rows(connection, NEW_ID)) == 1


async def test_other_data_under_a_stored_id_is_a_conflict(
    client: AsyncClient, connection: Connection
) -> None:
    response = await client.post(TRIPS, json=T1_JSON | {"amount": 2500})

    assert response.status_code == 409
    assert response.json() == {
        "detail": {
            "code": "trip_conflict",
            "message": "Поездка с id t1 уже сохранена с другими данными",  # noqa: RUF001
        }
    }
    assert await stored_rows(connection, T1.id) == [
        (T1.id, T1.start, T1.end, T1.amount, T1.payment.value, T1.commission)
    ]


def errors(response: Response) -> list[tuple[list[str | int], str]]:
    assert response.status_code == 422
    detail: list[dict[str, Any]] = response.json()["detail"]
    assert all(isinstance(error["msg"], str) for error in detail)
    return [(error["loc"], error["type"]) for error in detail]


@pytest.mark.parametrize(
    ("field", "value", "error_type"),
    [
        pytest.param("id", 1, "string_type", id="numeric id"),
        pytest.param("id", "", "string_too_short", id="empty id"),
        pytest.param("id", "t" * 65, "string_too_long", id="id over 64 characters"),
        pytest.param("id", "t 1", "string_pattern_mismatch", id="space in id"),
        pytest.param("start", "2026-10-01T18:40:00", "timezone_aware", id="start without offset"),
        pytest.param("end", "2026-10-01T19:05:00", "timezone_aware", id="end without offset"),
        pytest.param("start", "1790862000", "datetime_format", id="unix time"),
        pytest.param(
            "start", "0001-01-01T00:30:00+05:00", "datetime_out_of_range", id="start in year 0"
        ),
        pytest.param("end", NEW_TRIP["start"], "end_not_after_start", id="end at start"),
        pytest.param(
            "end", "2026-10-01T18:39:00+05:00", "end_not_after_start", id="end before start"
        ),
        pytest.param("amount", 0, "greater_than", id="zero amount"),
        pytest.param("amount", -1000, "greater_than", id="negative amount"),
        pytest.param("amount", 1000.5, "int_type", id="fractional amount"),
        pytest.param("amount", "1000", "int_type", id="amount as a string"),
        pytest.param("amount", 2_147_483_648, "less_than_equal", id="amount above integer"),
        pytest.param("commission", -1, "greater_than_equal", id="negative commission"),
        pytest.param("commission", 150.5, "int_type", id="fractional commission"),
        pytest.param("commission", 1001, "commission_above_amount", id="commission above amount"),
        pytest.param("payment", "crypto", "enum", id="unknown payment"),
        pytest.param("driver", "me", "extra_forbidden", id="unknown field"),
    ],
)
async def test_invalid_trip_is_rejected_on_its_field(
    client: AsyncClient, connection: Connection, field: str, value: Any, error_type: str
) -> None:
    response = await client.post(TRIPS, json=NEW_TRIP | {field: value})

    assert errors(response) == [(["body", field], error_type)]
    assert await stored_ids(connection) == sorted(trip.id for trip in SEED_TRIPS)


async def test_every_field_is_required(client: AsyncClient) -> None:
    response = await client.post(TRIPS, json={})

    assert errors(response) == [(["body", field], "missing") for field in NEW_TRIP]


async def test_openapi_documents_every_answer(client: AsyncClient) -> None:
    openapi = (await client.get("/openapi.json")).json()

    assert sorted(openapi["paths"][TRIPS]["post"]["responses"]) == ["200", "201", "409", "422"]
