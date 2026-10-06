from typing import Annotated

from fastapi import APIRouter, Path

from app.trips.dependencies import TripsServiceDep
from app.trips.schemas import DayReportOut, IsoDate

router = APIRouter()


@router.get("/days/{date}", response_model=DayReportOut)
async def read_day(
    day: Annotated[IsoDate, Path(alias="date")],
    service: TripsServiceDep,
) -> DayReportOut:
    return DayReportOut.from_domain(await service.get_day(day))
