# CLAUDE.md

This file is the canonical source for project rules. `AGENTS.md` only points here.

## Project

Driver shift diary — a test assignment: a FastAPI backend and a Flutter client that show a
driver's trips and daily summary, and add trips without duplicates.

Read before writing code:

- `docs/requirements.md` — what must work (R*), what to deliver (D*), extras (X*).
- `docs/decisions.md` — decisions D1–D12. Code must follow them; a change that contradicts one
  updates the decision in the same PR.
- `docs/api.md` — the API contract.
- `docs/architecture.md` — layout and conventions for both sides.
- `docs/plan.md` — PR sequence. Stay inside the current PR's scope.
- `data/README.md` — seed trips and the expected summary for each day.

## Commands

```bash
make up      # docker compose up: Postgres + API with data/trips.json loaded (from PR 5)
make gen     # build_runner for the Flutter app
make gate    # backend: ruff, mypy, import-linter, pytest; app: format check, analyze, tests
make apk     # release APK with app/env/prod.json; stops if it is missing or not https://
```

`make gate` runs `gate-backend` and `gate-app`, and skips a side whose folder (`backend/`, `app/`)
does not exist yet, so the backend and app tracks can land independently. `gate-app` runs the
Flutter tests with `TZ=America/New_York`, so code that shows the phone's time instead of
Asia/Almaty fails locally too, even on a machine in Almaty. Flutter runs through fvm by default.
CI runs the same targets. The backend workflow calls `make gate-backend`. The app workflow calls
`make gen DART=dart` and fails if the generated code differs from the committed files, new files
included, then calls `make gate-app FLUTTER=flutter DART=dart`. The release workflow runs on a
`v*` tag: `make apk FLUTTER=flutter`, then a GitHub release with `driver-shifts-<tag>.apk` and
its `.sha256`; how to cut one is in `docs/architecture.md` («Окружения»). Keep CI calling the
same `make` targets as local runs.

## Invariants

These are the reason the project exists. Do not trade them for convenience.

- **Money** is integer tenge everywhere: `int` in Python and Dart, `integer` in Postgres.
  Never `float`/`double`, never `Decimal` "just in case".
- **Time** is timezone-aware end to end. Reject timestamps without an offset. Store `timestamptz`.
- **A day** is a calendar date in `Asia/Almaty`; a trip belongs to the day of its `start` (D1, D2).
  Never group by UTC date. `Asia/Almaty` is UTC+05:00 since 2024-03-01 — a guard test pins it.
- **Duplicates** are prevented by the primary key and `INSERT … ON CONFLICT`, never by
  check-then-insert. New → `201`, identical repeat → `200`, same `id` with different data → `409` (D4).
- **The summary** is computed only on the server, by `summarize()`, from the same trips list the
  response returns. The client never recomputes money (D6).
- **Client retries** reuse the trip `id` generated when the form opened, and retry only
  `Failure.isTransient` (D7).

## Backend (`backend/`)

- Python 3.14, FastAPI (`fastapi[standard]`), Pydantic v2 + `pydantic-settings`, Postgres 18,
  async psycopg 3 (`psycopg[binary,pool]`, `AsyncConnectionPool`), plain SQL. No ORM, no Alembic
  (D10). Endpoints are `async def`.
- Current idioms only — old ones are what AI reproduces from stale examples:
  - `lifespan`, never `@app.on_event`.
  - `Annotated[..., Depends(...)]` for dependencies.
  - Pydantic v2: `model_config = ConfigDict(...)`, `model_dump()`, `field_validator` /
    `model_validator`. Never `class Config`, `.dict()`, `@validator`.
- Postgres 18 images keep data under `/var/lib/postgresql`, not `/var/lib/postgresql/data`.
  Mount the compose volume there.
- Docker: `backend/Dockerfile` (uv, two stages, non-root) builds from the repository root, so the
  image carries `data/trips.json` and points `TRIPS_FILE` at it; `.dockerignore` lets only those
  files in. `docker-compose.yml` runs it with `postgres:18`. Both services have healthchecks and
  the API starts after `depends_on: condition: service_healthy`. `pg_isready` checks over TCP:
  on first start the entrypoint's temporary server listens only on the socket.
- In the image, time zones come only from the `tzdata` package pinned in `uv.lock`
  (`PYTHONTZPATH=""` turns off the base image's database). Update it with
  `uv lock --upgrade-package tzdata`. The guard test runs on the host's database, not the image's.
- One `fastapi run` process per container: endpoints are async and the load is one driver.
  `WEB_CONCURRENCY` changes it without a rebuild; processes × `DATABASE_POOL_MAX_SIZE` must stay
  within Postgres' `max_connections` (100, 3 reserved).
- `make smoke` (`scripts/smoke.sh`, also a CI job) starts the stack on an empty volume, checks the
  `Asia/Almaty` offset inside the container and 2026-10-01 against the assignment, adds a trip,
  restarts on the same volume, and checks 2026-10-01 again (no duplicates), the added trip and
  yesterday's demo trips (unchanged). It removes the stack with its volume before and after.
- Domain modules in the fastapi-best-practices layout: `app/trips/` holds `router.py`,
  `schemas.py`, `domain.py`, `repository.py`, `service.py`, `dependencies.py`, `seed.py`,
  `demo.py`;
  `app/config.py` and `app/database.py` are shared. Full layout in `docs/architecture.md`.
- No ports/adapters, abstract repositories, Unit of Work or DI containers: each would have one
  implementation. Inject with FastAPI `Depends` from `dependencies.py`.
- API schemas and the domain are separate classes:
  - `schemas.py` — Pydantic models of the API: `TripCreate` (holds the D5 rules), `TripOut`
    (times in the driver's offset), `DayReportOut`, error bodies, and the mapping to and from
    the domain.
  - `domain.py` — frozen dataclasses (`Trip`, `DaySummary`, `DayReport`) and pure functions,
    standard library only.
  - Service and repository take and return domain objects only; the router, `seed.py` and
    `demo.py` do the mapping.
- `router.py` handles HTTP only and declares `response_model` on every endpoint. `service.py`
  orchestrates and knows nothing about HTTP or schemas.
- `seed.py` parses `trips.json` through `TripCreate`, so seed data passes the same checks as the API.
  The lifespan takes `pg_advisory_xact_lock` first, then applies `schema.sql` and saves the trips
  with `create_trip`, all in one transaction, so several processes can start on an empty
  database; a trip already stored with other data stops the startup (D10).
- `demo.py` (D13): `demo_trips(now, tz, days, skip_days)` is a pure generator of trips for the
  last `DEMO_DAYS` driver days up to today (setting, 0 = off, at most 31; 14 in compose and
  `render.yaml`). Ids are `demo-<day>-<n>`, so a day always yields identical trips; days of
  `trips.json` trips are skipped; only trips with `end <= now` are kept; trips go through
  `TripCreate`. The lifespan saves them after `trips.json` in the same transaction; a demo id
  stored with other data is logged and skipped, never stops the startup.
- `create_app(settings, clock)` builds the app; `clock` returns an aware `now` and is fixed in
  tests (never patch `datetime`). The lifespan yields the pool and settings as lifespan
  state, and `dependencies.py` reads them from `request.state`. The connection is `ConnectionDep`
  with `scope="function"`: the transaction commits before the response is sent.
- Day bounds come only from `day_window()`: the driver's midnights as UTC instants, compared as
  `started_at >= start AND started_at < end`. A period (`GET /periods/{start}/{end}`, D14) is
  one query from `day_window(start)` to `day_window(end)`; `group_by_day()` splits it by the
  same windows and `period_report()` sums the period with `summarize()` over the same trips as
  its days. At most 31 days, `end` not before `start` (`check_period()`, `422` at
  `["path", "end"]`). `stats` comes from the pure `period_stats()`: average trip, net per hour
  in trips (trip durations in microseconds) and the best day (earliest on ties), whole tenge
  via `divide_half_up()` — integer arithmetic only, `null` without trips. No `::date`, `date_trunc` or `AT TIME ZONE` in SQL:
  they follow the session time zone and Postgres' own time zone data.
- Inputs are parsed strictly: a path date is exactly `YYYY-MM-DD`, trip times are ISO 8601
  strings with an offset. Pydantic alone accepts Unix time for both and reads it as UTC.
  Days and trip times (in UTC) stay within 0001-01-02 … 9999-12-30, so no conversion to any
  time zone leaves years 1–9999 and turns into a 500.
- `import-linter` enforces two contracts in CI:
  - layers `router | seed | demo` → `schemas | dependencies` → `service` → `repository` → `domain`,
    exhaustive: a new module in `app/trips/` must take a layer;
  - `domain` imports none of `fastapi`, `pydantic`, `psycopg`.
- Duplicate protection is one atomic statement: `insert_if_absent` runs
  `INSERT … ON CONFLICT (id) DO NOTHING RETURNING` and reads the stored row only when nothing was
  inserted. Never read → compare → insert.
- `create_trip` returns `Created | Repeated | Conflict`; the router maps it with `match`.
  `POST /api/v1/trips` declares `status_code=201`; a repeat sets `status_code = 200` on the
  injected `Response`; a conflict raises `HTTPException(409)` with `ConflictDetailOut`. The route's
  `responses=` puts `200` and `409` into `/openapi.json`.
- A `422` keeps FastAPI's standard body. Its contract is `loc` (the field) and `type` (the reason,
  listed in `docs/api.md`): the client picks its own text by them. Pydantic's English `msg` is
  for developers. Tests pin `loc` and `type`.
- The pool opens one connection and grows to `DATABASE_POOL_MAX_SIZE` (a setting, 10 by
  default). The concurrency test requires the app's pool to allow at least 10, holds writes with
  `LOCK TABLE trips IN SHARE MODE` until 10 requests wait at their `INSERT` at once, then releases
  them together: the race is forced, not hoped for. A pool below 10 or requests that run one by
  one fail the test.
- `summarize()`, `day_window()`, `group_by_day()`, `period_report()`, `period_stats()` and
  `same_trip()` are pure and unit-tested without a database
  (`tests/unit/`).
- Database tests (`tests/integration/`) run against real Postgres 18 started by `testcontainers`,
  never mocks: the concurrency test is meaningless otherwise. `uv run pytest` needs only Docker,
  locally and in CI. API tests use the async client (`httpx.AsyncClient`) from the start, and run
  the lifespan through `asgi_lifespan.LifespanManager`: `httpx.ASGITransport` sends no lifespan
  events. `ASGITransport` also returns only after the app is done, so a test that a write is
  committed before the response checks the database at `http.response.start`, not with a
  follow-up request. Fixtures go `settings` → `app` → `client` and `pool` (read from the
  lifespan state); a test module overrides `settings` to start the app with other settings.
- Tooling: `uv` (commit `uv.lock`), `ruff` (lint + format), `mypy --strict`, `pytest`,
  `hypothesis`, `testcontainers`, `import-linter`.
- `ruff` rule sets include `DTZ` (no naive `datetime`, no `date.today()`), `ASYNC`, `UP`, `B`.
- pytest turns warnings into errors and runs async tests on anyio in auto mode: no markers,
  no `pytest-asyncio`.
- Change dependencies with `uv add` / `uv remove` and commit `uv.lock` with `pyproject.toml`:
  CI sets `UV_LOCKED=1` and fails on a stale lock.
- `make gate-backend` runs the backend half of the gate. Like every `make` target, it runs from
  the repository root, where the `Makefile` is. The `uv` commands run from `backend/`:

  ```bash
  uv sync                    # dependencies into .venv
  uv run pytest tests/unit   # domain tests, no Docker
  uv run pytest              # all tests; tests/integration starts Postgres 18 in Docker
  uv run fastapi dev         # the API on http://127.0.0.1:8000, reloads on change
  ```

## Flutter app (`app/`)

Feature-first Clean Architecture with BLoC, sized to this task.

```bash
cd app
fvm install                                                        # once: the SDK from app/.fvmrc
fvm flutter run --dart-define-from-file=env/ios-simulator.json     # iOS simulator, API from `make up`
fvm flutter run --dart-define-from-file=env/android-emulator.json  # Android emulator
cp env/local.example.json env/local.json                           # phone on the same network:
fvm flutter run --dart-define-from-file=env/local.json             #   put the computer's IP there
TZ=America/New_York fvm flutter test   # tests as gate-app runs them, away from Asia/Almaty
make -C .. gate-app                    # format check, analyze, tests: the app half of `make gate`
```

- Flutter stable 3.47.6 (Dart 3.13.5), pinned in `app/.fvmrc`; CI reads the same file.
- Feature layout: `data/{datasources,repositories}`, `domain/{models,repositories}`,
  `presentation/{bloc,screens,widgets}`. The checks against Flutter's official architecture
  recommendations are in `docs/architecture.md`.
- Repository implementations use `HandleErrorMixin` and return `Result<T>`. Datasources throw;
  the mixin maps `DioException` to a sealed `Failure`. Widgets show `Failure` messages, never raw
  exception text.
- Everything that depends on Dio lives in `core/network/`: the client, the error bodies and
  `HandleErrorMixin`. `core/error/failure.dart` and `core/domain/result.dart` never import Dio.
- `422` maps to `ValidationFailure` with per-field errors; `409` maps to `ConflictFailure`,
  whose message is the client's own: the server text carries the trip id, which a screen
  reader would read out.
  Error bodies are API models in `core/network/api_error.dart`; they never reach the domain.
- A `422` error is read by `loc` and `type` (`docs/api.md`, «Ошибки»). The field is `loc[1]`
  only when it is a string; `["body"]` and the number that `json_invalid` puts in `loc[1]` belong
  to the whole form. The text under a field is chosen by `type`, with a general text for an
  unknown `type`. Pydantic's English `msg` is never shown to the driver: `api_error.dart` does
  not even read it. `ValidationFailure` carries `type`s (field → `type`, and the whole-body
  `type`s); the form maps them to texts in `shift_diary_strings.dart`.
- JSON parses straight into domain models (`freezed` + `json_serializable`). No DTO mirrors: the
  client neither owns the contract nor stores data. (The backend is different — it owns the
  contract, so it keeps API schemas apart from the domain.)
  `build.yaml` sets `field_rename: snake` globally; no per-field `@JsonKey(name:)` for snake_case.
- No use cases: they would only forward to the repository. Add one only when it carries logic.
- A new trip is a full `Trip` (the client generates its id): the repository takes
  `addTrip(Trip)`, no params object. A half-filled form is bloc state, not domain.
- BLoC only for state.
  - State is one `freezed` class with a `status` enum when data must survive transitions — both
    blocs here. `DayState` keeps the report during a same-day refresh and on its failure, and
    drops it when the day changes; `PeriodState` does the same for its period. `AddTripState` keeps `tripId` and field errors across
    submissions. Sealed subclasses only for truly exclusive states.
  - Events are past tense: `DayStarted`, `DayChanged`, `DayRefreshRequested`, `PeriodChanged`,
    `PeriodRefreshRequested`, `TripSubmitted`.
  - Every handler checks `if (isClosed || emit.isDone) return;` after each `await`.
  - `DayBloc` handles every day event in one `on<DayEvent>` with `restartable()`, so a refresh
    and a day switch cancel each other; `PeriodBloc` likewise with `on<PeriodEvent>`.
    Submitting a form: `droppable()`.
  - A day load waits out a sleeping demo backend by itself (D12): after 3 s it sets
    `DayState.slow` (the «Сервер просыпается» note), and a transient failure is retried every
    5 s until 90 s have passed since the load started. `PeriodBloc` waits the same way: both
    use `WakingServerLoader` (timings in `WakingServerTimings`) instead of a copy, and dispose
    it on `close()`. Tests drive them with `fake_async` or
    `tester.pump`, never real waits. The form never retries by itself (D7).
  - Days are pages (`DayPages`: a horizontal `Scrollable` with page physics, excluded from
    semantics; the arrows carry the actions). The screen adds `DayChanged` only when a page
    settles, never per drag frame. Arrows, the picker and «Сегодня» turn the page with the same
    slide; a far day is first warped next to the shown one, as `TabBarView` does. A page that
    is not `DayState.date` shows the skeleton.
  - `AddTripBloc` ignores edits while a trip is being sent, so the form shows what was sent.
    `AddTripState.canRetry` is true only after a transient failure: the button then reads
    «Повторить» and resends the same trip id. A resubmission after `422` or a transient
    failure keeps the id too: a trip saved by a lost request then gets `409`, never a twin.
    `409` ends the form (`conflicted`): no more edits or sends, the button reads «Закрыть».
    A failed local check is `AddTripStatus.invalid`: field errors only, no banner. A `422`
    banner goes away with the next edit; transient and `409` banners stay.
  - Moving the start (day or time) of a trip with a positive duration moves the end by as
    much, like iOS Calendar. Only an end time the driver sets before the start time puts the
    end on the next day, until the driver picks the end day (`TripDraft.endDayPicked`). Equal
    times stay on one day and fail the check (D2): a start moved off them never makes a
    ~24 h trip.
  - A form opened on `DriverClock.today()` holds a 20-minute trip that ends at the current
    Almaty minute (both times empty if it would start before midnight). On another day the
    times are empty; with a start and no end, the end picker opens 15 minutes after the start.
  - The mode «День · Неделя · Месяц» lives in the screen, not in a bloc or on disk. A week is
    Monday to Sunday and a month the calendar month, as `Period` with a `DateTime.utc` start
    (`Period.containing(kind, day)`); the current one comes from `DriverClock.today()`. Weeks
    and months are pages too; a tapped day row switches to the day mode on that day. A week
    never lists days after today (display only, the API is unchanged). Titles: «Эта неделя,
    5 – 11 окт», «28 сент – 4 окт», «Октябрь 2026» (every month, the current one too).
    The mode switch is `SlidingSegmentedControl` (a custom widget from theme tokens, the same on
    both platforms) in place of the app bar title; at large text it moves to its own row.
    Below 150% a week is `WeekChart` (bar heights from `stats.best_day`, days ahead empty);
    at large text and for a month, the day list. `PeriodStatsRow` shows the server's `stats`. The form
    opens on today when the shown period holds it, otherwise on the period's first day, and a
    saved trip reloads the shown period (`PeriodRefreshRequested`). The day net bar is
    net / best day net for display; the client never sums days.
  - Blocs never reference each other. On a saved trip, a `BlocListener<AddTripBloc>` in the
    screen closes the sheet. A trip on the shown day adds `DayRefreshRequested` (it reloads the
    shown day); a trip on another day turns the page to `clock.dayOf(trip.start)`, which adds
    `DayChanged` when it settles. When the sheet closes after a send that did not end in
    success (by the cross, a swipe down or the back gesture), even if a later local check
    failed, the screen applies the same rule to `AddTripState.unconfirmedTrip`, the last trip
    it sent: the driver sees whether it was stored.
    The sheet swipes down and has its own drag handle, but cannot be closed while a trip is
    being sent (`PopScope`; the sheet claims vertical drags itself, since the route's drag
    pops past `PopScope`), so its reply always reaches the bloc.
- freezed 3+: declare classes `abstract` (one constructor) or `sealed` (several). Match them with
  Dart 3 `switch` patterns, not `when` / `maybeWhen`.
- New trip ids are `Uuid().v7()`.
- DI through constructors, registered with `@injectable` / `@lazySingleton`; `get_it` is touched
  only in `di/` and at the widget tree root. The root also provides `DriverClock` and
  `TripsRepository` with `RepositoryProvider`; the screen builds an `AddTripBloc` from them each
  time the form opens, so every form gets its own trip id, and closes it after the sheet.
- Show trip times and "today" in `Asia/Almaty` via the `timezone` package. Never `toLocal()`.
- A calendar day is `DateTime.utc(y, m, d)` (`DriverClock.today()`, `DayState.date`); `DayChanged`
  asserts it. The day of a moment is `DriverClock.dayOf(instant)`, never
  `DateTime.utc(t.year, …)` of a UTC moment: that puts 00:00–05:00 in Almaty on the day before.
  Date pickers return local midnight: convert the result with `DateTime.utc(picked.year,
  picked.month, picked.day)`.
- "Today" moves on at the Almaty midnight: the screen refreshes it on resume
  (`AppLifecycleListener`) and on a timer (`DriverClock.untilTomorrow()`). Never compute it once.
- JSON trip times must carry an offset, and money must be a whole number: `OffsetDateTimeConverter`
  and `WholeNumberConverter` in `domain/models/json_converters.dart` fail the parse otherwise.
- UI is Material 3 themed from `core/theme/` (D11) after the Claude Design handoff in
  `docs/design/README.md` (direction 1a, «grouped list»): seeded light and dark schemes
  following the system setting, system fonts, flat cards on the screen background. Widgets
  read colors, text styles, spacing, sizes and durations from the theme and the tokens
  (`Spacing`, `Radii`, `Sizes`, `Motion`, `Opacities`, `AppTextStyles`) — no `Color(0x…)`
  literals or magic numbers in feature widgets. `AppTheme.light` and `dark` are getters, not
  `static final`: `ThemeData` keeps the platform it was built for.
- Payment colors come only from the `PaymentColors` theme extension, computed from
  `material_color_utilities` palettes (the handoff hex values are what the theme test
  expects), and appear only in the payment icon circles. Red is for errors only.
- Icons come from `AppIcons.of(context)`: `CupertinoIcons` on iOS, Material Icons elsewhere.
  Cash and card are `AppIcons.cash` / `AppIcons.card` (Material Icons Rounded) on both. No
  `Icons.` or `CupertinoIcons.` in feature widgets. On iOS the theme has no ripple: a press
  darkens by 8% of onSurface. `styleFrom(foregroundColor: …)` derives its own overlay, so a
  widget style passes through `AppTheme.withPlatformPress(context, style)`.
- No FAB. A screen's main action is a labelled full-width button in
  `Scaffold.bottomNavigationBar` («Добавить поездку»), «Сегодня» is a text button in the app
  bar; at large text, under the day, it is a tonal «Перейти к сегодня» button. The summary
  opens with «На руки», then «Выручка» with cash and card right under it, then «Комиссия».
  The list ends 16 dp above the bar, and the bar shows a divider only while content is under
  it.
- One UI for both platforms. Use adaptive APIs where platforms differ: `CupertinoDatePicker` in
  a bottom sheet titled with the field on iOS vs `showDatePicker` / `showTimePicker` on
  Android, `showAdaptiveDialog` + `AlertDialog.adaptive`, `.adaptive` progress and refresh
  indicators. No Cupertino-only screens, no third-party UI kits.
- The iOS number pad has no «Готово», and on phones Flutter keeps a field focused when the
  user touches elsewhere. Text fields unfocus in `onTapOutside`. A form unfocuses before it
  opens a picker or dialog: otherwise the closed route gives focus back to the field and the
  keyboard returns. A sheet keeps its main button below the scrolling fields, above the
  keyboard.
- Material and Cupertino localizations are Russian (`flutter_localizations`,
  `supportedLocales: [Locale('ru')]`). UI strings live in
  `features/shift_diary/presentation/shift_diary_strings.dart`.
- Money uses tabular figures (`FontFeature.tabularFigures()`) and has a screen-reader label.
  Amounts are shown through `MoneyText`: one line in a `FittedBox(scaleDown)` that shrinks the
  whole number — never wrap or ellipsize an amount. A `FittedBox` shrinks only within a bounded
  width: give `MoneyText` one (`Expanded`, a `Column`, a `ConstrainedBox`), never a bare `Row`
  slot. The form takes whole tenge only: `GroupedDigitsFormatter` groups thousands like the
  summary and refuses an edit with anything but digits and spaces, so `2400,50` or `-150`
  leaves the field as it was instead of becoming another amount (D3).
- Large text starts at `TextScale.isLarge(context)` (scale ≥ 1.5): layouts switch there
  (no app bar title, the day on its own line, cash and card in a column, the trip amount under
  its time, no «+» on the add button, form labels above values). Only the day title and
  «На руки» are clamped, to 1.6 (`TextScale.headline`); every other text scales freely.
  A side-by-side layout also gives way below 1.5 when its texts do not fit without breaking a
  word: measure them (`TextMeasure`) and stack, as cash and card, the trip row and the payment
  buttons do. Never let a word or a number break mid-way.
- «+N день» means the trip ends N Almaty dates after its start
  (`DriverClock.daysLater`, comparing `dayOf`), the same rule in the list and the form. It is a
  date comparison for display, never a UTC or phone date, and never money.
- Screens must survive 200% text scale and the dark theme without overflow; widget tests cover
  both. Show errors inside the screen, not in a `SnackBar` with an action: it keeps the action in
  a row that overflows at 200% on a 320 dp phone. Error texts and the day title are
  `Semantics(liveRegion: true)`, so screen readers hear them. In the form, a field error is
  the `hint` of the field's semantics node and a `FieldError` under its row (a live region where
  the platform has no announcements, as `InputDecorator` does), and the failure of a submission
  is a `FailureBanner` above the button. A trip row is read as one phrase and «+N день» is
  excluded from semantics. The
  `showDatePicker` calendar and the `showTimePicker` dial are clamped to 130% text
  (`PickerMetrics.maxDialogTextScale`): at 200% Flutter clips two-digit days and piles up the
  dial numbers. The time picker is always 24-hour (`alwaysUse24HourFormat: true`): its input
  mode checks hours by that flag, not by the locale, and would reject 18 on a 12-hour phone.
  The FlutterTest font hides broken words and ellipses: check new layouts at 200% on 320 dp with
  real Roboto (a throwaway golden test, not committed).
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) are committed. Run `make gen`
  after changing annotated files.
- Tests use fakes (`class FakeTripsRepository extends Fake implements TripsRepository`), not
  mocks. Bloc tests assert emitted states in order. One feature test drives the screen with real
  blocs and the fake repository: open a day → add a trip → see the updated summary. Screen tests
  pump `DriverShiftsApp` through `test/helpers/pump_app.dart`, which registers the fakes in
  `get_it`.
- The API base URL comes only from `--dart-define-from-file=env/<name>.json` (`API_BASE_URL`,
  read in `core/config/env.dart`; D12). Never hardcode it. Cleartext `http` is allowed only in the
  Android debug manifest and via `NSAllowsLocalNetworking` on iOS; release builds use HTTPS.
- Lints: `flutter_lints` plus strict rules in `analysis_options.yaml`, with language modes
  `strict-casts`, `strict-inference`, `strict-raw-types`.
- No `print`/`debugPrint`. Package imports only.

## Comments

The default is none. Names, types and structure carry the meaning; a comment is an admission
that they could not. Explain *why* only where the code cannot.

## Workflow

- One PR per row in `docs/plan.md`. Small commits, Conventional Commits.
- Run `make gate` before every commit. CI runs the same checks.
- When AI-generated code turns out wrong — caught by a test, review or on-device run — add an
  entry to `docs/ai-log.md` with the commit link. Only real cases.

## Out of scope

Authentication, multiple drivers, editing or deleting trips, offline queue, overlap and
max-duration checks (see "Сознательно не делаем" in `docs/decisions.md`). Do not add them
without a decision entry.
