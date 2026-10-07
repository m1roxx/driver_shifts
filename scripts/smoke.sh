#!/usr/bin/env bash
# make smoke: starts the compose stack from an empty volume, checks it, restarts it on the same
# volume and checks again. The stack and its volume are removed at the end, as at the start.
# Demo trips (DEMO_DAYS in docker-compose.yml) fill the last 14 days, so the check of the added
# trip on 2026-10-04 ignores them, and yesterday has to come back the same after the restart.
set -euo pipefail

cd "$(dirname "$0")/.."

readonly api=http://localhost:8000/api/v1

readonly assignment_day='{
  "date": "2026-10-01",
  "timezone": "Asia/Almaty",
  "summary": {
    "trips_count": 2, "revenue": 3900, "commission": 585, "net": 3315,
    "by_payment": {"cash": 1500, "card": 2400}
  },
  "trips": [
    {"id": "t1", "start": "2026-10-01T08:10:00+05:00", "end": "2026-10-01T08:32:00+05:00",
     "amount": 2400, "payment": "card", "commission": 360},
    {"id": "t2", "start": "2026-10-01T09:05:00+05:00", "end": "2026-10-01T09:20:00+05:00",
     "amount": 1500, "payment": "cash", "commission": 225}
  ]
}'

readonly added_trip='{"id": "smoke-1", "start": "2026-10-04T10:00:00+05:00",
  "end": "2026-10-04T10:20:00+05:00", "amount": 1000, "payment": "cash", "commission": 150}'

readonly almaty_yesterday='
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
print((datetime.now(ZoneInfo("Asia/Almaty")) - timedelta(days=1)).date())
'

readonly almaty_offset='
import sys, zoneinfo
from datetime import datetime, timedelta
import tzdata
midnight = datetime(2026, 10, 1, tzinfo=zoneinfo.ZoneInfo("Asia/Almaty"))
print(f"{midnight.isoformat()} (tzdata {tzdata.IANA_VERSION}, TZPATH {zoneinfo.TZPATH})")
if midnight.utcoffset() != timedelta(hours=5) or zoneinfo.TZPATH:
    sys.exit("Asia/Almaty must be +05:00 from the tzdata package")
'

fail() {
  echo "smoke: $*" >&2
  exit 1
}

finish() {
  local status=$?
  if ((status != 0)); then
    docker compose logs --no-color
  fi
  docker compose down --volumes
  exit "$status"
}

up() {
  docker compose up --detach --build --wait --wait-timeout 120
}

day() {
  curl --silent --show-error --fail-with-body "$api/days/$1"
}

check_assignment_day() {
  local report
  report=$(day 2026-10-01)
  echo "$report"
  jq --exit-status --argjson expected "$assignment_day" '. == $expected' <<<"$report" >/dev/null ||
    fail "2026-10-01 does not match the assignment"
}

check_trips_on_2026_10_04() {
  local ids
  ids=$(day 2026-10-04 | jq --compact-output '[.trips[].id | select(startswith("demo-") | not)]')
  [[ $ids == "$1" ]] || fail "2026-10-04 has trips $ids besides the demo ones, expected $1"
}

demo_report() {
  local report
  report=$(day "$1")
  jq --exit-status --arg prefix "demo-$1-" \
    '.trips != [] and all(.trips[]; .id | startswith($prefix))' <<<"$report" >/dev/null ||
    fail "$1 has no demo trips or other trips: $report"
  echo "$report"
}

add_trip() {
  local code
  code=$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --header 'Content-Type: application/json' --data "$added_trip" "$api/trips")
  [[ $code == 201 ]] || fail "POST /trips answered $code, expected 201"
}

trap finish EXIT
docker compose down --volumes

echo "smoke: from an empty volume"
up
docker compose exec -T api python -c "$almaty_offset"
check_assignment_day
check_trips_on_2026_10_04 '[]'
demo_day=$(docker compose exec -T api python -c "$almaty_yesterday")
demo_before=$(demo_report "$demo_day")
add_trip

echo "smoke: restarted on the same volume"
docker compose down
up
check_assignment_day
check_trips_on_2026_10_04 '["smoke-1"]'
[[ $(demo_report "$demo_day") == "$demo_before" ]] || fail "$demo_day changed after the restart"

echo "smoke: ok"
