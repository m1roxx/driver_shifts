from dataclasses import dataclass
from datetime import date
from zoneinfo import ZoneInfo

from app.database import Connection
from app.trips import repository
from app.trips.domain import (
    DayReport,
    PeriodReport,
    Trip,
    day_window,
    period_report,
    period_window,
    same_trip,
    summarize,
)


@dataclass(frozen=True, slots=True)
class Created:
    trip: Trip


@dataclass(frozen=True, slots=True)
class Repeated:
    trip: Trip


@dataclass(frozen=True, slots=True)
class Conflict:
    stored: Trip


class TripsService:
    def __init__(self, connection: Connection, timezone: ZoneInfo) -> None:
        self._connection = connection
        self._timezone = timezone

    async def get_day(self, day: date) -> DayReport:
        start, end = day_window(day, self._timezone)
        trips = tuple(await repository.list_between(self._connection, start, end))
        return DayReport(day=day, timezone=self._timezone, trips=trips, summary=summarize(trips))

    async def get_period(self, start: date, end: date) -> PeriodReport:
        window_start, window_end = period_window(start, end, self._timezone)
        trips = await repository.list_between(self._connection, window_start, window_end)
        return period_report(trips, start, end, self._timezone)

    async def create_trip(self, trip: Trip) -> Created | Repeated | Conflict:
        stored = await repository.insert_if_absent(self._connection, trip)
        if stored is None:
            return Created(trip)
        if same_trip(stored, trip):
            return Repeated(stored)
        return Conflict(stored)
