from collections.abc import AsyncIterator, Iterator

import pytest
from psycopg import AsyncConnection
from testcontainers.community.postgres import PostgresContainer

from app.database import Connection
from app.trips import repository


@pytest.fixture(scope="session")
def anyio_backend() -> str:
    return "asyncio"


@pytest.fixture(scope="session")
def database_url() -> Iterator[str]:
    with PostgresContainer("postgres:18-alpine", driver=None) as postgres:
        yield postgres.get_connection_url()


@pytest.fixture
async def connection(database_url: str) -> AsyncIterator[Connection]:
    async with await AsyncConnection.connect(database_url, autocommit=True) as connection:
        await connection.execute("DROP TABLE IF EXISTS trips")
        await repository.create_schema(connection)
        yield connection
