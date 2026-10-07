from collections import Counter
from datetime import UTC, date, datetime, timedelta

from hypothesis import given
from hypothesis import strategies as st

from app.trips.demo import COMMISSION_PERCENT, SHIFTS, days_of, demo_trips
from app.trips.domain import PaymentMethod, Trip
from tests.seed_trips import ALMATY, SEED_TRIPS

NOW = datetime(2026, 10, 7, 10, 0, tzinfo=ALMATY)
TODAY = date(2026, 10, 7)
SEED_DAYS = days_of(SEED_TRIPS, ALMATY)


def day_of(trip: Trip) -> date:
    return trip.start.astimezone(ALMATY).date()


def trips_by_day(trips: list[Trip]) -> Counter[date]:
    return Counter(day_of(trip) for trip in trips)


def test_seed_days_are_the_days_of_trip_starts_in_almaty() -> None:
    assert sorted(SEED_DAYS) == [
        date(2026, 9, 30),
        date(2026, 10, 1),
        date(2026, 10, 2),
        date(2026, 10, 3),
    ]


def test_zero_days_is_no_trips() -> None:
    assert demo_trips(NOW, ALMATY, 0, frozenset()) == []


def test_same_moment_gives_the_same_trips() -> None:
    assert demo_trips(NOW, ALMATY, 14, SEED_DAYS) == demo_trips(NOW, ALMATY, 14, SEED_DAYS)


def test_a_later_moment_keeps_every_trip_already_generated() -> None:
    earlier = demo_trips(NOW, ALMATY, 14, SEED_DAYS)
    later = {trip.id: trip for trip in demo_trips(NOW + timedelta(hours=10), ALMATY, 14, SEED_DAYS)}

    assert all(later[trip.id] == trip for trip in earlier)


def test_ids_are_unique_and_name_the_day_and_the_ride() -> None:
    trips = demo_trips(NOW, ALMATY, 14, frozenset())

    assert len({trip.id for trip in trips}) == len(trips)
    for trip in trips:
        day, number = trip.id.removeprefix("demo-").rsplit("-", 1)
        assert day == day_of(trip).isoformat()
        assert 1 <= int(number) <= 6


def test_covers_the_last_days_up_to_today() -> None:
    days = trips_by_day(demo_trips(NOW, ALMATY, 3, frozenset()))

    assert set(days) <= {TODAY - timedelta(days=2), TODAY - timedelta(days=1), TODAY}
    assert 3 <= days[TODAY - timedelta(days=2)] <= 6
    assert 3 <= days[TODAY - timedelta(days=1)] <= 6


def test_skips_the_given_days() -> None:
    days = trips_by_day(demo_trips(NOW, ALMATY, 14, SEED_DAYS))

    assert set(days).isdisjoint(SEED_DAYS)
    assert days[date(2026, 9, 29)] > 0
    assert days[date(2026, 10, 4)] > 0


def test_today_has_only_trips_that_have_ended() -> None:
    whole_today = [
        trip
        for trip in demo_trips(NOW + timedelta(days=2), ALMATY, 3, frozenset())
        if day_of(trip) == TODAY
    ]
    for moment in (NOW.replace(hour=0), NOW, NOW.replace(hour=23)):
        ended = [trip for trip in whole_today if trip.end <= moment]
        assert demo_trips(moment, ALMATY, 1, frozenset()) == ended

    half_past_noon = NOW.replace(hour=12, minute=30)
    assert [trip.id for trip in demo_trips(half_past_noon, ALMATY, 1, frozenset())] == [
        "demo-2026-10-07-1"
    ]
    assert len(whole_today) == 5


def test_a_trip_past_midnight_belongs_to_the_day_it_starts() -> None:
    trips = demo_trips(NOW, ALMATY, 14, frozenset())
    past_midnight = [trip for trip in trips if trip.end.astimezone(ALMATY).date() != day_of(trip)]

    assert past_midnight
    assert all(trip.id.startswith(f"demo-{day_of(trip).isoformat()}-") for trip in past_midnight)


def test_times_carry_the_driver_offset() -> None:
    for trip in demo_trips(NOW, ALMATY, 14, frozenset()):
        assert trip.start.utcoffset() == timedelta(hours=5)
        assert trip.end.utcoffset() == timedelta(hours=5)


def test_money_is_whole_tenge_with_a_15_percent_commission() -> None:
    trips = demo_trips(NOW, ALMATY, 14, frozenset())

    for trip in trips:
        assert trip.commission * 100 == trip.amount * COMMISSION_PERCENT
    assert {trip.payment for trip in trips} == {PaymentMethod.CASH, PaymentMethod.CARD}


def test_every_shift_has_three_to_six_rides_and_mixes_payments() -> None:
    for shift in SHIFTS:
        assert 3 <= len(shift) <= 6
        assert {ride.payment for ride in shift} == {PaymentMethod.CASH, PaymentMethod.CARD}
        assert [ride.start for ride in shift] == sorted(ride.start for ride in shift)


@given(
    now=st.integers(min_value=0, max_value=100 * 366 * 24 * 3600).map(
        lambda seconds: datetime(2000, 1, 1, tzinfo=UTC) + timedelta(seconds=seconds)
    ),
    days=st.integers(min_value=0, max_value=31),
    skip_days=st.frozensets(
        st.dates(min_value=date(1999, 12, 1), max_value=date(2100, 1, 2)), max_size=10
    ),
)
def test_any_moment_gives_ended_trips_inside_the_window(
    now: datetime, days: int, skip_days: frozenset[date]
) -> None:
    today = now.astimezone(ALMATY).date()
    trips = demo_trips(now, ALMATY, days, skip_days)

    assert len({trip.id for trip in trips}) == len(trips)
    for trip in trips:
        assert trip.end <= now
        assert today - timedelta(days=days) < day_of(trip) <= today
        assert day_of(trip) not in skip_days
