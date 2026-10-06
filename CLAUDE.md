# CLAUDE.md

This file is the canonical source for project rules. `AGENTS.md` only points here.

## Project

Driver shift diary — a test assignment: a FastAPI backend and a Flutter client that show a
driver's trips and daily summary, and add trips without duplicates.

Read before writing code:

- `docs/requirements.md` — what must work (R*), what to deliver (D*), extras (X*).
- `docs/decisions.md` — decisions D1–D11. Code must follow them; a change that contradicts one
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
- One package per feature (`app/trips/`), layout from `docs/architecture.md`. Layers are defined
  by import direction: `router | seed` → `service` → `repository` → `domain` → `models`.
  `import-linter` enforces it in CI.
- No ports/adapters, abstract repositories or DI containers: each would have one implementation.
  Inject with FastAPI `Depends`.
- `router.py` handles HTTP only. `service.py` orchestrates. `domain.py` and `models.py` never
  import FastAPI or psycopg.
- One Pydantic `Trip` model serves the API and the logic. No DTO mirrors.
- Duplicate protection is one atomic statement: `insert_if_absent` runs
  `INSERT … ON CONFLICT (id) DO NOTHING RETURNING` and reads the stored row only when nothing was
  inserted. Never read → compare → insert.
- `create_trip` returns `Created | Repeated | Conflict`; the router maps it with `match`.
- `summarize()`, `day_window()` and `same_trip()` are pure and unit-tested without a database
  (`tests/unit/`).
- Database tests (`tests/integration/`) run against real Postgres 18 started by `testcontainers`,
  never mocks: the concurrency test is meaningless otherwise. `uv run pytest` needs only Docker,
  locally and in CI.
- Tooling: `uv` (commit `uv.lock`), `ruff` (lint + format), `mypy --strict`, `pytest`,
  `hypothesis`, `testcontainers`, `import-linter`.
- `ruff` rule sets include `DTZ` (no naive `datetime`, no `date.today()`), `ASYNC`, `UP`, `B`.

## Flutter app (`app/`)

Feature-first Clean Architecture with BLoC, sized to this task.

- Flutter stable 3.47 (Dart 3.13), pinned in `.fvmrc`.
- Feature layout: `data/{datasources,repositories}`, `domain/{models,params,repositories}`,
  `presentation/{bloc,screens,widgets}`.
- Repository implementations use `HandleErrorMixin` and return `Result<T>`. Datasources throw;
  the mixin maps `DioException` to a sealed `Failure`. Widgets show `Failure` messages, never raw
  exception text.
- `422` maps to `ValidationFailure` with per-field errors; `409` maps to `ConflictFailure`.
- JSON parses straight into domain models (`freezed` + `json_serializable`). No DTO mirrors.
  `build.yaml` sets `field_rename: snake` globally; no per-field `@JsonKey(name:)` for snake_case.
- No use cases: they would only forward to the repository. Add one only when it carries logic.
- BLoC only for state. Events and states are `freezed` sealed classes. Every handler checks
  `if (isClosed || emit.isDone) return;` after each `await`.
  - Loading or switching a day: `restartable()`.
  - Submitting a form: `droppable()`.
- Match sealed classes with Dart 3 `switch` patterns, not `when` / `maybeWhen`.
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
  mocks. Bloc tests assert emitted states in order.
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
