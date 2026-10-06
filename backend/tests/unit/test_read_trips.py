import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.config import REPO_ROOT
from app.trips.seed import read_trips
from tests.seed_trips import SEED_TRIPS, T1_JSON


def test_reads_data_trips_json() -> None:
    assert read_trips(REPO_ROOT / "data" / "trips.json") == SEED_TRIPS


def test_trips_json_goes_through_trip_create(tmp_path: Path) -> None:
    path = tmp_path / "trips.json"
    path.write_text(json.dumps([T1_JSON | {"amount": 0}]))

    with pytest.raises(ValidationError):
        read_trips(path)
