from typing import Any

import pytest
from psycopg.errors import CheckViolation

from app.database import Connection
from tests.seed_trips import T1

T1_ROW = {
    "id": T1.id,
    "started_at": T1.start,
    "ended_at": T1.end,
    "amount": T1.amount,
    "payment": T1.payment.value,
    "commission": T1.commission,
}


@pytest.mark.parametrize(
    ("change", "constraint"),
    [
        pytest.param({"amount": 0, "commission": 0}, "trips_amount_positive", id="zero amount"),
        pytest.param({"ended_at": T1.start}, "trips_end_after_start", id="end at start"),
        pytest.param({"commission": -1}, "trips_commission_within_amount", id="negative"),
        pytest.param({"commission": 2401}, "trips_commission_within_amount", id="above amount"),
        pytest.param({"payment": "crypto"}, "trips_payment_known", id="unknown payment"),
    ],
)
async def test_database_rejects_trips_that_bypass_validation(
    connection: Connection, change: dict[str, Any], constraint: str
) -> None:
    with pytest.raises(CheckViolation) as raised:
        await connection.execute(
            """
            INSERT INTO trips (id, started_at, ended_at, amount, payment, commission)
            VALUES (
                %(id)s, %(started_at)s, %(ended_at)s, %(amount)s, %(payment)s, %(commission)s
            )
            """,
            T1_ROW | change,
        )

    assert raised.value.diag.constraint_name == constraint
