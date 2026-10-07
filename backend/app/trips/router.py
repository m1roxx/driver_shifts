from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Response, status

from app.trips.dependencies import DriverTzDep, TripsServiceDep
from app.trips.schemas import (
    ConflictDetailOut,
    ConflictOut,
    DayReportOut,
    IsoDate,
    PeriodReportOut,
    TripCreate,
    TripOut,
    check_period,
)
from app.trips.service import Conflict, Created, Repeated

router = APIRouter()


@router.get("/days/{date}", response_model=DayReportOut)
async def read_day(
    day: Annotated[IsoDate, Path(alias="date")],
    service: TripsServiceDep,
) -> DayReportOut:
    return DayReportOut.from_domain(await service.get_day(day))


async def period_days(
    start: Annotated[IsoDate, Path()], end: Annotated[IsoDate, Path()]
) -> tuple[date, date]:
    check_period(start, end)
    return start, end


@router.get("/periods/{start}/{end}", response_model=PeriodReportOut)
async def read_period(
    days: Annotated[tuple[date, date], Depends(period_days)],
    service: TripsServiceDep,
) -> PeriodReportOut:
    return PeriodReportOut.from_domain(await service.get_period(*days))


@router.post(
    "/trips",
    status_code=status.HTTP_201_CREATED,
    response_model=TripOut,
    response_description="The trip is stored",
    responses={
        status.HTTP_200_OK: {
            "model": TripOut,
            "description": "A repeat: the trip is already stored with the same data",
        },
        status.HTTP_409_CONFLICT: {
            "model": ConflictOut,
            "description": "The id is already stored with other data",
        },
    },
)
async def create_trip(
    trip: TripCreate,
    response: Response,
    service: TripsServiceDep,
    driver_tz: DriverTzDep,
) -> TripOut:
    match await service.create_trip(trip.to_domain()):
        case Created(trip=created):
            return TripOut.from_domain(created, driver_tz)
        case Repeated(trip=stored):
            response.status_code = status.HTTP_200_OK
            return TripOut.from_domain(stored, driver_tz)
        case Conflict(stored=stored):
            raise HTTPException(
                status.HTTP_409_CONFLICT, detail=ConflictDetailOut.from_domain(stored).model_dump()
            )
