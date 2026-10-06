from datetime import datetime
from pathlib import Path

from psycopg.rows import args_row

from app.database import Connection
from app.trips.domain import PaymentMethod, Trip

SCHEMA = Path(__file__).with_name("schema.sql")
_STARTUP_LOCK = 1_952_611_428


# CREATE TABLE IF NOT EXISTS is not safe against a second process starting on an empty database.
async def lock_startup(connection: Connection) -> None:
    await connection.execute("SELECT pg_advisory_xact_lock(%s)", (_STARTUP_LOCK,))


async def create_schema(connection: Connection) -> None:
    await connection.execute(SCHEMA.read_bytes())


async def list_between(connection: Connection, start: datetime, end: datetime) -> list[Trip]:
    async with connection.cursor(row_factory=args_row(_trip)) as cursor:
        await cursor.execute(
            """
            SELECT id, started_at, ended_at, amount, payment, commission
            FROM trips
            WHERE started_at >= %(start)s AND started_at < %(end)s
            ORDER BY started_at, id
            """,
            {"start": start, "end": end},
        )
        return await cursor.fetchall()


async def insert_if_absent(connection: Connection, trip: Trip) -> Trip | None:
    inserted = await connection.execute(
        """
        INSERT INTO trips (id, started_at, ended_at, amount, payment, commission)
        VALUES (%(id)s, %(start)s, %(end)s, %(amount)s, %(payment)s, %(commission)s)
        ON CONFLICT (id) DO NOTHING
        RETURNING id
        """,
        {
            "id": trip.id,
            "start": trip.start,
            "end": trip.end,
            "amount": trip.amount,
            "payment": trip.payment.value,
            "commission": trip.commission,
        },
    )
    if await inserted.fetchone() is not None:
        return None
    # A separate statement takes a fresh snapshot, so under READ COMMITTED it sees the row
    # committed by the concurrent insert that made this one do nothing.
    async with connection.cursor(row_factory=args_row(_trip)) as cursor:
        await cursor.execute(
            """
            SELECT id, started_at, ended_at, amount, payment, commission
            FROM trips
            WHERE id = %(id)s
            """,
            {"id": trip.id},
        )
        stored = await cursor.fetchone()
    if stored is None:
        raise LookupError(f"trip {trip.id} was neither inserted nor found")
    return stored


def _trip(
    trip_id: str,
    start: datetime,
    end: datetime,
    amount: int,
    payment: str,
    commission: int,
) -> Trip:
    return Trip(
        id=trip_id,
        start=start,
        end=end,
        amount=amount,
        payment=PaymentMethod(payment),
        commission=commission,
    )
