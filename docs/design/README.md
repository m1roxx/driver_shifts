# Handoff: редизайн «Дневник смен» (экран дня и форма поездки)

## Обзор
Редизайн UI/UX Flutter-приложения `driver_shifts/app`. Меняются только внешний вид и удобство. Логика (BLoC), API, модели, тексты ошибок сервера и правила денег/времени остаются прежними. Выбранное направление — **1a «Сгруппированный список»**: сгруппированные карточки без теней в духе iOS, широкая кнопка «Добавить поездку» внизу вместо FAB, «Сегодня» — текстовая кнопка в шапке, пометка «+1 день» у поездок через полночь.

## О файлах дизайна
Файлы в `design/` — **макеты в HTML**, они показывают, как должно выглядеть и вести себя приложение. Это не код для копирования. Задача — **воссоздать их во Flutter-приложении** `driver_shifts/app` по его текущим правилам: Material 3, BLoC, injectable, существующие виджеты в `lib/src/features/shift_diary/presentation/widgets/`, инварианты из `CLAUDE.md` / `AGENTS.md` репозитория.

Открыть макеты: `design/Дневник смен - кадры.dc.html` и `design/Дневник смен - спецификация.dc.html` в браузере, рядом должны лежать `support.js`, `DayScreen.dc.html`, `TripSheet.dc.html`, `fonts/`.

## Точность
**High-fidelity.** Цвета, типографика, отступы, состояния и поведение финальные. Hex взяты из `material_color_utilities` (tonalSpot) для seed `#00AFCA`, их же выдаёт `ColorScheme.fromSeed`. Тексты финальные. Если HTML и этот README расходятся, верен README.

## Жёсткие правила (не нарушать)
- Клиент не считает деньги. Показываются только поля сервера: за день — `trips_count, revenue, commission, net, by_payment.cash, by_payment.card`; по поездке — `start, end, amount, commission, payment`.
- Время — всегда Asia/Almaty, 24 часа. Поездка относится ко дню начала. «+1 день» — если календарная дата `end` в Алматы позже даты `start`. Это сравнение дат для отображения, не расчёт денег.
- Деньги — целые тенге, `formatTenge` (неразрывные пробелы), цифры одинаковой ширины (`AppTextStyles.tabularFigures`).
- Без FAB, без теней, без ripple на iOS, без сторонних UI-китов, шрифты системные.
- Вне рамок: редактирование и удаление поездок, авторизация, офлайн-очередь, графики и отчёты.

---

## 1. Тема (`lib/src/core/theme/app_theme.dart`)

```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF00AFCA),
  brightness: brightness,
  dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
);
```
ThemeMode.system. Дополнительно в `ThemeData`:
- `scaffoldBackgroundColor`: светлая — `surfaceContainer`, тёмная — `surface`.
- `cardTheme`: elevation 0, margin zero, shape radius 16, color: светлая — `surfaceContainerLowest`, тёмная — `surfaceContainerHigh`.
- `appBarTheme`: centerTitle true, toolbarHeight 48, elevation 0, scrolledUnderElevation 0, surfaceTintColor transparent, backgroundColor = фон экрана, titleTextStyle = titleMedium w600.
- `dividerTheme`: color `outlineVariant`, thickness 1, space 1.
- `filledButtonTheme`: minimumSize `Size.fromHeight(56)`, shape radius 16, textStyle titleMedium w600. **Тёмная тема:** backgroundColor `primaryContainer`, foregroundColor `onPrimaryContainer`. Светлая — по умолчанию (`primary` / `onPrimary`).
- `bottomSheetTheme`: backgroundColor: светлая — `surfaceContainer`, тёмная — `surfaceContainerLow`; shape radius 28 сверху; modalBarrierColor — scrim 32%.
- iOS (`TargetPlatform.iOS`): `splashFactory: NoSplash.splashFactory`, нажатие — overlay onSurface 8%.
- `inputDecorationTheme.errorMaxLines` оставить (4).

### Роли и hex

| Роль | Светлая | Тёмная | Где |
|---|---|---|---|
| primary | #006879 | #84D2E5 | Стрелки дня, «Сегодня», текстовые кнопки, курсор; основная кнопка (светлая) |
| onPrimary | #FFFFFF | #003640 | Текст основной кнопки (светлая) |
| primaryContainer | #A9EDFF | #004E5B | Основная кнопка (тёмная), выбранные часы в Android-пикере |
| onPrimaryContainer | #004E5B | #A9EDFF | Текст основной кнопки (тёмная) |
| secondaryContainer | #CEE7EE | #334A50 | «+1 день», выбранный сегмент, «Повторить» на экране ошибки, кнопка при отправке |
| onSecondaryContainer | #334A50 | #CEE7EE | Текст на secondaryContainer |
| surface | #F5FAFC | #0F1416 | Фон экрана (тёмная) |
| surfaceContainerLowest | #FFFFFF | #090F11 | Карточки (светлая) |
| surfaceContainerLow | #EFF4F6 | #171D1E | Лист формы (тёмная) |
| surfaceContainer | #E9EFF1 | #1B2122 | Фон экрана, шапки, нижней панели, листа (светлая) |
| surfaceContainerHigh | #E4E9EB | #252B2D | Карточки (тёмная), Android-диалоги |
| surfaceContainerHighest | #DEE3E5 | #303637 | Кнопки даты/времени, скелетон, циферблат |
| onSurface | #171D1E | #DEE3E5 | Основной текст, суммы |
| onSurfaceVariant | #3F484B | #BFC8CB | Подписи, второстепенный текст |
| outline | #6F797B | #899295 | Рамка SegmentedButton |
| outlineVariant | #BFC8CB | #3F484B | Все разделители |
| error | #BA1A1A | #FFB4AB | Текст ошибок под полями, подпись поля с ошибкой |
| errorContainer | #FFDAD6 | #93000A | Плашки ошибок, кружок экрана ошибки |
| onErrorContainer | #93000A | #FFDAD6 | Текст/значки на errorContainer |

Красный — только для ошибок. Комиссия и суммы — `onSurface`.

### ThemeExtension `PaymentColors` (новый файл `core/theme/payment_colors.dart`)
Палитры: `TonalPalette.fromHueAndChroma(150, 36)` — наличные, `(260, 36)` — карта. Тона 90/30 в светлой теме, 30/90 в тёмной.

| Поле | Светлая | Тёмная |
|---|---|---|
| cashContainer (кружок) | #B8F1B9 | #1D5128 |
| onCashContainer (значок) | #1D5128 | #B8F1B9 |
| cardContainer (кружок) | #D5E3FF | #234776 |
| onCardContainer (значок) | #234776 | #D5E3FF |

Цвет оплаты — **только в кружках значков**, без цветных плиток и текста.

### Контраст (проверено)
Светлая / тёмная: onSurface на фоне 14,69 / 14,33; на карточке 17,06 / 11,10; onSurfaceVariant на карточке 9,38 / 8,44; primary на фоне 5,55 / 10,89; текст кнопки 6,45 / 7,25; onSecondaryContainer 7,28; onErrorContainer 7,24; error на карточке 6,46 / 8,46; outline на карточке 4,47 / 4,52; значки оплаты к кружку 7,22–7,28. Всё ≥ AA.

## 2. Типографика (роли M3, шрифт системный)

| Элемент | Роль | Размер | Вес и цвет | Масштаб |
|---|---|---|---|---|
| «Дневник смен» в шапке | titleMedium | 16/24 | w600 | скрыт при ≥ 1,5× |
| Подпись дня | titleLarge | 22/28 | w600 | clamp 1,6× |
| «Сегодня» | bodyLarge | 16/24 | w500, primary | — |
| «Выручка»/«Комиссия» — подпись | bodyLarge | 16/24 | onSurfaceVariant | — |
| «Выручка»/«Комиссия» — сумма | bodyLarge | 16/24 | tabular | FittedBox |
| «На руки» — подпись | labelLarge | 14/20 | w500, onSurfaceVariant | — |
| «На руки» — сумма | displayMedium | 45/52 | w600, letterSpacing −0,45, tabular | clamp 1,6× + FittedBox |
| «3 поездки» | bodyMedium | 14/20 | onSurfaceVariant | — |
| «Наличные»/«Карта» — подпись | labelLarge | 14/20 | w500, onSurfaceVariant | — |
| «Наличные»/«Карта» — сумма | titleLarge | 22/28 | w600, tabular | FittedBox |
| Заголовок «Поездки» | labelLarge | 14/20 | w500, onSurfaceVariant | — |
| Время поездки | bodyLarge | 16/24 | tabular | — |
| «+1 день» | labelMedium | 12/16 (плашка 20) | w600, onSecondaryContainer | — |
| «Карта · комиссия 360 ₸» | bodyMedium | 14/20 | onSurfaceVariant | — |
| Сумма поездки | bodyLarge | 16/24 | w600, tabular | FittedBox |
| Заголовок пустого дня / ошибки | titleLarge | 22/28 | w600 | — |
| Текст ошибки | bodyLarge | 16/24 | onSurfaceVariant | — |
| Плашка ошибки: текст / «Повторить» | bodyMedium / labelLarge | 14/20 | onErrorContainer, кнопка w600 | — |
| Основная кнопка | titleMedium | 16/24 | w600 | без «+» при ≥ 1,5× |
| Форма: «Новая поездка» | titleMedium | 16/24 | w600 | — |
| Форма: подписи полей | bodyLarge | 16/24 | onSurface; при ошибке error | — |
| Форма: дата и время | bodyLarge | 16/24 | время tabular; «Время» — onSurfaceVariant | — |
| Форма: сумма/комиссия | bodyLarge | 16/24 | w600, tabular; «0» — onSurfaceVariant | — |
| Форма: «Способ оплаты» | labelLarge | 14/20 | w500, onSurfaceVariant | — |
| Сегменты | labelLarge | 14/20 | w600 | — |
| Ошибки под полями | bodyMedium | 14/20 | error | — |

## 3. Отступы, радиусы, высоты
Токены `Spacing`: xs 4, sm 8, md 16, lg 24, xl 32. Добавить в `Radii`: small 6, medium 10, large 16, sheet 28. Удалить `Spacing.floatingButtonClearance` (FAB больше нет).

- Поля экрана 16. Шапка 48. Ряд дня: padding 4/4/8, IconButton 48×48, подпись дня min-height 48.
- Карточка: radius 16, без тени и рамки.
- Строка сводки: min-height 48, padding 12×16, разделитель с отступом 16 слева.
- Блок «На руки»: padding 12/16/16, между строками 2.
- Наличные/карта: две колонки, VerticalDivider 1 с отступами 12; кружок 32, иконка 18, отступ 8; сумма на 6 ниже подписи.
- Заголовок «Поездки»: 24 сверху, 8 снизу, 16 от края карточки.
- Строка поездки: min-height 64, padding 8×16; кружок 40, иконка 22; отступ 16; разделитель с отступом 72 (при ≥ 1,5× — 16).
- «+1 день»: padding 0×6, radius 6, высота 20, отступ от времени 8.
- Нижняя панель: padding 8/16/8 + нижняя safe area; кнопка min-height 56, radius 16, иконка 24, отступ 8.
- Плашка ошибки: radius 16, padding 12/8/4/16, иконка 24, отступ 12; 16 снизу.
- Пустой день / ошибка: кружок 72, иконка 36, промежутки 16, поля 24.
- Лист формы: радиус 28 сверху; шапка 8 + 48; группы radius 16, промежуток 16; строки min-height 56, padding 8/8/8/16.
- Кнопки даты/времени: высота 40, зона касания 48 (`MaterialTapTargetSize.padded`), radius 10, padding 10, иконка 18, отступ 6, промежуток 8.
- SegmentedButton: высота 48, полностью скруглённый, рамка 1 outline.
- «Сохранить»: отступы 16 (+ safe area снизу), min-height 56, radius 16.
- Теней нет нигде (исключение — системный круг RefreshIndicator на Android).

## 4. Экран дня — компоненты и состояния
Сверху вниз:
1. **Шапка** `AppBar`: заголовок «Дневник смен» по центру; справа `TextButton` «Сегодня» внутри `Visibility(visible: !isToday, maintainSize: true, maintainAnimation: true, maintainState: true)`, чтобы заголовок не сдвигался.
2. **Ряд дня** (`day_switcher.dart`): `IconButton` ‹ · `TextButton` (подпись дня + иконка раскрытия, открывает выбор даты) · `IconButton` ›. Подписи: «Сегодня, 7 октября», «Вчера, 6 октября», «Завтра, 8 октября», иначе «Четверг, 1 октября».
3. **Плашка ошибки обновления** (`failure_banner.dart`): первым sliver над сводкой, данные остаются видны. Текст — `failure.message`, кнопка «Повторить».
4. **Сводка** (`summary_card.dart`, заменить `metric_grid.dart`): строка «Выручка» · Divider · строка «Комиссия» · Divider · блок «На руки» (подпись, сумма крупно, «N поездок/поездки/поездка») · Divider · «Наличные | Карта» (кружок с иконкой, подпись, сумма, обе одного размера).
5. **Заголовок «Поездки»** и **список** в одной карточке: `SliverMainAxisGroup` + `DecoratedSliver(BoxDecoration(color, radius 16))` + `SliverList.separated` с `Divider(indent: 72)`. Строка (`trip_tile.dart`) — свой виджет с `MergeSemantics`, не `ListTile`: кружок 40 (cashContainer/cardContainer, иконка `payments_rounded` / `credit_card_rounded`) · колонка: `Wrap(время «08:10 – 08:32», плашка «+1 день»)`, «Карта · комиссия 360 ₸» · сумма справа.
6. **Нижняя панель** — `Scaffold.bottomNavigationBar`: `SafeArea(top: false)` → `Padding(8,16,8)` → `FilledButton.icon(add, «Добавить поездку»)`. Фон — фон экрана. Пока под ней есть содержимое (`ScrollMetrics.extentAfter > 0`), сверху разделитель outlineVariant.

Состояния:
- **Загрузка** (`day_skeleton.dart`): ряд дня настоящий; карточка сводки и 3 строки списка из полос `surfaceContainerHighest`, пульсация opacity 1↔0,55, 900 мс. Скелетон появляется, только если загрузка дольше 300 мс.
- **Данные**: см. выше. 02.10 — поездка 00:30–00:55 без плашки, 23:50–00:20 с «+1 день».
- **Длинный список**: прокрутка, панель с кнопкой закреплена, последняя поездка на 16 выше панели.
- **Пустой день** (`empty_day_message.dart`): карточку сводки не показывать. По центру: кружок 72 (`surfaceContainerLowest` / `surfaceContainerHigh`, иконка пустого дня, onSurfaceVariant), «В этот день поездок нет» (titleLarge w600). Действие — общая нижняя кнопка.
- **Ошибка первой загрузки** (`day_failure_view.dart`): по центру кружок 72 errorContainer с иконкой «нет связи», «Не удалось загрузить поездки» (titleLarge w600), `failure.message` (bodyLarge onSurfaceVariant), `FilledButton.tonalIcon(refresh, «Повторить»)` (secondaryContainer, высота 48, radius 16).
- **Потягивание**: `RefreshIndicator.adaptive` (как сейчас).

## 5. Форма новой поездки (`add_trip_sheet.dart`)
`showModalBottomSheet(isScrollControlled: true, useSafeArea: true, enableDrag: false, isDismissible: !submitting)`, `PopScope(canPop: !submitting)` — как сейчас.

Сверху вниз:
1. Шапка: пусто 48 · «Новая поездка» по центру · `IconButton` закрыть (при отправке disabled).
2. **Группа «время»** (Card): строка «Начало» и строка «Окончание», между ними Divider(indent 16). Строка — `Wrap(spaceBetween)`: подпись слева, справа `Wrap` из двух `TextButton.icon`: дата («1 октября», иконка даты) и время («10:00» / «Время» цветом onSurfaceVariant, иконка часов). Фон кнопок — surfaceContainerHighest. У «Окончания» рядом с подписью плашка «+1 день», если день окончания следующий.
3. **Группа «деньги»** (Card, отступ сверху 16): «Сумма», «Комиссия». Справа `TextField(textAlign: end, keyboardType: TextInputType.number)`, `InputDecoration.collapsed`, суффикс « ₸», подсказка «0». Разряды — существующий `MoneyField`. Фокус — линия 2 primary под значением.
4. «Способ оплаты» (labelLarge) и `SegmentedButton<PaymentMethod>` во всю ширину, иконки `payments_rounded` / `credit_card_rounded`, `emptySelectionAllowed: true`, `showSelectedIcon: false`, выбранный — secondaryContainer.
5. Плашка ошибки отправки (`FailureBanner`) над кнопкой.
6. **Кнопка** закреплена внизу листа, отступы 16.

Ошибка поля: подпись поля цветом error, под строкой внутри группы — иконка ошибки 16 + текст (bodyMedium, error), padding 0/16/12. Тексты точные, из `ShiftDiaryStrings.fieldError`: «Выберите время начала», «Выберите время окончания», «Окончание должно быть позже начала», «Введите сумму», «Сумма должна быть больше нуля», «Слишком большая сумма», «Введите комиссию, если её нет — 0», «Комиссия не может быть больше суммы», «Выберите наличные или карту».

Состояния:
- **Пустая**: дата начала и окончания — выбранный на экране день, время не выбрано, суммы пустые, оплата не выбрана.
- **Заполненная**. Если время окончания раньше начала, день окончания сам становится следующим, появляется «+1 день».
- **Отправка**: поля с opacity 0,5 и недоступны, «Закрыть» недоступна, лист не закрывается. Кнопка disabled: `disabledBackgroundColor: secondaryContainer`, `disabledForegroundColor: onSecondaryContainer`, `CircularProgressIndicator.adaptive` 18 + «Поездка сохраняется».
- **Нет связи**: плашка с иконкой «нет связи» и текстом `ConnectionFailure.message`, кнопка «Повторить» с иконкой refresh. Повтор отправляет ту же поездку (тот же id, как сейчас).
- **Конфликт (409)**: плашка с иконкой ошибки и текстом «Эта поездка уже сохранена — с данными первой отправки. Проверьте её в списке.», поля недоступны (opacity 0,5), кнопка «Закрыть».
- **Клавиатура**: лист поднимается на `viewInsets.bottom`, поле в фокусе прокручивается в видимую часть, «Сохранить» над клавиатурой. `TapRegion(onTapOutside: unfocus)`.
- **Выбор даты/времени**: iOS — `showCupertinoPickerSheet` (есть) с `CupertinoDatePicker(mode: time, use24hFormat: true)` / `mode: date`, заголовок листа — имя поля («Начало» / «Окончание»), кнопка «Готово». Android — `showDatePicker` / `showTimePicker` с `alwaysUse24HourFormat: true`.

## 6. iOS и Android
| Что | iOS | Android |
|---|---|---|
| Отклик на нажатие | NoSplash + overlay 8% | InkSparkle |
| Шапка | AppBar, по центру, 48 | то же |
| Иконки | CupertinoIcons | Material Icons |
| Дата / время | CupertinoDatePicker в нижнем листе | showDatePicker / showTimePicker |
| Диалоги | AlertDialog.adaptive | AlertDialog |
| Индикаторы | .adaptive (Cupertino) | Material |
| Прокрутка | Bouncing | Clamping + stretch |

### Иконки (новый `core/theme/app_icons.dart`, выбор по `Theme.of(context).platform`)
| Элемент | iOS | Android |
|---|---|---|
| Стрелки дня | CupertinoIcons.chevron_left / chevron_right | Icons.chevron_left / chevron_right |
| Раскрыть дату | CupertinoIcons.chevron_down | Icons.expand_more |
| Закрыть | CupertinoIcons.xmark | Icons.close |
| Добавить | CupertinoIcons.add | Icons.add |
| Дата в форме | CupertinoIcons.calendar | Icons.event_outlined |
| Время в форме | CupertinoIcons.clock | Icons.schedule |
| Ошибка | CupertinoIcons.exclamationmark_circle | Icons.error_outline |
| Нет связи | CupertinoIcons.wifi_slash | Icons.cloud_off_outlined |
| Пустой день | CupertinoIcons.calendar_badge_minus | Icons.event_busy_outlined |
| Повторить | CupertinoIcons.arrow_clockwise | Icons.refresh |
| Наличные | Icons.payments_rounded | Icons.payments_rounded |
| Карта | Icons.credit_card_rounded | Icons.credit_card_rounded |

Встроенные Material Icons (`_rounded` / `_outlined`), не пакет Material Symbols. Добавить зависимость `cupertino_icons`, если её нет. Размеры: отдельные иконки 24, в кружке 40 — 22, в кружке 32 — 18; стрелки дня на iOS 24, на Android 28.

## 7. Крупный текст и ширина 320
- Порог: `final large = MediaQuery.textScalerOf(context).scale(16) / 16 >= 1.5;`
- При `large`:
  - скрыть заголовок «Дневник смен»;
  - день — отдельной строкой во всю ширину, под ним ряд: ‹ · «Сегодня» (`Visibility maintainSize`) · ›;
  - наличные и карта — в столбец;
  - сумма поездки — под временем и способом оплаты, кружок 32 — в строке способа оплаты, «+1 день» — своей строкой;
  - разделитель поездок с отступом 16;
  - форма — подпись над значением (Wrap), SegmentedButton вертикально;
  - у основной кнопки нет «+».
- **Ограничение масштаба** — только два текста: сумма «На руки» и подпись дня: `Text(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6))`. Остальной текст масштабируется без ограничений.
- **Значок «+»** скрыт при масштабе ≥ 1,5; подпись переносится, кнопка растёт по высоте.
- **Уменьшение сумм**: все суммы сводки (выручка, комиссия, на руки, наличные, карта) и сумма поездки — `FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(…, maxLines: 1, softWrap: false))`. Никаких переносов внутри числа и многоточий.
- **Список под кнопкой**: кнопка в `Scaffold.bottomNavigationBar`, тело кончается над панелью, у `CustomScrollView` нижний `SliverPadding(bottom: 16)`. Если панель поверх списка (`extendBody: true`) — нижний отступ = высота панели (56 + 8 + 8 + `MediaQuery.paddingOf(context).bottom`, при крупном тексте — измеренная) + 16.
- Области нажатия ≥ 48: IconButton 48, кнопки даты/времени — padded, сегменты 48, основная кнопка 56.
- Нигде нет фиксированных ширин и `maxLines` у текста, кроме сумм в FittedBox.

## 8. Поведение и анимации
- **Свайп между днями** (`_DaySwipeDetector`): содержимое следует за пальцем. Смена дня, если |скорость| > `kMinFlingVelocity` или смещение > 30% ширины. Влево — следующий день, вправо — предыдущий. Иначе возврат за 200 мс, `Curves.easeOutCubic`.
- **Смена дня** (свайп, стрелки, выбор даты, «Сегодня»): подпись дня меняется сразу; содержимое — `AnimatedSwitcher` 250 мс, сдвиг 24 по направлению + затухание, `Curves.easeOutCubic`; `HapticFeedback.selectionClick()` (уже есть).
- «Сегодня» — `AnimatedOpacity` 150 мс.
- Плашка ошибки обновления — `AnimatedSize` 200 мс.
- **Сохранение**: кнопка → «Поездка сохраняется» (`AnimatedSwitcher` 150 мс). При успехе лист закрывается, `HapticFeedback.lightImpact()` (уже есть), экран переходит на день поездки. Новая строка подсвечена secondaryContainer и за 1200 мс затухает до цвета карточки. Диктору — `SemanticsService.announce('Поездка добавлена')`.
- Ошибка отправки: `HapticFeedback.heavyImpact()` (уже есть), плашка — `AnimatedSize` 200 мс.
- Окончание через полночь: текст даты меняется, «+1 день» появляется за 150 мс.
- `MediaQuery.disableAnimations`: без сдвигов, только затухание 100 мс, скелетон без пульсации.

## 9. Экранный диктор и порядок фокуса
Суммы — через `spokenTenge` («3 900 тенге»).

**Экран дня:**
1. «Дневник смен», header (при крупном тексте нет)
2. «Сегодня, кнопка» (только на другом дне)
3. «Предыдущий день, кнопка»
4. «Четверг, 1 октября. Выбрать дату, кнопка» — header + liveRegion
5. «Следующий день, кнопка»
6. Плашка ошибки (liveRegion) → «Повторить, кнопка»
7. «Выручка 3 900 тенге», «Комиссия 585 тенге»
8. «На руки 3 315 тенге, 2 поездки»
9. «Наличные 1 500 тенге», «Карта 2 400 тенге»
10. «Поездки», header
11. Поездка одной фразой: «С 08:10 до 08:32, карта, 2 400 тенге, комиссия 360 тенге». Через полночь: «С 23:50 до 00:20 следующего дня, карта, 4 600 тенге, комиссия 690 тенге». Плашка «+1 день» — в `ExcludeSemantics`.
12. «Добавить поездку, кнопка»

Загрузка — liveRegion «Загрузка поездок». Пустой день — «В этот день поездок нет». Ошибка — liveRegion «Не удалось загрузить поездки. <message>», затем «Повторить». Свайп — `excludeFromSemantics` (действия есть у стрелок).

**Форма:** «Новая поездка» (header) → «Закрыть» → «Начало, день 1 октября» → «Начало, время 10:00» / «не выбрано» → «Окончание, день 3 октября, следующий день» → «Окончание, время 00:20» → «Сумма в тенге» → «Комиссия в тенге» → «Способ оплаты: Наличные, выбрано / Карта» → плашка (liveRegion) → «Сохранить» / «Повторить» / «Закрыть». При отправке — liveRegion «Поездка сохраняется». После неудачной проверки фокус на первое поле с ошибкой, `SemanticsService.announce` читает её текст.

### Новые строки в `ShiftDiaryStrings`
| Ключ | Текст |
|---|---|
| dayLoadFailedTitle | Не удалось загрузить поездки |
| nextDayBadge | +1 день |
| spokenTripTimesNextDay | с $start до $end следующего дня |
| spokenNextDay | следующий день |
| tripSaved | Поездка добавлена |

## 10. Карта изменений по файлам
| Файл | Что сделать |
|---|---|
| core/theme/app_theme.dart | Тема из раздела 1, подключить PaymentColors |
| core/theme/payment_colors.dart | Новый ThemeExtension |
| core/theme/app_icons.dart | Новый: иконки по платформе |
| core/theme/radii.dart, spacing.dart | Новые радиусы; убрать floatingButtonClearance |
| screens/shift_diary_screen.dart | Убрать FAB → bottomNavigationBar; «Сегодня» текстом с maintainSize; анимация смены дня; свайп с порогом 30% |
| widgets/day_switcher.dart | Обычная и крупная раскладка, иконки, clamp 1,6 |
| widgets/day_report_view.dart | Плашка, сводка, DecoratedSliver-список, нижний отступ 16, разделитель над панелью |
| widgets/summary_card.dart, metric_grid.dart | Новая структура сводки, FittedBox, крупная раскладка |
| widgets/trip_tile.dart | Кружок оплаты, «+1 день», подпись с комиссией, крупная раскладка, озвучка |
| widgets/empty_day_message.dart, day_failure_view.dart, day_skeleton.dart | Новые состояния |
| widgets/failure_banner.dart | Радиус 16, отступы, иконки по платформе |
| widgets/add_trip_sheet.dart, money_field.dart | Сгруппированная форма, кнопки даты/времени, «+1 день», кнопка при отправке |
| widgets/cupertino_picker_sheet.dart | Заголовок поля над колесом |
| shift_diary_strings.dart | Новые строки |
| test/… | Обновить виджет-тесты (FAB → кнопка, тексты, 200% на 320×568, светлая/тёмная, озвучка); тесты идут с TZ=America/New_York — время должно оставаться алматинским |

## 11. Порядок работы (предложение)
1. Тема, PaymentColors, AppIcons, токены.
2. Экран дня: шапка, ряд дня, нижняя кнопка вместо FAB.
3. Сводка и список, «+1 день», озвучка.
4. Состояния: скелетон, пустой день, ошибки.
5. Крупный текст (порог 1,5, clamp, FittedBox) + тесты на 320×568 при 2,0.
6. Форма и её состояния, пикеры.
7. Анимации и вибрация.
После каждого шага — `make gate`.

## Ресурсы
- Иконки: встроенные `Icons` Flutter и пакет `cupertino_icons` (в макетах — `fonts/CupertinoIcons.ttf` из того же пакета и Google Material Icons).
- Изображений и иллюстраций нет.

## Файлы в `design/`
- `Дневник смен - кадры.dc.html` — все кадры: экран дня (все состояния, светлая/тёмная, iPhone 402×874, Android 360×800), 200% на 320×568, форма во всех состояниях.
- `Дневник смен - спецификация.dc.html` — та же спецификация с образцами цветов и проверкой иконок.
- `Дневник смен - направления.dc.html` — история: направления, выбор 1a, правки.
- `DayScreen.dc.html`, `TripSheet.dc.html` — параметризованные макеты экрана и формы (параметры theme, platform, device, scale, day, state).
- `support.js`, `fonts/CupertinoIcons.ttf` — нужны для открытия макетов.
