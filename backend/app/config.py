from functools import lru_cache
from pathlib import Path
from typing import Annotated
from zoneinfo import ZoneInfo

from pydantic import Field, PositiveInt, PostgresDsn
from pydantic_settings import BaseSettings

REPO_ROOT = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    database_url: PostgresDsn
    database_pool_max_size: PositiveInt = 10
    driver_tz: ZoneInfo = ZoneInfo("Asia/Almaty")
    trips_file: Path = REPO_ROOT / "data" / "trips.json"
    demo_days: Annotated[int, Field(ge=0, le=31)] = 0


@lru_cache
def get_settings() -> Settings:
    return Settings()
