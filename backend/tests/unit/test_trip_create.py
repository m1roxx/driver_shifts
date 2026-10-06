from typing import Any

import pytest
from pydantic import ValidationError

from app.trips.schemas import TripCreate
from tests.seed_trips import T1, T1_JSON


def errors(data: dict[str, Any]) -> list[tuple[tuple[int | str, ...], str]]:
    with pytest.raises(ValidationError) as raised:
        TripCreate.model_validate(data)
    return [(error["loc"], error["type"]) for error in raised.value.errors()]


def test_task_example_becomes_a_domain_trip() -> None:
    assert TripCreate.model_validate(T1_JSON).to_domain() == T1


@pytest.mark.parametrize(
    "change",
    [
        pytest.param({"id": "A-z_09" * 10 + "abcd"}, id="64-character id"),
        pytest.param({"start": "2026-10-01T03:10:00Z", "end": "2026-10-01T03:32:00Z"}, id="utc"),
        pytest.param({"commission": 0}, id="no commission"),
        pytest.param({"commission": 2400}, id="commission equals amount"),
        pytest.param({"amount": 2_147_483_647}, id="largest postgres integer"),
    ],
)
def test_accepts_edge_values(change: dict[str, Any]) -> None:
    TripCreate.model_validate(T1_JSON | change)


@pytest.mark.parametrize(
    ("field", "value", "error_type"),
    [
        pytest.param("id", "", "string_too_short", id="empty id"),
        pytest.param("id", "t" * 65, "string_too_long", id="long id"),
        pytest.param("id", "t 1", "string_pattern_mismatch", id="space in id"),
        pytest.param("id", "т1", "string_pattern_mismatch", id="cyrillic id"),
        pytest.param("id", 1, "string_type", id="numeric id"),
        pytest.param("start", "2026-10-01T08:10:00", "timezone_aware", id="no offset"),
        pytest.param("start", "2026-10-01", "timezone_aware", id="date only"),
        pytest.param("start", 1790824200, "datetime_format", id="unix time"),
        pytest.param("start", "1790824200", "datetime_format", id="unix time string"),
        pytest.param("start", "08:10", "datetime_format", id="time only"),
        pytest.param("end", "2026-10-01T08:10:00+05:00", "end_not_after_start", id="end at start"),
        pytest.param("end", "2026-10-01T03:09:00Z", "end_not_after_start", id="end before start"),
        pytest.param("amount", 0, "greater_than", id="zero amount"),
        pytest.param("amount", -2400, "greater_than", id="negative amount"),
        pytest.param("amount", 2_147_483_648, "less_than_equal", id="amount above integer"),
        pytest.param("amount", 2400.5, "int_type", id="fractional amount"),
        pytest.param("amount", 2400.0, "int_type", id="float amount"),
        pytest.param("amount", "2400", "int_type", id="string amount"),
        pytest.param("payment", "crypto", "enum", id="unknown payment"),
        pytest.param("payment", "CARD", "enum", id="uppercase payment"),
        pytest.param("commission", -1, "greater_than_equal", id="negative commission"),
        pytest.param("commission", 2401, "commission_above_amount", id="commission above amount"),
    ],
)
def test_rejects_invalid_field(field: str, value: Any, error_type: str) -> None:
    assert errors(T1_JSON | {field: value}) == [((field,), error_type)]


def test_rejects_unknown_fields() -> None:
    assert errors(T1_JSON | {"driver": "me"}) == [(("driver",), "extra_forbidden")]


def test_requires_every_field() -> None:
    assert errors({}) == [((field,), "missing") for field in T1_JSON]
