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


def same_trip(a: Trip, b: Trip) -> bool:
    return _in_utc(a) == _in_utc(b)


def _in_utc(trip: Trip) -> Trip:
    return replace(trip, start=trip.start.astimezone(UTC), end=trip.end.astimezone(UTC))
