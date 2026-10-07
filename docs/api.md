# API

Базовый путь: `/api/v1`. Формат — JSON. Время — ISO 8601 со смещением, в ответах всегда
в поясе водителя (`+05:00`). Суммы — целые тенге.

Описание FastAPI генерирует автоматически: `/docs` (Swagger UI) и `/openapi.json`.
Этот файл — договорённость до кода; если они разойдутся, прав код, а файл нужно поправить.

## Модель поездки

```json
{
  "id": "t1",
  "start": "2026-10-01T08:10:00+05:00",
  "end": "2026-10-01T08:32:00+05:00",
  "amount": 2400,
  "payment": "card",
  "commission": 360
}
```

Правила проверки — в [decisions.md](decisions.md#d5-проверка-данных).

## `GET /api/v1/days/{date}`

Сводка и поездки за день. `date` — дата в поясе водителя, `YYYY-MM-DD`.
Какие поездки попадают в день — [D1](decisions.md#d1-день--по-часовому-поясу-водителя),
[D2](decisions.md#d2-поездка-через-полночь).

**200 OK**

```json
{
  "date": "2026-10-01",
  "timezone": "Asia/Almaty",
  "summary": {
    "trips_count": 2,
    "revenue": 3900,
    "commission": 585,
    "net": 3315,
    "by_payment": {"cash": 1500, "card": 2400}
  },
  "trips": [
    {"id": "t1", "start": "2026-10-01T08:10:00+05:00", "end": "2026-10-01T08:32:00+05:00",
     "amount": 2400, "payment": "card", "commission": 360},
    {"id": "t2", "start": "2026-10-01T09:05:00+05:00", "end": "2026-10-01T09:20:00+05:00",
     "amount": 1500, "payment": "cash", "commission": 225}
  ]
}
```

- `net` — «на руки»: `revenue − commission`.
- `by_payment` — выручка по способу оплаты; `cash + card = revenue`.
- `trips` отсортированы по началу.
- День без поездок — `200` с нулями и пустым списком, не `404`.

**422** — дата не в формате `YYYY-MM-DD` или вне диапазона `0001-01-02` … `9999-12-30`.

## `GET /api/v1/periods/{start}/{end}`

Сводка за несколько дней подряд: неделя или месяц. `start` и `end` — первый и последний день
в поясе водителя, `YYYY-MM-DD`, оба включительно. Поездка относится к дню своего начала, как
в `GET /days/{date}`. Почему так — [D14](decisions.md#d14-сводка-за-неделю-и-месяц).

**200 OK** — `GET /api/v1/periods/2026-09-28/2026-10-04`

```json
{
  "start": "2026-09-28",
  "end": "2026-10-04",
  "timezone": "Asia/Almaty",
  "summary": {
    "trips_count": 9,
    "revenue": 21040,
    "commission": 3156,
    "net": 17884,
    "by_payment": {"cash": 8900, "card": 12140}
  },
  "days": [
    {"date": "2026-09-28", "summary": {"trips_count": 0, "revenue": 0, "commission": 0,
      "net": 0, "by_payment": {"cash": 0, "card": 0}}},
    {"date": "2026-09-29", "summary": {"trips_count": 0, "revenue": 0, "commission": 0,
      "net": 0, "by_payment": {"cash": 0, "card": 0}}},
    {"date": "2026-09-30", "summary": {"trips_count": 3, "revenue": 7100, "commission": 1065,
      "net": 6035, "by_payment": {"cash": 3200, "card": 3900}}},
    {"date": "2026-10-01", "summary": {"trips_count": 2, "revenue": 3900, "commission": 585,
      "net": 3315, "by_payment": {"cash": 1500, "card": 2400}}},
    {"date": "2026-10-02", "summary": {"trips_count": 3, "revenue": 8540, "commission": 1281,
      "net": 7259, "by_payment": {"cash": 2700, "card": 5840}}},
    {"date": "2026-10-03", "summary": {"trips_count": 1, "revenue": 1500, "commission": 225,
      "net": 1275, "by_payment": {"cash": 1500, "card": 0}}},
    {"date": "2026-10-04", "summary": {"trips_count": 0, "revenue": 0, "commission": 0,
      "net": 0, "by_payment": {"cash": 0, "card": 0}}}
  ]
}
```

- `summary` и `summary` каждого дня — та же сводка, что в `GET /days/{date}`.
- `days` — каждый день диапазона по порядку, день без поездок — с нулями.
- Сумма сводок дней равна `summary`: оба считаются из одного списка поездок.
- Списка поездок нет: его отдаёт `GET /days/{date}`.

**422** — `loc` и `type`:

| `loc` | `type` | Когда |
|---|---|---|
| `["path", "start"]`, `["path", "end"]` | `date_format` | дата не в формате `YYYY-MM-DD` |
| `["path", "start"]`, `["path", "end"]` | `date_out_of_range` | дата вне `0001-01-02` … `9999-12-30` |
| `["path", "end"]` | `period_end_before_start` | `end` раньше `start` |
| `["path", "end"]` | `period_too_long` | больше 31 дня |

## `POST /api/v1/trips`

Добавить поездку. Тело — модель поездки, `id` задаёт клиент. Время в теле — с любым смещением;
в ответах `201` и `200` оно, как и в `GET /days/{date}`, в поясе водителя.

| Ответ | Когда |
|---|---|
| `201 Created` + поездка | Поездки с таким `id` не было |
| `200 OK` + сохранённая поездка | Повтор: тот же `id`, те же данные |
| `409 Conflict` | Тот же `id`, другие данные |
| `422 Unprocessable Entity` | Данные не прошли проверку |

Почему так — [D4](decisions.md#d4-защита-от-дублей-id-поездки-как-ключ). Время сравнивается
по моменту: `08:10+05:00` и `03:10Z` — те же данные.

Поездка сохраняется до того, как уходит ответ: клиент, получивший `201`, следующим
`GET /days/{date}` уже видит её в сводке.

## Ошибки

### `422`

Формат — стандартный для FastAPI: `detail` со списком ошибок, у каждой `loc`, `type` и `msg`
(бывают ещё `input` и `ctx`).

- `loc` — где ошибка. Поле тела — второй элемент, только если это строка: `["body", "amount"]`.
  `["body"]` — ошибка всего тела. У битого JSON (`json_invalid`) второй элемент — число,
  позиция в тексте, а не поле. Ошибки всего тела клиент показывает для всей формы, а не под
  полем.
- `type` — причина. По полю и `type` клиент выбирает свой текст. Для `type`, которого нет
  в таблице ниже, — общий текст: Pydantic может добавить новые коды.
- `msg` — английский текст Pydantic для разработчика. Он меняется между версиями Pydantic,
  водителю его не показывают.

```json
{
  "detail": [
    {"type": "greater_than", "loc": ["body", "amount"], "msg": "Input should be greater than 0",
     "input": 0, "ctx": {"gt": 0}}
  ]
}
```

Причины `422` в `POST /api/v1/trips`, правила — в [D5](decisions.md#d5-проверка-данных):

| Поле | `type` | Когда |
|---|---|---|
| любое | `missing` | поля нет |
| лишнее | `extra_forbidden` | поля нет в модели поездки |
| `id` | `string_type` | не строка |
| `id` | `string_too_short`, `string_too_long` | пустой, длиннее 64 символов |
| `id` | `string_pattern_mismatch` | есть символы кроме латиницы, цифр, `-` и `_` |
| `start`, `end` | `datetime_format` | не строка ISO 8601, например Unix-время |
| `start`, `end` | `timezone_aware` | время без смещения |
| `start`, `end` | `datetime_out_of_range` | в UTC вне 0001-01-02 … 9999-12-30 |
| `end` | `end_not_after_start` | окончание не позже начала |
| `amount`, `commission` | `int_type` | не целое число: `2400.5`, `2400.0`, `"2400"`, `true`, `null` |
| `amount` | `greater_than` | 0 или меньше |
| `amount` | `less_than_equal` | больше 2 147 483 647 |
| `commission` | `greater_than_equal` | меньше 0 |
| `commission` | `commission_above_amount` | больше `amount` |
| `payment` | `enum` | не `cash` и не `card` |
| всё тело | `missing` | тела нет |
| всё тело | `model_attributes_type` | тело не объект: `[]`, `"abc"`, а также тело не в JSON (`text/plain`) |
| всё тело | `json_invalid` | JSON не разобрать; второй элемент `loc` — позиция в тексте |

### `409`

```json
{
  "detail": {
    "code": "trip_conflict",
    "message": "Поездка с id t1 уже сохранена с другими данными"
  }
}
```
