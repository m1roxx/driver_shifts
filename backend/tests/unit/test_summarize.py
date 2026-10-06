from datetime import datetime, timedelta, timezone

import pytest
from hypothesis import given
from hypothesis import strategies as st

from app.trips.domain import DaySummary, PaymentMethod, Trip, summarize

CASH = PaymentMethod.CASH
CARD = PaymentMethod.CARD
DAY_START = datetime(2026, 10, 1, tzinfo=timezone(timedelta(hours=5)))


def trip(
    trip_id: str, start: str, end: str, amount: int, payment: PaymentMethod, commission: int
) -> Trip:
    return Trip(
        id=trip_id,
        start=datetime.fromisoformat(start),
        end=datetime.fromisoformat(end),
        amount=amount,
        payment=payment,
        commission=commission,
    )


T1 = trip("t1", "2026-10-01T08:10:00+05:00", "2026-10-01T08:32:00+05:00", 2400, CARD, 360)
T2 = trip("t2", "2026-10-01T09:05:00+05:00", "2026-10-01T09:20:00+05:00", 1500, CASH, 225)
T3 = trip("t3", "2026-09-30T18:40:00+05:00", "2026-09-30T19:05:00+05:00", 1800, CARD, 270)
T4 = trip("t4", "2026-09-30T19:30:00+05:00", "2026-09-30T20:10:00+05:00", 3200, CASH, 480)
T5 = trip("t5", "2026-09-30T21:15:00+05:00", "2026-09-30T21:40:00+05:00", 2100, CARD, 315)
T6 = trip("t6", "2026-10-02T00:30:00+05:00", "2026-10-02T00:55:00+05:00", 2700, CASH, 405)
T7 = trip("t7", "2026-10-02T12:10:00+05:00", "2026-10-02T12:35:00+05:00", 1240, CARD, 186)
T8 = trip("t8", "2026-10-02T23:50:00+05:00", "2026-10-03T00:20:00+05:00", 4600, CARD, 690)
T9 = trip("t9", "2026-10-03T07:45:00+05:00", "2026-10-03T08:05:00+05:00", 1500, CASH, 225)


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
