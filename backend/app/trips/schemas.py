from datetime import datetime
from typing import Annotated

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

from app.trips.domain import PaymentMethod, Trip


def _parse_iso_datetime(value: object) -> object:
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            pass
    raise PydanticCustomError(
        "datetime_format", "Datetime should be in ISO 8601 format with a UTC offset"
    )


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
