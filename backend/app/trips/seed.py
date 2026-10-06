from collections.abc import Iterable
from pathlib import Path

from pydantic import TypeAdapter

from app.trips.domain import Trip
from app.trips.schemas import TripCreate
from app.trips.service import Conflict, TripsService

_TRIPS = TypeAdapter(list[TripCreate])


class SeedConflictError(Exception):
    pass


def read_trips(path: Path) -> list[Trip]:
    return [trip.to_domain() for trip in _TRIPS.validate_json(path.read_bytes())]


async def load_trips(service: TripsService, trips: Iterable[Trip]) -> None:
    for trip in trips:
        if isinstance(await service.create_trip(trip), Conflict):
            raise SeedConflictError(f"trip {trip.id} is already stored with other data")
