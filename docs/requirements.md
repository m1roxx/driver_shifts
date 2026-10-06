# Требования

Требования тестового задания arqa («Дневник смен водителя») своими словами, с номерами.
Каждое требование потом связывается с кодом и тестом — эта таблица переедет в README.

Статусы: `план` → `в работе` → `готово`.

## Из задания

| ID | Требование | Где в коде | Тест | Статус |
|---|---|---|---|---|
| R1 | Сервер по API отдаёт список поездок за выбранный день | `GET /api/v1/days/{date}` в `backend/app/trips/router.py`, границы дня — `day_window()` в `backend/app/trips/domain.py` | `backend/tests/integration/test_days_api.py`, `backend/tests/unit/test_day_window.py` | готово |
| R2 | Сервер по API отдаёт сводку за день: число поездок, выручка, комиссия, «на руки», наличные / карта | `summarize()` в `backend/app/trips/domain.py`, `GET /api/v1/days/{date}` | `backend/tests/unit/test_summarize.py`, `backend/tests/integration/test_days_api.py` | готово |
| R3 | Клиент показывает сводку и список поездок за день | `ShiftDiaryScreen`, `SummaryCard`, `TripTile` в `app/lib/src/features/shift_diary/presentation/`; `GET /days/{date}` — `TripsRepositoryImpl` в `app/lib/src/features/shift_diary/data/` | `app/test/src/features/shift_diary/presentation/screens/shift_diary_screen_test.dart`, `app/test/src/features/shift_diary/domain/models/day_report_test.dart` | готово |
| R4 | Клиент переключает дни | `DayBloc` (`restartable()`) и `DaySwitcher` в `app/lib/src/features/shift_diary/presentation/` | `app/test/src/features/shift_diary/presentation/bloc/day_bloc_test.dart`, `app/test/src/features/shift_diary/presentation/screens/shift_diary_screen_test.dart` | готово |
| R5 | Поездку можно добавить через API | `POST /api/v1/trips` в `backend/app/trips/router.py`; в клиенте — `AddTripSheet` и `AddTripBloc` в `app/lib/src/features/shift_diary/presentation/`, `TripsRepositoryImpl.addTrip` в `app/lib/src/features/shift_diary/data/` | `backend/tests/integration/test_create_trip_api.py`, `app/test/src/features/shift_diary/presentation/screens/add_trip_test.dart`, `app/test/src/features/shift_diary/presentation/bloc/add_trip_bloc_test.dart` | готово |
| R6 | Проверка данных: сумма > 0 | `TripCreate` в `backend/app/trips/schemas.py`, CHECK в `backend/app/trips/schema.sql` | `backend/tests/unit/test_trip_create.py`, `backend/tests/integration/test_create_trip_api.py`, `backend/tests/integration/test_schema.py` | готово |
| R7 | Проверка данных: окончание позже начала | `TripCreate` в `backend/app/trips/schemas.py`, CHECK в `backend/app/trips/schema.sql` | `backend/tests/unit/test_trip_create.py`, `backend/tests/integration/test_create_trip_api.py`, `backend/tests/integration/test_schema.py` | готово |
| R8 | Повторная отправка той же поездки не создаёт дубль | `insert_if_absent()` с `INSERT … ON CONFLICT` в `backend/app/trips/repository.py`, `same_trip()` в `backend/app/trips/domain.py`, `POST /api/v1/trips` | `backend/tests/integration/test_create_trip_api.py`, `backend/tests/unit/test_same_trip.py` | готово |
| R9 | Тесты на расчёт сводки | `summarize()` в `backend/app/trips/domain.py` | `backend/tests/unit/test_summarize.py` | готово |
| R10 | Тесты на защиту от дублей | `insert_if_absent()` в `backend/app/trips/repository.py`, `same_trip()` в `backend/app/trips/domain.py` | `backend/tests/integration/test_create_trip_api.py` (повтор, другое смещение, `409`, 20 одновременных запросов), `backend/tests/unit/test_same_trip.py` | готово |
| R11 | Исходные данные — JSON-файл с поездками (id, начало, окончание, сумма, способ оплаты, комиссия) | `data/trips.json`, загрузка при старте — `backend/app/trips/seed.py` | `backend/tests/unit/test_read_trips.py`, `backend/tests/integration/test_seed.py` | готово |

## Что сдать

| ID | Что | Статус |
|---|---|---|
| D1 | Публичный репозиторий (GitHub) | план |
| D2 | README: как запустить и что сделано | план |
| D3 | Демо или скриншоты (необязательно) | план |
| D4 | Как использовал ИИ, где он ошибся, что исправил сам → [ai-log.md](ai-log.md) | план |

## Сверх задания

То, чего в задании нет, но без чего это не «работающая сборка».

| ID | Что | Зачем | Статус |
|---|---|---|---|
| X1 | Запуск бэкенда одной командой (`docker compose up`) | Проверяющий не должен ставить Python и Postgres | план |
| X2 | CI: линтеры, типы, тесты бэкенда и клиента | Каждое изменение проходит автопроверки | готово |
| X3 | CI: проверка, что сгенерированный Dart-код не устарел | Закоммиченные `*.g.dart` не расходятся с исходниками | готово |
| X4 | APK в GitHub Releases | Демо «на телефоне, а не в отчёте» | план |
| X5 | Дополнительная проверка данных (комиссия, способ оплаты, смещение во времени) | См. [decisions.md](decisions.md#d5-проверка-данных) | готово |
| X6 | Защита от дублей на всём пути: от кнопки до базы | См. [decisions.md](decisions.md#d7-повторы-на-клиенте) | готово |
| X7 | Интерфейс под водителя: тёмная тема, крупный текст, привычное поведение на iOS и Android | См. [decisions.md](decisions.md#d11-интерфейс-material-3-и-адаптивное-поведение) | готово |
| X8 | Бэкенд доступен из интернета по HTTPS, APK из Releases работает на любом телефоне | См. [decisions.md](decisions.md#d12-адрес-api-и-демо-бэкенд-в-интернете) | план |

## Пример данных из задания

```json
[
  {"id": "t1", "start": "2026-10-01T08:10:00+05:00", "end": "2026-10-01T08:32:00+05:00",
   "amount": 2400, "payment": "card", "commission": 360},
  {"id": "t2", "start": "2026-10-01T09:05:00+05:00", "end": "2026-10-01T09:20:00+05:00",
   "amount": 1500, "payment": "cash", "commission": 225}
]
```

Ожидаемая сводка за 01.10.2026: 2 поездки, выручка 3 900 ₸, комиссия 585 ₸, на руки 3 315 ₸,
наличные / карта 1 500 / 2 400 ₸.
