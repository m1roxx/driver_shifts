import pytest
from pydantic import PostgresDsn

from app.config import Settings
from app.database import Pool


@pytest.fixture
def settings(database_url: str) -> Settings:
    return Settings(database_url=PostgresDsn(database_url), database_pool_max_size=12)


async def test_pool_size_comes_from_settings(pool: Pool) -> None:
    assert pool.max_size == 12
