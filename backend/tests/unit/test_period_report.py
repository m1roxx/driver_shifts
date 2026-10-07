from dataclasses import replace
from datetime import UTC, date, datetime, timedelta

from hypothesis import given
from hypothesis import strategies as st

from app.trips.domain import (
    DaySummary,
    PaymentMethod,
    Trip,
    group_by_day,
    period_report,
    period_window,
    summarize,
)
from tests.seed_trips import ALMATY, SEED_TRIPS, T1, T2, T3, T4, T5, T6, T7, T8, T9

WEEK_START = date(2026, 9, 28)
WEEK_END = date(2026, 10, 4)


def test_period_runs_from_the_first_almaty_midnight_to_the_one_after_the_last_day() -> None:
    assert period_window(WEEK_START, WEEK_END, ALMATY) == (
        datetime(2026, 9, 27, 19, tzinfo=UTC),
        datetime(2026, 10, 4, 19, tzinfo=UTC),
    )


def test_every_day_of_the_period_is_present_in_order_even_without_trips() -> None:
    groups = group_by_day(SEED_TRIPS, WEEK_START, WEEK_END, ALMATY)

    assert list(groups.items()) == [
        (date(2026, 9, 28), ()),
        (date(2026, 9, 29), ()),
        (date(2026, 9, 30), (T3, T4, T5)),
        (date(2026, 10, 1), (T1, T2)),
        (date(2026, 10, 2), (T6, T7, T8)),
        (date(2026, 10, 3), (T9,)),
        (date(2026, 10, 4), ()),
    ]


def test_trip_at_half_past_midnight_belongs_to_its_own_day() -> None:
    groups = group_by_day([T6], date(2026, 10, 1), date(2026, 10, 2), ALMATY)

    assert groups == {date(2026, 10, 1): (), date(2026, 10, 2): (T6,)}


def test_trip_across_midnight_belongs_to_the_day_it_started() -> None:
    groups = group_by_day([T8], date(2026, 10, 2), date(2026, 10, 3), ALMATY)

    assert groups == {date(2026, 10, 2): (T8,), date(2026, 10, 3): ()}


def test_trip_times_in_another_offset_land_on_the_same_day() -> None:
    in_utc = replace(T6, start=T6.start.astimezone(UTC), end=T6.end.astimezone(UTC))

    assert group_by_day([in_utc], date(2026, 10, 1), date(2026, 10, 2), ALMATY) == {
        date(2026, 10, 1): (),
        date(2026, 10, 2): (in_utc,),
    }


def test_seed_week_matches_data_readme() -> None:
    report = period_report(SEED_TRIPS, WEEK_START, WEEK_END, ALMATY)

    assert [(total.day, total.summary) for total in report.days] == [
        (date(2026, 9, 28), summarize([])),
        (date(2026, 9, 29), summarize([])),
        (
            date(2026, 9, 30),
            DaySummary(
                trips_count=3, revenue=7100, commission=1065, net=6035, cash=3200, card=3900
            ),
        ),
        (
            date(2026, 10, 1),
            DaySummary(trips_count=2, revenue=3900, commission=585, net=3315, cash=1500, card=2400),
        ),
        (
            date(2026, 10, 2),
            DaySummary(
                trips_count=3, revenue=8540, commission=1281, net=7259, cash=2700, card=5840
            ),
        ),
        (
            date(2026, 10, 3),
            DaySummary(trips_count=1, revenue=1500, commission=225, net=1275, cash=1500, card=0),
        ),
        (date(2026, 10, 4), summarize([])),
    ]
    assert report.summary == DaySummary(
        trips_count=9, revenue=21040, commission=3156, net=17884, cash=8900, card=12140
    )
    assert (report.start, report.end, report.timezone) == (WEEK_START, WEEK_END, ALMATY)


def test_period_without_trips_has_every_day_with_zeros() -> None:
    report = period_report([], WEEK_START, WEEK_END, ALMATY)

    assert report.summary == summarize([])
    assert [total.day for total in report.days] == [
        WEEK_START + timedelta(days=offset) for offset in range(7)
    ]
    assert {total.summary for total in report.days} == {summarize([])}


def test_trips_outside_the_period_are_left_out() -> None:
    report = period_report(SEED_TRIPS, date(2026, 10, 1), date(2026, 10, 1), ALMATY)

    assert report.summary == summarize([T1, T2])


@st.composite
def trips_in_period(draw: st.DrawFn) -> tuple[list[Trip], date, date]:
    start = draw(st.dates(min_value=date(2020, 1, 2), max_value=date(2030, 12, 1)))
    end = start + timedelta(days=draw(st.integers(min_value=0, max_value=30)))
    window_start, window_end = period_window(start, end, ALMATY)
    seconds = int((window_end - window_start).total_seconds())
    trips = []
    for number in range(draw(st.integers(min_value=0, max_value=20))):
        moment = window_start + timedelta(seconds=draw(st.integers(0, seconds - 1)))
        amount = draw(st.integers(min_value=1, max_value=100_000))
        trips.append(
            Trip(
                id=f"trip-{number}",
                start=moment,
                end=moment + timedelta(minutes=draw(st.integers(1, 180))),
                amount=amount,
                payment=draw(st.sampled_from(PaymentMethod)),
                commission=draw(st.integers(min_value=0, max_value=amount)),
            )
        )
    return trips, start, end


@given(trips_in_period())
def test_day_summaries_add_up_to_the_period_summary(case: tuple[list[Trip], date, date]) -> None:
    trips, start, end = case

    report = period_report(trips, start, end, ALMATY)

    assert len(report.days) == (end - start).days + 1
    assert report.summary.trips_count == len(trips)
    assert sum(total.summary.trips_count for total in report.days) == len(trips)
    for field in ("revenue", "commission", "net", "cash", "card"):
        day_sum = sum(getattr(total.summary, field) for total in report.days)
        assert day_sum == getattr(report.summary, field)


@given(trips_in_period())
def test_each_trip_lands_on_the_almaty_date_of_its_start(
    case: tuple[list[Trip], date, date],
) -> None:
    trips, start, end = case

    groups = group_by_day(trips, start, end, ALMATY)

    for day, day_trips in groups.items():
        assert all(trip.start.astimezone(ALMATY).date() == day for trip in day_trips)
