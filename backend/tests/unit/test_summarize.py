from datetime import datetime, timedelta, timezone

import pytest
from hypothesis import given
from hypothesis import strategies as st

from app.trips.domain import DaySummary, PaymentMethod, Trip, summarize
from tests.seed_trips import T1, T2, T3, T4, T5, T6, T7, T8, T9

DAY_START = datetime(2026, 10, 1, tzinfo=timezone(timedelta(hours=5)))


def test_task_example() -> None:
    assert summarize([T1, T2]) == DaySummary(
        trips_count=2, revenue=3900, commission=585, net=3315, cash=1500, card=2400
    )


def test_empty_day_is_all_zeros() -> None:
    assert summarize([]) == DaySummary(
        trips_count=0, revenue=0, commission=0, net=0, cash=0, card=0
    )


@pytest.mark.parametrize(
    ("trips", "expected"),
    [
        pytest.param(
            [T3, T4, T5],
            DaySummary(
                trips_count=3, revenue=7100, commission=1065, net=6035, cash=3200, card=3900
            ),
            id="2026-09-30",
        ),
        pytest.param(
            [T6, T7, T8],
            DaySummary(
                trips_count=3, revenue=8540, commission=1281, net=7259, cash=2700, card=5840
            ),
            id="2026-10-02",
        ),
        pytest.param(
            [T9],
            DaySummary(trips_count=1, revenue=1500, commission=225, net=1275, cash=1500, card=0),
            id="2026-10-03",
        ),
    ],
)
def test_seed_day_matches_data_readme(trips: list[Trip], expected: DaySummary) -> None:
    assert summarize(trips) == expected


@st.composite
def valid_trips(draw: st.DrawFn) -> Trip:
    amount = draw(st.integers(min_value=1, max_value=1_000_000))
    start = DAY_START + draw(st.timedeltas(min_value=timedelta(0), max_value=timedelta(hours=23)))
    duration = draw(st.timedeltas(min_value=timedelta(minutes=1), max_value=timedelta(hours=3)))
    return Trip(
        id=str(draw(st.uuids())),
        start=start,
        end=start + duration,
        amount=amount,
        payment=draw(st.sampled_from(PaymentMethod)),
        commission=draw(st.integers(min_value=0, max_value=amount)),
    )


day_trips = st.lists(valid_trips(), max_size=30)


@given(day_trips)
def test_cash_plus_card_is_revenue(trips: list[Trip]) -> None:
    summary = summarize(trips)

    assert summary.cash + summary.card == summary.revenue


@given(day_trips)
def test_net_is_revenue_minus_commission(trips: list[Trip]) -> None:
    summary = summarize(trips)

    assert summary.net == summary.revenue - summary.commission


@given(day_trips)
def test_trips_count_is_list_length(trips: list[Trip]) -> None:
    assert summarize(trips).trips_count == len(trips)
