from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


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
