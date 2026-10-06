# Архитектура

Монорепозиторий: бэкенд на Python, клиент на Flutter, общие данные и документация.

```
driver_shifts/
├── backend/            FastAPI + Postgres
├── app/                Flutter-клиент (Android, iOS, web)
├── data/trips.json     начальные данные из задания
├── docs/               требования, решения, API, план, журнал ИИ
├── docker-compose.yml  API + Postgres одной командой
├── Makefile            gen, gate, up, test
└── .github/workflows/  CI и сборка APK
```

```
Flutter-клиент ──HTTP/JSON──▶ FastAPI ──SQL──▶ Postgres
  DayBloc        GET  /days/{date}   summarize()     trips (id PK)
  AddTripBloc    POST /trips         ON CONFLICT
```

## Бэкенд

Модуль на фичу, как на клиенте. Слои разделены направлением зависимостей, а не папками.
Портов, адаптеров, абстрактных репозиториев и DI-контейнера нет: у каждого интерфейса была бы
одна реализация, а внедрение зависимостей уже есть в FastAPI (`Depends`).

### Стек

| Что | Выбор |
|---|---|
| Язык | Python 3.14 |
| Веб | FastAPI (`fastapi[standard]`), эндпоинты `async def` |
| Модели и настройки | Pydantic v2, `pydantic-settings` |
| База | Postgres 18, асинхронный psycopg 3 с пулом (`psycopg[binary,pool]`, `AsyncConnectionPool`) |
| Зависимости | `uv`, `uv.lock` в репозитории |
| Проверки | `ruff` (линтер и форматтер), `mypy --strict`, `import-linter` |
| Тесты | `pytest`, `hypothesis`, `testcontainers` |

- **Только актуальные идиомы.** `lifespan` вместо `@app.on_event`, зависимости через
  `Annotated[..., Depends(...)]`, API Pydantic v2 (`model_config`, `model_dump()`,
  `field_validator`). ИИ по старым примерам пишет `class Config`, `.dict()`, `@validator` —
  это ловится на ревью.
- **`ruff` с правилами `DTZ`**: запрещены `datetime` без пояса и `date.today()`. Правило про время
  (D1) проверяет линтер, а не внимательность.
- **Postgres 18 в Docker** хранит данные в `/var/lib/postgresql`, а не в `/var/lib/postgresql/data`,
  как в образах до 18. Том в `docker-compose.yml` монтируется по новому пути.

### Структура

```
backend/
├── pyproject.toml           зависимости и настройки ruff, mypy, pytest, import-linter
├── app/
│   ├── main.py              FastAPI(), lifespan: пул, схема и начальные данные, роутеры
│   ├── core/
│   │   ├── settings.py      DATABASE_URL, DRIVER_TZ, путь к trips.json
│   │   └── db.py            AsyncConnectionPool, соединение через Depends
│   └── trips/
│       ├── models.py        Pydantic: Trip (правила проверки D5), DaySummary, DayReport
│       ├── domain.py        чистые функции: summarize() (D6), day_window() (D1, D2), same_trip() (D4)
│       ├── repository.py    SQL: list_between(), insert_if_absent() с ON CONFLICT (D4)
│       ├── service.py       get_day(), create_trip() → Created | Repeated | Conflict
│       ├── router.py        HTTP: разбор запроса, коды 201 / 200 / 409
│       ├── seed.py          trips.json → service.create_trip()
│       └── schema.sql
└── tests/
    ├── unit/                domain: сводка, границы дня, полночь, сравнение поездок — без базы
    └── integration/         repository и API на Postgres: 201 / 200 / 409 / 422, 20 одновременных запросов
```

| Слой | Аналог во Flutter | Делает | Не делает |
|---|---|---|---|
| `router.py` | `presentation/` | Разбирает запрос, выбирает код ответа по исходу сервиса | Не ходит в базу, не считает |
| `service.py` | логика блока | День: окно → выборка → сводка. Новая поездка: вставка → сравнение → исход | Не знает про HTTP |
| `models.py`, `domain.py` | `domain/` | Модели и чистые функции | Не импортируют FastAPI и psycopg |
| `repository.py` | `data/` | SQL | Без интерфейса: реализация одна |

### Правила

- **Одна модель `Trip`** для API и логики (Pydantic, frozen, strict). Отдельных DTO нет —
  как на клиенте.
- **Защита от дублей — одна атомарная операция в базе.** `insert_if_absent` делает
  `INSERT … ON CONFLICT (id) DO NOTHING RETURNING` и только если строка не вставилась, читает
  сохранённую. Сервис сравнивает её с пришедшей через `same_trip()`. Последовательность
  «прочитать → сравнить → вставить» запрещена: это гонка (D4).
- **Исход `create_trip`** — `Created | Repeated | Conflict`, роутер разбирает его через `match`.
  Аналог sealed `Result` в Dart.
- **Начальные данные** идут через тот же `create_trip`, поэтому повторный запуск не плодит дубли.
- **Направление зависимостей проверяет CI**: контракт слоёв `import-linter` —
  `router | seed → service → repository → domain → models`. Нижний слой не импортирует верхний.

Тесты из `tests/unit/` идут без базы. Тесты из `tests/integration/` — на настоящем Postgres 18,
который поднимает `testcontainers`. `uv run pytest` требует только Docker и одинаково работает
локально и в CI. На моках гонку не воспроизвести.

## Клиент

Feature-first, Clean Architecture, BLoC — в объёме, который нужен этой задаче.

### Стек

Flutter 3.47 (Dart 3.13), версия закреплена в `.fvmrc`.

`flutter_bloc` + `bloc_concurrency`, `get_it` + `injectable`, `dio` + `retrofit`,
`freezed` + `json_serializable`, `timezone`, `intl`, `uuid`.
Тесты: `flutter_test`, `bloc_test`, `fake_async`.
Линты: `flutter_lints` и строгие правила в `analysis_options.yaml`, включая режимы языка
`strict-casts`, `strict-inference`, `strict-raw-types`.

### Структура

```
app/lib/
├── main.dart
└── src/
    ├── core/
    │   ├── domain/result.dart        Result<T>: SuccessResult / ErrorResult
    │   ├── error/failure.dart        sealed Failure, isTransient, HandleErrorMixin
    │   ├── network/http_client.dart  Dio с таймаутами и логированием
    │   ├── time/driver_clock.dart    «сегодня» и форматирование в Asia/Almaty
    │   ├── format/money.dart         2 400 ₸
    │   └── theme/                    светлая и тёмная тема Material 3, отступы, смысловые цвета
    ├── di/injector.dart              injectable, throwOnMissingDependencies
    └── features/shift_diary/
        ├── data/
        │   ├── datasources/trips_remote_datasource.dart   retrofit
        │   └── repositories/trips_repository_impl.dart     HandleErrorMixin
        ├── domain/
        │   ├── models/      trip, day_report, day_summary, payment_method
        │   ├── params/      new_trip
        │   └── repositories/trips_repository.dart
        └── presentation/
            ├── bloc/        day_bloc, add_trip_bloc
            ├── screens/     shift_diary_screen
            └── widgets/     summary_card, day_switcher, trip_tile, add_trip_sheet
```

### Правила

- **Ошибки.** Репозиторий оборачивает вызовы в `handleError` и возвращает `Result<T>`.
  `Failure` — sealed: `ConnectionFailure`, `TimeoutFailure`, `ValidationFailure` (ошибки по полям
  из `422`), `ConflictFailure` (`409`), `BadResponseFailure`, `UnexpectedFailure`.
  `isTransient` решает, можно ли повторить запрос (D7).
- **Модели.** JSON разбирается прямо в доменные модели (`freezed` + `json_serializable`),
  отдельных DTO-копий нет. `field_rename: snake` задан один раз в `build.yaml`, поэтому
  `@JsonKey(name:)` на каждом поле не нужен.
- **Блоки.** События и состояния — `freezed` sealed. После каждого `await` —
  `if (isClosed || emit.isDone) return;`. Состояния в виджетах разбираются через `switch`
  с сопоставлением с образцом, а не через `when` / `maybeWhen`.
  - `DayBloc`: загрузка и смена дня через `restartable()`. Быстрое переключение дней отменяет
    устаревший запрос, и экран не покажет данные чужого дня.
  - `AddTripBloc`: `id` (UUIDv7) генерируется при открытии формы; отправка через `droppable()`;
    повтор только при `isTransient` и с тем же `id`.
- **Время.** `DateTime.parse` теряет смещение, а `toLocal()` переводит в пояс телефона.
  Время поездок и «сегодня» показываются в `Asia/Almaty` через пакет `timezone`.
- **Тесты.** Фейки вида `extends Fake implements TripsRepository`, а не моки.
  Плюс smoke-тест DI: граф зависимостей собирается.

### Интерфейс

Почему так — [D11](decisions.md#d11-интерфейс-material-3-и-адаптивное-поведение).

**Тема.** Material 3, `ColorScheme.fromSeed` от одного цвета, светлая и тёмная версии,
переключаются по системной настройке. Шрифты системные: SF Pro на iOS, Roboto на Android.
Всё лежит в `core/theme/`:

- `ThemeData` для светлой и тёмной темы;
- константы отступов;
- `ThemeExtension` для смысловых цветов, если понадобятся (например, наличные и карта).

Виджеты берут цвета, шрифты и отступы только из темы, без литералов `Color(0x…)` и чисел
на месте.

**Экран дня.**

- Сверху сводка: «На руки» крупно (`headlineLarge`), под ней сетка показателей — поездки,
  выручка, комиссия, наличные / карта.
- Ниже список поездок: время начала и окончания, способ оплаты, сумма.
- Дни переключаются свайпом, стрелками и через выбор даты; кнопка «Сегодня» возвращает
  к текущему дню.
- Суммы печатаются цифрами одинаковой ширины (`FontFeature.tabularFigures()`), чтобы столбец
  не прыгал.
- Состояния: скелетон при загрузке, пустой день с кнопкой «Добавить», ошибка с кнопкой
  «Повторить».

**Форма поездки** (нижний лист):

- сумма и комиссия — цифровая клавиатура, разделитель разрядов;
- время начала и окончания, по умолчанию в выбранный день;
- способ оплаты — `SegmentedButton` «Наличные / Карта»;
- ошибки проверки показываются под полями: локальные сразу, ошибки из `422` после отправки.

**Поведение на iOS и Android.** Один интерфейс, платформенные различия — там, где их замечает
пользователь:

| Что | iOS | Android |
|---|---|---|
| Выбор даты и времени | `CupertinoDatePicker` в нижнем листе | `showDatePicker`, `showTimePicker` |
| Диалоги | `showAdaptiveDialog` + `AlertDialog.adaptive` | то же |
| Индикаторы | `CircularProgressIndicator.adaptive`, `RefreshIndicator.adaptive` | то же |
| Свайп назад, пружинящая прокрутка | Flutter делает сам | — |

Лёгкая вибрация (`HapticFeedback`) — при смене дня и после сохранения поездки.

**Доступность.** Экран дня и форма проверяются при масштабе шрифта 200%: текст переносится,
ничего не обрезается. У сумм есть подписи для экранного диктора («Выручка 3 900 тенге»).
Области нажатия — не меньше 48 × 48.

### Чего нет и почему

| Нет | Почему |
|---|---|
| Use cases | Они бы только вызывали репозиторий. Логики на клиенте нет — деньги считает сервер (D6) |
| DTO-копии моделей | Поля совпадают один в один |
| auto_route | Один экран и bottom sheet |
| Локализация на несколько языков | Задание на русском; строки в одном месте, перевод добавляется позже |
| Crash reporting, аналитика | Нет продакшена, некуда отправлять |
| Локальная база | Нет офлайн-режима (см. «Сознательно не делаем» в decisions.md) |
| Сторонний UI-кит, свои шрифты | Material 3 и системные шрифты закрывают задачу (D11) |
| Отдельный интерфейс на Cupertino | Двойная работа ради одного экрана; платформенные различия закрыты адаптивными виджетами (D11) |

## Сгенерированный код

`*.g.dart`, `*.freezed.dart`, `*.config.dart` коммитятся, чтобы `flutter run` работал сразу
после клонирования. В `.gitattributes` они помечены `linguist-generated=true` — GitHub
сворачивает их в диффах. CI запускает `build_runner` и падает, если сгенерированный код
расходится с закоммиченным.
