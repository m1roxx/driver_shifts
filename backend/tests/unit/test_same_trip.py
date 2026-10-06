from dataclasses import replace
from datetime import UTC, timedelta
from typing import Any

import pytest

from app.trips.domain import PaymentMethod, same_trip
from tests.seed_trips import T1


def test_same_moments_in_another_offset_are_the_same_trip() -> None:
    in_utc = replace(T1, start=T1.start.astimezone(UTC), end=T1.end.astimezone(UTC))

    assert same_trip(T1, in_utc)


@pytest.mark.parametrize(
    "change",
    [
        pytest.param({"start": T1.start - timedelta(minutes=1)}, id="start"),
        pytest.param({"end": T1.end + timedelta(minutes=1)}, id="end"),
        pytest.param({"amount": T1.amount + 1}, id="amount"),
        pytest.param({"payment": PaymentMethod.CASH}, id="payment"),
        pytest.param({"commission": T1.commission + 1}, id="commission"),
    ],
)
def test_any_other_difference_makes_another_trip(change: dict[str, Any]) -> None:
    assert not same_trip(T1, replace(T1, **change))
