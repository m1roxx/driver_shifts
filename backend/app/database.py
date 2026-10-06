from psycopg import AsyncConnection
from psycopg.rows import TupleRow
from psycopg_pool import AsyncConnectionPool

type Connection = AsyncConnection[TupleRow]
type Pool = AsyncConnectionPool[Connection]

POOL_MAX_SIZE = 10


def create_pool(url: str) -> Pool:
    return AsyncConnectionPool(url, max_size=POOL_MAX_SIZE, open=False)
