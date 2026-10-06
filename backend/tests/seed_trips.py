from datetime import datetime
from zoneinfo import ZoneInfo

from app.trips.domain import PaymentMethod, Trip

ALMATY = ZoneInfo("Asia/Almaty")
CASH = PaymentMethod.CASH
CARD = PaymentMethod.CARD


def trip(
    trip_id: str, start: str, end: str, amount: int, payment: PaymentMethod, commission: int
) -> Trip:
    return Trip(
        id=trip_id,
        start=datetime.fromisoformat(start),
        end=datetime.fromisoformat(end),
        amount=amount,
        payment=payment,
        commission=commission,
    )


T1_JSON = {
    "id": "t1",
    "start": "2026-10-01T08:10:00+05:00",
    "end": "2026-10-01T08:32:00+05:00",
    "amount": 2400,
    "payment": "card",
    "commission": 360,
}

T1 = trip("t1", "2026-10-01T08:10:00+05:00", "2026-10-01T08:32:00+05:00", 2400, CARD, 360)
T2 = trip("t2", "2026-10-01T09:05:00+05:00", "2026-10-01T09:20:00+05:00", 1500, CASH, 225)
T3 = trip("t3", "2026-09-30T18:40:00+05:00", "2026-09-30T19:05:00+05:00", 1800, CARD, 270)
T4 = trip("t4", "2026-09-30T19:30:00+05:00", "2026-09-30T20:10:00+05:00", 3200, CASH, 480)
T5 = trip("t5", "2026-09-30T21:15:00+05:00", "2026-09-30T21:40:00+05:00", 2100, CARD, 315)
T6 = trip("t6", "2026-10-02T00:30:00+05:00", "2026-10-02T00:55:00+05:00", 2700, CASH, 405)
T7 = trip("t7", "2026-10-02T12:10:00+05:00", "2026-10-02T12:35:00+05:00", 1240, CARD, 186)
T8 = trip("t8", "2026-10-02T23:50:00+05:00", "2026-10-03T00:20:00+05:00", 4600, CARD, 690)
T9 = trip("t9", "2026-10-03T07:45:00+05:00", "2026-10-03T08:05:00+05:00", 1500, CASH, 225)

SEED_TRIPS = [T1, T2, T3, T4, T5, T6, T7, T8, T9]
