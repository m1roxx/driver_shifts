import re
from datetime import date, datetime
from typing import Annotated, Self
from zoneinfo import ZoneInfo

from pydantic import (
    AwareDatetime,
    BaseModel,
    BeforeValidator,
    ConfigDict,
    Field,
    StrictInt,
    StringConstraints,
    ValidationInfo,
    field_validator,
)
from pydantic_core import PydanticCustomError

from app.trips.domain import DayReport, DaySummary, PaymentMethod, Trip

_ISO_DATE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")


def _require_date_format(value: object) -> object:
    if isinstance(value, str) and _ISO_DATE.fullmatch(value):
        return value
    raise PydanticCustomError("date_format", "Date should be in the format YYYY-MM-DD")


def _parse_iso_datetime(value: object) -> object:
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            pass
    raise PydanticCustomError(
        "datetime_format", "Datetime should be in ISO 8601 format with a UTC offset"
    )


IsoDate = Annotated[date, BeforeValidator(_require_date_format)]
IsoDatetime = Annotated[AwareDatetime, BeforeValidator(_parse_iso_datetime)]
TripId = Annotated[str, StringConstraints(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")]


class TripCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: TripId
    start: IsoDatetime
    end: IsoDatetime
    amount: Annotated[StrictInt, Field(gt=0)]
    payment: PaymentMethod
    commission: Annotated[StrictInt, Field(ge=0)]

    @field_validator("end")
    @classmethod
    def check_end_after_start(cls, end: datetime, info: ValidationInfo) -> datetime:
        start = info.data.get("start")
        if start is not None and end <= start:
            raise PydanticCustomError("end_not_after_start", "End should be later than start")
        return end

    @field_validator("commission")
    @classmethod
    def check_commission_within_amount(cls, commission: int, info: ValidationInfo) -> int:
        amount = info.data.get("amount")
        if amount is not None and commission > amount:
            raise PydanticCustomError(
                "commission_above_amount", "Commission should not exceed the amount"
            )
        return commission

    def to_domain(self) -> Trip:
        return Trip(
            id=self.id,
            start=self.start,
            end=self.end,
            amount=self.amount,
            payment=self.payment,
            commission=self.commission,
        )


class TripOut(BaseModel):
    id: str
    start: AwareDatetime
    end: AwareDatetime
    amount: int
    payment: PaymentMethod
    commission: int

    @classmethod
    def from_domain(cls, trip: Trip, timezone: ZoneInfo) -> Self:
        return cls(
            id=trip.id,
            start=trip.start.astimezone(timezone),
            end=trip.end.astimezone(timezone),
            amount=trip.amount,
            payment=trip.payment,
            commission=trip.commission,
        )


class ByPaymentOut(BaseModel):
    cash: int
    card: int


class DaySummaryOut(BaseModel):
    trips_count: int
    revenue: int
    commission: int
    net: int
    by_payment: ByPaymentOut

    @classmethod
    def from_domain(cls, summary: DaySummary) -> Self:
        return cls(
            trips_count=summary.trips_count,
            revenue=summary.revenue,
            commission=summary.commission,
            net=summary.net,
            by_payment=ByPaymentOut(cash=summary.cash, card=summary.card),
        )


class DayReportOut(BaseModel):
    date: date
    timezone: str
    summary: DaySummaryOut
    trips: list[TripOut]

    @classmethod
    def from_domain(cls, report: DayReport) -> Self:
        return cls(
            date=report.day,
            timezone=report.timezone.key,
            summary=DaySummaryOut.from_domain(report.summary),
            trips=[TripOut.from_domain(trip, report.timezone) for trip in report.trips],
        )
