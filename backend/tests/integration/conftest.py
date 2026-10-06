from collections.abc import AsyncIterator, Iterator

import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from psycopg import AsyncConnection
from pydantic import PostgresDsn
from testcontainers.community.postgres import PostgresContainer

from app.config import Settings
from app.database import Connection
from app.main import create_app
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


@pytest.fixture
async def client(database_url: str, connection: Connection) -> AsyncIterator[AsyncClient]:
    app = create_app(Settings(database_url=PostgresDsn(database_url)))
    async with (
        LifespanManager(app) as manager,
        AsyncClient(transport=ASGITransport(app=manager.app), base_url="http://test") as client,
    ):
        yield client
