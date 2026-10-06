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
```

`make gate` skips a side whose folder (`backend/`, `app/`) does not exist yet, so the backend and
app tracks can land independently. Flutter runs through fvm by default; CI overrides it with
`make gate FLUTTER=flutter DART=dart`. Keep CI calling the same `make` targets as local runs.

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
- Domain modules in the fastapi-best-practices layout: `app/trips/` holds `router.py`,
  `schemas.py`, `domain.py`, `repository.py`, `service.py`, `dependencies.py`, `seed.py`;
  `app/config.py` and `app/database.py` are shared. Full layout in `docs/architecture.md`.
- No ports/adapters, abstract repositories, Unit of Work or DI containers: each would have one
  implementation. Inject with FastAPI `Depends` from `dependencies.py`.
- API schemas and the domain are separate classes:
  - `schemas.py` — Pydantic models of the API: `TripCreate` (holds the D5 rules), `TripOut`
    (times in the driver's offset), `DayReportOut`, error bodies, and the mapping to and from
    the domain.
  - `domain.py` — frozen dataclasses (`Trip`, `DaySummary`) and pure functions, standard library
    only.
  - Service and repository take and return domain objects only; the router and `seed.py` do the
    mapping.
- `router.py` handles HTTP only and declares `response_model` on every endpoint. `service.py`
  orchestrates and knows nothing about HTTP or schemas.
- `seed.py` parses `trips.json` through `TripCreate`, so seed data passes the same checks as the API.
- `import-linter` enforces two contracts in CI:
  - layers `router | seed` → `schemas | dependencies` → `service` → `repository` → `domain`;
  - `domain` imports none of `fastapi`, `pydantic`, `psycopg`.
- Duplicate protection is one atomic statement: `insert_if_absent` runs
  `INSERT … ON CONFLICT (id) DO NOTHING RETURNING` and reads the stored row only when nothing was
  inserted. Never read → compare → insert.
- `create_trip` returns `Created | Repeated | Conflict`; the router maps it with `match`.
- `summarize()`, `day_window()` and `same_trip()` are pure and unit-tested without a database
  (`tests/unit/`).
- Database tests (`tests/integration/`) run against real Postgres 18 started by `testcontainers`,
  never mocks: the concurrency test is meaningless otherwise. `uv run pytest` needs only Docker,
  locally and in CI. API tests use the async client (`httpx.AsyncClient`) from the start.
- Tooling: `uv` (commit `uv.lock`), `ruff` (lint + format), `mypy --strict`, `pytest`,
  `hypothesis`, `testcontainers`, `import-linter`.
- `ruff` rule sets include `DTZ` (no naive `datetime`, no `date.today()`), `ASYNC`, `UP`, `B`.

## Flutter app (`app/`)

Feature-first Clean Architecture with BLoC, sized to this task.

```bash
cd app
fvm install                                                        # once: the SDK from app/.fvmrc
fvm flutter run --dart-define-from-file=env/ios-simulator.json     # iOS simulator, API from `make up`
fvm flutter run --dart-define-from-file=env/android-emulator.json  # Android emulator
cp env/local.example.json env/local.json                           # phone on the same network:
fvm flutter run --dart-define-from-file=env/local.json             #   put the computer's IP there
TZ=America/New_York fvm flutter test   # time code must not depend on the machine's zone
make -C .. gate-app                    # format check, analyze, tests: the app half of `make gate`
```

- Flutter stable 3.47.6 (Dart 3.13.5), pinned in `app/.fvmrc`; CI reads the same file.
- Feature layout: `data/{datasources,repositories}`, `domain/{models,repositories}`,
  `presentation/{bloc,screens,widgets}`. The checks against Flutter's official architecture
  recommendations are in `docs/architecture.md`.
- Repository implementations use `HandleErrorMixin` and return `Result<T>`. Datasources throw;
  the mixin maps `DioException` to a sealed `Failure`. Widgets show `Failure` messages, never raw
  exception text.
- `422` maps to `ValidationFailure` with per-field errors; `409` maps to `ConflictFailure`.
  Error bodies are API models in `core/network/api_error.dart`; they never reach the domain.
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
    drops it when the day changes. `AddTripState` keeps `tripId` and field errors across
    submissions. Sealed subclasses only for truly exclusive states.
  - Events are past tense: `DayStarted`, `DayChanged`, `DayRefreshRequested`, `TripSubmitted`.
  - Every handler checks `if (isClosed || emit.isDone) return;` after each `await`.
  - Loading or switching a day: `restartable()`. Submitting a form: `droppable()`.
  - Blocs never reference each other. On a saved trip, a `BlocListener<AddTripBloc>` in the
    screen closes the sheet and adds `DayRefreshRequested` to `DayBloc`.
- freezed 3+: declare classes `abstract` (one constructor) or `sealed` (several). Match them with
  Dart 3 `switch` patterns, not `when` / `maybeWhen`.
- New trip ids are `Uuid().v7()`.
- DI through constructors, registered with `@injectable` / `@lazySingleton`; `get_it` is touched
  only in `di/` and at the widget tree root.
- Show trip times and "today" in `Asia/Almaty` via the `timezone` package. Never `toLocal()`.
- UI is Material 3 themed from `core/theme/` (D11): seeded light and dark schemes following the
  system setting, system fonts. Widgets read colors, text styles and spacing from the theme —
  no `Color(0x…)` literals or magic numbers in feature widgets.
- One UI for both platforms. Use adaptive APIs where platforms differ: `CupertinoDatePicker` in
  a bottom sheet on iOS vs `showDatePicker` / `showTimePicker` on Android, `showAdaptiveDialog`
  + `AlertDialog.adaptive`, `.adaptive` progress and refresh indicators. No Cupertino-only
  screens, no third-party UI kits.
- Money uses tabular figures (`FontFeature.tabularFigures()`) and has a screen-reader label.
- Screens must survive 200% text scale and the dark theme without overflow; widget tests cover
  both.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) are committed. Run `make gen`
  after changing annotated files.
- Tests use fakes (`class FakeTripsRepository extends Fake implements TripsRepository`), not
  mocks. Bloc tests assert emitted states in order. One feature test drives the screen with real
  blocs and the fake repository: open a day → add a trip → see the updated summary.
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
