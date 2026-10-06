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

Модули по доменам, как в [fastapi-best-practices](https://github.com/zhanymkanov/fastapi-best-practices)
(по образцу Netflix Dispatch): у каждого модуля свои `router`, `schemas`, `service`,
`dependencies`. Из Clean Architecture взят один принцип — домен не зависит от фреймворков.
Абстрактных репозиториев, Unit of Work и DI-контейнера нет: у каждого интерфейса была бы одна
реализация, транзакция — один SQL-запрос, а внедрение зависимостей уже есть в FastAPI (`Depends`).

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
│   ├── config.py            pydantic-settings: DATABASE_URL, DRIVER_TZ, путь к trips.json
│   ├── database.py          AsyncConnectionPool
│   └── trips/
│       ├── router.py        эндпоинты, response_model, коды 201 / 200 / 409
│       ├── schemas.py       Pydantic: TripCreate (правила D5), TripOut, DaySummaryOut, DayReportOut,
│       │                    ошибки; перевод в домен и обратно
│       ├── domain.py        dataclass Trip, DaySummary; summarize() (D6), day_window() (D1, D2),
│       │                    same_trip() (D4) — только стандартная библиотека
│       ├── repository.py    SQL ↔ domain.Trip: list_between(), insert_if_absent() с ON CONFLICT (D4)
│       ├── service.py       get_day(), create_trip() → Created | Repeated | Conflict
│       ├── dependencies.py  Depends: соединение из пула, сервис
│       ├── seed.py          trips.json → TripCreate → service.create_trip()
│       └── schema.sql
└── tests/
    ├── unit/                domain: сводка, границы дня, полночь, сравнение поездок — без базы
    └── integration/         repository и API на Postgres: 201 / 200 / 409 / 422, 20 одновременных запросов
```

| Файл | Аналог во Flutter | Делает | Не делает |
|---|---|---|---|
| `router.py` | `presentation/` | Принимает схему, вызывает сервис, по исходу выбирает код ответа и собирает схему ответа | Не ходит в базу, не считает |
| `schemas.py` | нет, см. ниже | Форма данных API: проверка входа (D5), формат выхода, перевод в домен и обратно | Не содержит бизнес-логики |
| `dependencies.py` | `di/` | Отдаёт роутеру соединение и сервис через `Depends` | — |
| `service.py` | логика блока | День: окно → выборка → сводка. Новая поездка: вставка → сравнение → исход | Не знает про HTTP и схемы |
| `repository.py` | `data/` | SQL, строки базы → `domain.Trip` | Без интерфейса: реализация одна |
| `domain.py` | `domain/` | Модели и чистые функции | Не импортирует FastAPI, Pydantic и psycopg |

### Схемы API и домен

На сервере схемы API (`schemas.py`) и домен (`domain.py`) — разные классы. Это стандарт FastAPI:
официальная документация (раздел «Extra Models») и официальный шаблон full-stack-fastapi-template
заводят отдельные модели для входа, выхода и хранения. Здесь они и правда различаются:

| Модель | Особенность |
|---|---|
| `TripCreate` (вход) | Строгие типы, лишние поля запрещены, время с любым смещением, правила D5 |
| `TripOut` (выход) | Время переведено в пояс водителя (`+05:00`) — это представление, домен о нём не знает |
| `DayReportOut` (выход) | Поля ответа за день: `date`, `timezone`, `summary`, `trips` |
| `domain.Trip` | Время с поясом без формата вывода; только стандартная библиотека |

На клиенте отдельных DTO нет: клиент не владеет контрактом и ничего не хранит, поэтому JSON
разбирается прямо в доменные модели. Сервер контракт определяет, и его форма меняется
независимо от домена.

### Правила

- **Правила проверки D5 — в `TripCreate`.** Через него идут и API, и загрузка `trips.json`:
  правила в одном месте, ошибки `422` указывают на поле.
- **Сервис и репозиторий работают только с `domain`.** Перевод между схемами и доменом —
  в `schemas.py`, вызывают его роутер и `seed.py`.
- **У каждого эндпоинта `response_model`**: ответ проверяется и совпадает с документацией `/docs`.
- **Защита от дублей — одна атомарная операция в базе.** `insert_if_absent` делает
  `INSERT … ON CONFLICT (id) DO NOTHING RETURNING` и только если строка не вставилась, читает
  сохранённую. Сервис сравнивает её с пришедшей через `same_trip()`. Последовательность
  «прочитать → сравнить → вставить» запрещена: это гонка (D4).
- **Исход `create_trip`** — `Created | Repeated | Conflict`, роутер разбирает его через `match`.
  Аналог sealed `Result` в Dart.
- **Начальные данные** идут через `TripCreate` и тот же `create_trip`: те же проверки, и повторный
  запуск не плодит дубли.
- **Зависимости проверяет CI** — два контракта `import-linter`:
  - слои `router | seed` → `schemas | dependencies` → `service` → `repository` → `domain`;
    нижний слой не импортирует верхний;
  - `domain` не импортирует `fastapi`, `pydantic` и `psycopg`.

Тесты из `tests/unit/` идут без базы. Тесты из `tests/integration/` — на настоящем Postgres 18,
который поднимает `testcontainers`. `uv run pytest` требует только Docker и одинаково работает
локально и в CI. На моках гонку не воспроизвести. Тесты API с самого начала идут через
асинхронный клиент `httpx.AsyncClient` — на нём же тест 20 одновременных запросов.

## Клиент

Feature-first, Clean Architecture, BLoC — в объёме, который нужен этой задаче.

### Сверка с рекомендациями Flutter

Официальные рекомендации по архитектуре (docs.flutter.dev/app-architecture) и пример compass_app
из `flutter/samples`. Уровни: strong — делать всегда, recommend — советуют, conditional — только
при условиях.

| Рекомендация | Уровень | У нас |
|---|---|---|
| Слои данных и интерфейса, паттерн «репозиторий» | strong | `data/`, `presentation/` |
| Абстрактные репозитории | strong | `TripsRepository` и его реализация |
| Без логики в виджетах, однонаправленный поток данных | strong | BLoC — в терминах Flutter он играет роль ViewModel |
| Неизменяемые модели, freezed | strong / recommend | ✓ |
| Внедрение зависимостей | strong | get_it + injectable |
| Фейки в тестах; компоненты по отдельности и вместе | strong | фейковый репозиторий, тесты блоков, тест фичи целиком |
| Доменный слой с use cases | conditional: «в большинстве приложений use cases добавляют лишнюю нагрузку» | без use cases |
| Отдельные модели API и домена | conditional: «для больших приложений» | без DTO; исключение — тела ошибок |
| go_router для навигации | recommend | навигации нет: один экран и нижний лист |

Сознательные отличия от compass_app: интерфейс репозитория лежит в `domain/`, как в Clean
Architecture, а не в `data/`; папки называются `datasources/` и `bloc/`, а не `services/`
и `view_models/`.

### Стек

Flutter 3.47 (Dart 3.13), версия закреплена в `.fvmrc`.

`flutter_bloc` + `bloc_concurrency`, `get_it` + `injectable`, `dio` + `retrofit`,
`freezed` + `json_serializable`, `timezone`, `intl`, `uuid`.
Тесты: `flutter_test`, `bloc_test`, `fake_async`.
Линты: `flutter_lints` и строгие правила в `analysis_options.yaml`, включая режимы языка
`strict-casts`, `strict-inference`, `strict-raw-types`.

### Структура

```
app/
├── env/                                  адрес API для разных сборок (см. «Окружения»)
└── lib/
    ├── main.dart
    └── src/
        ├── core/
        │   ├── config/env.dart           API_BASE_URL из --dart-define
        │   ├── domain/result.dart        Result<T>: SuccessResult / ErrorResult
        │   ├── error/failure.dart        sealed Failure, isTransient
        │   ├── network/http_client.dart  Dio с таймаутами и логированием
        │   ├── network/handle_error_mixin.dart  HandleErrorMixin: DioException → Failure
        │   ├── network/api_error.dart    тела ошибок 422 и 409 — модели API, не домена
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
            │   └── repositories/trips_repository.dart          getDay(date), addTrip(Trip)
            └── presentation/
                ├── bloc/        day_bloc, add_trip_bloc
                ├── screens/     shift_diary_screen
                └── widgets/     summary_card, day_switcher, trip_tile, add_trip_sheet
```

### Правила

- **Ошибки.** Репозиторий оборачивает вызовы в `handleError` из `HandleErrorMixin` и возвращает
  `Result<T>`. `Failure` — sealed: `ConnectionFailure`, `TimeoutFailure`, `ValidationFailure`
  (ошибки по полям из `422`), `ConflictFailure` (`409`), `BadResponseFailure`,
  `UnexpectedFailure`. `isTransient` решает, можно ли повторить запрос (D7). Тела ошибок `422`
  и `409` разбираются в `core/network/api_error.dart`: это модели API, в домен они не попадают.
  Всё, что зависит от Dio, лежит в `core/network/`, и миксин тоже
  (`core/network/handle_error_mixin.dart`). Поэтому `Failure` и `Result` не импортируют Dio,
  и домен от него не зависит.
- **Модели.** JSON разбирается прямо в доменные модели (`freezed` + `json_serializable`),
  отдельных DTO-копий нет (почему на сервере иначе — в разделе «Схемы API и домен»).
  `field_rename: snake` задан один раз в `build.yaml`, поэтому `@JsonKey(name:)` на каждом поле
  не нужен.
- **Новая поездка — сразу полный `Trip`.** `id` генерирует клиент, поэтому отдельные параметры
  (`params/new_trip`) не нужны: репозиторий принимает `addTrip(Trip)`. Черновик формы
  с незаполненными полями — это состояние блока, а не домен.
- **Состояние блоков — один `freezed`-класс со `status`.** Документация bloc (раздел «Modeling
  State») советует такой вариант, когда нужно показать ошибку, не теряя прошлые данные.
  Sealed-подклассы — только для взаимоисключающих состояний.
  - `DayState`: `date`, `status` (`loading`, `success`, `failure`), `report`, `failure`. При смене
    дня `report` сбрасывается. При обновлении того же дня он остаётся на экране, пока идёт запрос,
    и не пропадает при ошибке.
  - `AddTripState`: `tripId` (UUIDv7, создаётся при открытии формы), `status` (`editing`,
    `submitting`, `success`, `failure`), ошибки полей. `tripId` переживает повторные отправки (D7).
- **События и конкурентность.** События — в прошедшем времени, по соглашению bloc: `DayStarted`,
  `DayChanged`, `DayRefreshRequested`, `TripSubmitted`. После каждого `await` —
  `if (isClosed || emit.isDone) return;`.
  - `DayBloc`: `restartable()`. Быстрое переключение дней отменяет устаревший запрос, и экран
    не покажет данные чужого дня.
  - `AddTripBloc`: `droppable()` на отправку; повтор только при `isTransient` и с тем же `tripId`.
- **Блоки не знают друг о друге.** Документация bloc: зависимостей между блоками одного слоя
  избегать. После успешного сохранения `BlocListener<AddTripBloc>` на экране закрывает форму
  и отправляет в `DayBloc` событие `DayRefreshRequested` для дня поездки.
- **freezed 3+.** Класс объявляется с `abstract` (один конструктор) или `sealed` (несколько).
  В виджетах — `switch` с сопоставлением с образцом, а не `when` / `maybeWhen`.
- **Время.** `DateTime.parse` теряет смещение, а `toLocal()` переводит в пояс телефона.
  Время поездок и «сегодня» показываются в `Asia/Almaty` через пакет `timezone`.
- **Тесты.**
  - Фейки вида `extends Fake implements TripsRepository`, а не моки.
  - Тесты блоков проверяют порядок состояний.
  - Smoke-тест DI: граф зависимостей собирается.
  - Тест фичи целиком: экран с настоящими блоками и фейковым репозиторием — открыть день →
    добавить поездку → увидеть обновлённую сводку.

### Окружения

Почему так — [D12](decisions.md#d12-адрес-api-и-демо-бэкенд-в-интернете).

Адрес API задаётся при сборке: `--dart-define-from-file=env/<файл>.json` с ключом `API_BASE_URL`.
В коде его читает `core/config/env.dart`.

| Файл | Адрес | Для чего |
|---|---|---|
| `env/android-emulator.json` | `http://10.0.2.2:8000` | Эмулятор Android, бэкенд из `make up` |
| `env/ios-simulator.json` | `http://localhost:8000` | Симулятор iOS |
| `env/local.json` (в `.gitignore`, пример — `local.example.json`) | `http://<IP компьютера>:8000` | Телефон в той же сети |
| `env/prod.json` | `https://…` | APK в Releases и демо |

Локальный `http` по умолчанию блокируют обе платформы. На Android он разрешён только в
отладочной сборке (`usesCleartextTraffic` в `src/debug/AndroidManifest.xml`), на iOS — только
для локальной сети (`NSAllowsLocalNetworking` в `Info.plist`). Сборка для Releases ходит по HTTPS.

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
| Use cases | Они бы только вызывали репозиторий. Логики на клиенте нет — деньги считает сервер (D6). У Flutter это conditional-рекомендация |
| DTO-копии моделей | Клиент не владеет контрактом и ничего не хранит; отдельные модели — только для тел ошибок. На сервере схемы есть (см. «Схемы API и домен») |
| Роутер | Один экран и нижний лист. Со вторым экраном появится go_router — его рекомендует Flutter |
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
