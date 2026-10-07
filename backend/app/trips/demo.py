import logging
from collections.abc import Collection, Iterable
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from app.trips.domain import PaymentMethod, Trip
from app.trips.schemas import TripCreate
from app.trips.service import Conflict, TripsService

logger = logging.getLogger(__name__)

COMMISSION_PERCENT = 15

CASH = PaymentMethod.CASH
CARD = PaymentMethod.CARD


@dataclass(frozen=True, slots=True)
class Ride:
    start: time
    minutes: int
    amount: int
    payment: PaymentMethod


def _ride(start: str, minutes: int, amount: int, payment: PaymentMethod) -> Ride:
    return Ride(time.fromisoformat(start), minutes, amount, payment)


# Amounts are multiples of 20, so a 15% commission is a whole number of tenge.
SHIFTS: tuple[tuple[Ride, ...], ...] = (
    (
        _ride("07:40", 25, 2200, CARD),
        _ride("08:30", 18, 1600, CASH),
        _ride("09:15", 32, 3100, CARD),
        _ride("10:20", 15, 1240, CASH),
    ),
    (
        _ride("11:05", 22, 1900, CARD),
        _ride("12:00", 35, 3400, CARD),
        _ride("13:10", 14, 1100, CASH),
        _ride("14:30", 27, 2600, CARD),
        _ride("15:45", 20, 1800, CASH),
    ),
    (
        _ride("19:20", 24, 2300, CASH),
        _ride("21:00", 30, 2900, CARD),
        _ride("23:45", 35, 4200, CARD),
    ),
    (
        _ride("07:15", 20, 1700, CASH),
        _ride("08:05", 28, 2500, CARD),
        _ride("09:00", 16, 1400, CARD),
        _ride("17:30", 33, 3000, CASH),
        _ride("18:40", 21, 1960, CARD),
        _ride("19:50", 26, 2400, CASH),
    ),
    (
        _ride("00:20", 25, 2800, CASH),
        _ride("01:10", 20, 2100, CARD),
        _ride("06:50", 18, 1500, CASH),
        _ride("16:10", 30, 2700, CARD),
    ),
)


def days_of(trips: Iterable[Trip], timezone: ZoneInfo) -> frozenset[date]:
    return frozenset(trip.start.astimezone(timezone).date() for trip in trips)


def demo_trips(
    now: datetime, timezone: ZoneInfo, days: int, skip_days: Collection[date]
) -> list[Trip]:
    today = now.astimezone(timezone).date()
    trips: list[Trip] = []
    for days_ago in range(days - 1, -1, -1):
        day = today - timedelta(days=days_ago)
        if day not in skip_days:
            trips.extend(trip for trip in _day_trips(day, timezone) if trip.end <= now)
    return trips


def _day_trips(day: date, timezone: ZoneInfo) -> list[Trip]:
    shift = SHIFTS[day.toordinal() % len(SHIFTS)]
    return [_trip(day, number, ride, timezone) for number, ride in enumerate(shift, start=1)]


def _trip(day: date, number: int, ride: Ride, timezone: ZoneInfo) -> Trip:
    start = datetime.combine(day, ride.start, tzinfo=timezone)
    end = (start.astimezone(UTC) + timedelta(minutes=ride.minutes)).astimezone(timezone)
    return TripCreate.model_validate(
        {
            "id": f"demo-{day.isoformat()}-{number}",
            "start": start.isoformat(),
            "end": end.isoformat(),
            "amount": ride.amount,
            "payment": ride.payment.value,
            "commission": ride.amount * COMMISSION_PERCENT // 100,
        }
    ).to_domain()


async def load_trips(service: TripsService, trips: Iterable[Trip]) -> None:
    for trip in trips:
        if isinstance(await service.create_trip(trip), Conflict):
            logger.warning("demo trip %s is already stored with other data, skipped", trip.id)
