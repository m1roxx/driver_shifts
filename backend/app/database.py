from psycopg import AsyncConnection
from psycopg.rows import TupleRow
from psycopg_pool import AsyncConnectionPool

type Connection = AsyncConnection[TupleRow]
type Pool = AsyncConnectionPool[Connection]


def create_pool(url: str, max_size: int) -> Pool:
    return AsyncConnectionPool(url, min_size=1, max_size=max_size, open=False)
