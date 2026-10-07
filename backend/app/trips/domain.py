from collections.abc import Sequence
from dataclasses import dataclass, replace
from datetime import UTC, date, datetime, time, timedelta
from enum import StrEnum
from zoneinfo import ZoneInfo


class PaymentMethod(StrEnum):
    CASH = "cash"
    CARD = "card"


@dataclass(frozen=True, slots=True, kw_only=True)
class Trip:
    id: str
    start: datetime
    end: datetime
    amount: int
    payment: PaymentMethod
    commission: int


@dataclass(frozen=True, slots=True, kw_only=True)
class DaySummary:
    trips_count: int
    revenue: int
    commission: int
    net: int
    cash: int
    card: int


@dataclass(frozen=True, slots=True, kw_only=True)
class DayReport:
    day: date
    timezone: ZoneInfo
    trips: tuple[Trip, ...]
    summary: DaySummary


@dataclass(frozen=True, slots=True, kw_only=True)
class DayTotal:
    day: date
    summary: DaySummary


@dataclass(frozen=True, slots=True, kw_only=True)
class PeriodReport:
    start: date
    end: date
    timezone: ZoneInfo
    summary: DaySummary
    days: tuple[DayTotal, ...]


def summarize(trips: Sequence[Trip]) -> DaySummary:
    revenue = sum(trip.amount for trip in trips)
    commission = sum(trip.commission for trip in trips)
    return DaySummary(
        trips_count=len(trips),
        revenue=revenue,
        commission=commission,
        net=revenue - commission,
        cash=sum(trip.amount for trip in trips if trip.payment is PaymentMethod.CASH),
        card=sum(trip.amount for trip in trips if trip.payment is PaymentMethod.CARD),
    )


def day_window(day: date, timezone: ZoneInfo) -> tuple[datetime, datetime]:
    start = datetime.combine(day, time.min, tzinfo=timezone)
    end = datetime.combine(day + timedelta(days=1), time.min, tzinfo=timezone)
    return start.astimezone(UTC), end.astimezone(UTC)


def period_window(start: date, end: date, timezone: ZoneInfo) -> tuple[datetime, datetime]:
    return day_window(start, timezone)[0], day_window(end, timezone)[1]


def days_of_period(start: date, end: date) -> list[date]:
    return [start + timedelta(days=offset) for offset in range((end - start).days + 1)]


def group_by_day(
    trips: Sequence[Trip], start: date, end: date, timezone: ZoneInfo
) -> dict[date, tuple[Trip, ...]]:
    groups: dict[date, tuple[Trip, ...]] = {}
    for day in days_of_period(start, end):
        day_start, day_end = day_window(day, timezone)
        groups[day] = tuple(trip for trip in trips if day_start <= trip.start < day_end)
    return groups


def period_report(
    trips: Sequence[Trip], start: date, end: date, timezone: ZoneInfo
) -> PeriodReport:
    groups = group_by_day(trips, start, end, timezone)
    return PeriodReport(
        start=start,
        end=end,
        timezone=timezone,
        summary=summarize([trip for day_trips in groups.values() for trip in day_trips]),
        days=tuple(
            DayTotal(day=day, summary=summarize(day_trips)) for day, day_trips in groups.items()
        ),
    )


def same_trip(a: Trip, b: Trip) -> bool:
    return _in_utc(a) == _in_utc(b)


def _in_utc(trip: Trip) -> Trip:
    return replace(trip, start=trip.start.astimezone(UTC), end=trip.end.astimezone(UTC))
