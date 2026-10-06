from datetime import UTC, date, datetime, timedelta

import pytest
from hypothesis import given
from hypothesis import strategies as st

from app.trips.domain import day_window
from tests.seed_trips import ALMATY, T6, T8


@pytest.mark.parametrize(
    ("moment", "offset"),
    [
        pytest.param(datetime(2024, 2, 28, 12, tzinfo=ALMATY), 6, id="before 2024-03-01"),
        pytest.param(datetime(2024, 3, 1, tzinfo=ALMATY), 5, id="since 2024-03-01"),
        pytest.param(datetime(2026, 10, 1, tzinfo=ALMATY), 5, id="2026-10-01"),
    ],
)
def test_almaty_offset_follows_the_2024_switch_to_utc_plus_5(moment: datetime, offset: int) -> None:
    assert moment.utcoffset() == timedelta(hours=offset)


def test_day_runs_from_almaty_midnight_to_the_next_in_utc() -> None:
    assert day_window(date(2026, 10, 1), ALMATY) == (
        datetime(2026, 9, 30, 19, tzinfo=UTC),
        datetime(2026, 10, 1, 19, tzinfo=UTC),
    )


def in_window(moment: datetime, day: date) -> bool:
    start, end = day_window(day, ALMATY)
    return start <= moment < end


def test_trip_at_half_past_midnight_belongs_to_its_own_day() -> None:
    assert in_window(T6.start, date(2026, 10, 2))
    assert not in_window(T6.start, date(2026, 10, 1))


def test_trip_across_midnight_belongs_to_the_day_it_started() -> None:
    assert in_window(T8.start, date(2026, 10, 2))
    assert not in_window(T8.start, date(2026, 10, 3))


moments = st.timedeltas(min_value=timedelta(days=-20_000), max_value=timedelta(days=20_000)).map(
    lambda delta: datetime(2026, 10, 1, tzinfo=UTC) + delta
)


@given(moments)
def test_every_moment_falls_into_the_day_of_its_almaty_date(moment: datetime) -> None:
    assert in_window(moment, moment.astimezone(ALMATY).date())


@given(st.dates(min_value=date(1970, 1, 1), max_value=date(2100, 1, 1)))
def test_consecutive_days_share_a_boundary(day: date) -> None:
    assert day_window(day, ALMATY)[1] == day_window(day + timedelta(days=1), ALMATY)[0]
