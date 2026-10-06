from psycopg import AsyncConnection
from psycopg.rows import TupleRow
from psycopg_pool import AsyncConnectionPool

type Connection = AsyncConnection[TupleRow]
type Pool = AsyncConnectionPool[Connection]


def create_pool(url: str) -> Pool:
    return AsyncConnectionPool(url, open=False)
