from collections.abc import AsyncIterator, Iterator

import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from psycopg import AsyncConnection
from pydantic import PostgresDsn
from starlette.types import ASGIApp, Receive, Scope, Send
from testcontainers.community.postgres import PostgresContainer

from app.config import Settings
from app.database import Connection, Pool
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
def settings(database_url: str) -> Settings:
    return Settings(database_url=PostgresDsn(database_url))


@pytest.fixture
async def app(settings: Settings, connection: Connection) -> AsyncIterator[ASGIApp]:
    async with LifespanManager(create_app(settings)) as manager:
        yield manager.app


@pytest.fixture
async def client(app: ASGIApp) -> AsyncIterator[AsyncClient]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client


@pytest.fixture
async def pool(app: ASGIApp) -> Pool:
    pools: list[Pool] = []

    async def app_keeping_pool(scope: Scope, receive: Receive, send: Send) -> None:
        await app(scope, receive, send)
        pools.append(scope["state"]["pool"])

    async with AsyncClient(
        transport=ASGITransport(app=app_keeping_pool), base_url="http://test"
    ) as client:
        await client.get("/openapi.json")
    return pools[0]
