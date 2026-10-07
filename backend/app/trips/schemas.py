import re
from datetime import UTC, date, datetime
from typing import Annotated, Literal, Self
from zoneinfo import ZoneInfo

from fastapi.exceptions import RequestValidationError
from pydantic import (
    AfterValidator,
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

from app.trips.domain import (
    BestDay,
    DayReport,
    DaySummary,
    DayTotal,
    PaymentMethod,
    PeriodReport,
    PeriodStats,
    Trip,
)

_ISO_DATE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
_POSTGRES_INTEGER_MAX = 2_147_483_647
# 0001-01-01 and 9999-12-31 lack a midnight on one side, and no time zone moves a moment by a
# day or more: within these bounds every conversion stays in years 1 to 9999.
_FIRST_DAY = date(1, 1, 2)
_LAST_DAY = date(9999, 12, 30)
_FIRST_MOMENT = datetime(1, 1, 2, tzinfo=UTC)
_END_OF_LAST_DAY = datetime(9999, 12, 31, tzinfo=UTC)
MAX_PERIOD_DAYS = 31


def _require_date_format(value: object) -> object:
    if isinstance(value, str) and _ISO_DATE.fullmatch(value):
        return value
    raise PydanticCustomError("date_format", "Date should be in the format YYYY-MM-DD")


def _require_supported_day(day: date) -> date:
    if not _FIRST_DAY <= day <= _LAST_DAY:
        raise PydanticCustomError(
            "date_out_of_range", "Date should be between 0001-01-02 and 9999-12-30"
        )
    return day


def _parse_iso_datetime(value: object) -> object:
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            pass
    raise PydanticCustomError(
        "datetime_format", "Datetime should be in ISO 8601 format with a UTC offset"
    )


def _require_supported_moment(moment: datetime) -> datetime:
    try:
        supported = _FIRST_MOMENT <= moment.astimezone(UTC) < _END_OF_LAST_DAY
    except OverflowError:
        supported = False
    if not supported:
        raise PydanticCustomError(
            "datetime_out_of_range", "Datetime should be between 0001-01-02 and 9999-12-30 in UTC"
        )
    return moment


def check_period(start: date, end: date) -> None:
    if end < start:
        error_type, message = "period_end_before_start", "End should not be earlier than start"
    elif (end - start).days + 1 > MAX_PERIOD_DAYS:
        error_type = "period_too_long"
        message = f"Period should be at most {MAX_PERIOD_DAYS} days"
    else:
        return
    raise RequestValidationError(
        [{"type": error_type, "loc": ("path", "end"), "msg": message, "input": end.isoformat()}]
    )


IsoDate = Annotated[
    date, BeforeValidator(_require_date_format), AfterValidator(_require_supported_day)
]
IsoDatetime = Annotated[
    AwareDatetime, BeforeValidator(_parse_iso_datetime), AfterValidator(_require_supported_moment)
]
TripId = Annotated[str, StringConstraints(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")]


class TripCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: TripId
    start: IsoDatetime
    end: IsoDatetime
    amount: Annotated[StrictInt, Field(gt=0, le=_POSTGRES_INTEGER_MAX)]
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


class ConflictDetailOut(BaseModel):
    code: Literal["trip_conflict"]
    message: str

    @classmethod
    def from_domain(cls, stored: Trip) -> Self:
        return cls(
            code="trip_conflict",
            message=f"Поездка с id {stored.id} уже сохранена с другими данными",
        )


class ConflictOut(BaseModel):
    detail: ConflictDetailOut


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


class DayTotalOut(BaseModel):
    date: date
    summary: DaySummaryOut

    @classmethod
    def from_domain(cls, total: DayTotal) -> Self:
        return cls(date=total.day, summary=DaySummaryOut.from_domain(total.summary))


class BestDayOut(BaseModel):
    date: date
    net: int

    @classmethod
    def from_domain(cls, best: BestDay) -> Self:
        return cls(date=best.day, net=best.net)


class PeriodStatsOut(BaseModel):
    average_trip: int | None
    net_per_hour: int | None
    best_day: BestDayOut | None

    @classmethod
    def from_domain(cls, stats: PeriodStats) -> Self:
        return cls(
            average_trip=stats.average_trip,
            net_per_hour=stats.net_per_hour,
            best_day=None if stats.best_day is None else BestDayOut.from_domain(stats.best_day),
        )


class PeriodReportOut(BaseModel):
    start: date
    end: date
    timezone: str
    summary: DaySummaryOut
    days: list[DayTotalOut]
    stats: PeriodStatsOut

    @classmethod
    def from_domain(cls, report: PeriodReport) -> Self:
        return cls(
            start=report.start,
            end=report.end,
            timezone=report.timezone.key,
            summary=DaySummaryOut.from_domain(report.summary),
            days=[DayTotalOut.from_domain(total) for total in report.days],
            stats=PeriodStatsOut.from_domain(report.stats),
        )
