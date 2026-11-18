# Shortcuts: architecture overview

The home-screen widget, the Quick Settings tile and the app shortcut (SPEC FR-WG, FR-SE-6; D147, D156; mockup 38). They only open hisaab sooner: the entry path stays Add → digits → Next → tile.

## Entry points

| Surface | Where | Opens |
|---|---|---|
| Widget *hisaab* (2×1, 2×2, 4×1, 4×2) | `android/.../widget/HisaabWidgetProvider.kt` | Add key → `hisaab://add`; elsewhere → `hisaab://home`; *Set up* → `hisaab://setup` |
| Tile "Add a spend · hisaab" | `android/.../tile/AddSpendTileService.kt` | Tap → `hisaab://add` (unlocks first); long-press → Home |
| App shortcut "Add a spend" | `android/app/src/main/res/xml/shortcuts.xml` | `hisaab://add` |
| Settings › Shortcuts | `lib/settings/presentation/widgets/shortcuts_group.dart` | Android's own add-widget and add-tile dialogs |

## Key classes

| Class | Layer | Responsibility |
|---|---|---|
| `ProjectWidgetDays` (`lib/shortcuts/domain/usecase/`) | domain | Every day from today to the end of the next cycle, as Home would show it with nothing new typed |
| `ProjectedBook` (`lib/shortcuts/domain/projection/`) | domain | An in-memory copy of the ledger that the real `PostDueRecurring` and `GetCycleSummary` run on |
| `WidgetSnapshot`, `WidgetDay` (`lib/shortcuts/domain/entities/`) | domain | The snapshot, every word already worded |
| `LaunchAction` | domain | `add`, `home`, `setUp`, parsed from a `hisaab://` URI |
| `ShortcutsPlatform` | domain port | Publish, can-pin, pin, can-add-tile, add-tile, launch actions |
| `WidgetSnapshotMapper` (`lib/shortcuts/presentation/`) | presentation | Words each day with Home's `HeroCopy`, `TodayBarMapper` and `DaysRailMapper` |
| `WidgetSnapshotJson` (`lib/shortcuts/data/mapper/`) | data | The JSON contract with `SnapshotReader.kt` (`v: 1`) |
| `AndroidShortcutsPlatform` (`lib/shortcuts/data/platform/`) | data | The `hisaab/shortcuts` method channel |
| `ShortcutsBloc` (`lib/app/bloc/`) | app | Publishes on every trigger (`sequential()`); holds a pending tap |
| `ShortcutLaunchListener` (`lib/app/widgets/`) | app | Follows a pending tap on the root screen in view |
| `AppRoutes.followLaunch` (`lib/app/routes.dart`) | app | Home, or the Add tray at the keypad; a tray already open stays |
| `ShortcutRowsBloc`, `ShortcutsGroup` (`lib/settings/presentation/`) | presentation | The two Settings rows, hidden where the phone can't |
| `MainActivity.kt` | Android | The channel, the launch URI, pin and add-tile requests |
| `SnapshotReader.kt` | Android, pure | Parses the snapshot, picks today's row; stale when none |
| `WidgetViews.kt`, `EtchPaper.kt`, `TodayBar.kt`, `DaysRail.kt`, `WidgetText.kt` | Android | Draw one widget at its size, in the app's *Look* |
| `Midnight.kt` | Android | The inexact alarm and the WorkManager job just after midnight |

## Data flow: keeping the widget fresh

1. A write emits on `LedgerRepository.changes` or `RecurringRepository.changes`; or `AppRoot` sees the root screen settle (start, onboarding finished, restore, *Delete everything*), a *Look* change or a resume.
2. `ShortcutsBloc` reads the look, runs `ProjectWidgetDays`, maps the days with `WidgetSnapshotMapper` and calls `ShortcutsPlatform.publish`, one publish at a time.
3. `ProjectWidgetDays` reads the ledger once into a `ProjectedBook`. For each day it sets a clock to that day, runs the engine (bills, savings and pay due by then are posted on the copy) and then `GetCycleSummary`. It stops at the end of the cycle after today's.
4. `MainActivity` stores the JSON in shared preferences (`SnapshotStore`) and redraws every placed widget.
5. `HisaabWidgetProvider` picks the row for `LocalDate.now()` whenever it redraws: on publish, a resize, just after midnight, a date, time or time-zone change, boot, an app update, and Android's 30-minute refresh. With no row it shows the wordmark and "Open hisaab to update".

## Data flow: a tap

1. The widget, tile or shortcut starts `MainActivity` with a `hisaab://` URI (explicit intent, `FLAG_IMMUTABLE`).
2. On a cold start `MainActivity` keeps the URI until Dart asks (`launchAction`); while running, `onNewIntent` sends it down the channel (`launch`).
3. `ShortcutsBloc` holds it as `ShortcutsLaunchPending`. The root screen in view follows it through `ShortcutLaunchListener`: onboarding drops it (E51); Home pops to itself and, for `add`, opens the Add tray unless one is open. On a cold start the tray waits up to 1 s for the habits and Home's figures (D156).

## Failures

- A failed read during projection is logged (`shortcuts.project_failed`) and nothing is published; the widget keeps the last snapshot.
- A channel error is logged and swallowed: nothing can be added, no tap is read.
- A missing, unreadable or unknown-version snapshot draws the stale state; nothing crashes (W3).

## Tests

- `test/shortcuts/domain/usecase/project_widget_days_test.dart`: the oracle. Each projected day equals the real engine and summary on a real SQLite database opened on that day. It covers a fixed, a changing and a card bill, a saving, payday on the 31st in leap-year February, the year end, over today, over the cycle, a pay switch, weekly pay and no income.
- `test/app/shortcut_launches_test.dart`: taps and publishes through the whole app.
- `test/shortcuts/android_resources_test.dart`: drift guards. `widget_colors.xml` must equal `HisaabColors`, and `strings.xml` must equal the ARB.
- `android/app/src/test/.../SnapshotReaderTest.kt`: JVM tests for picking today's row. Drawing is checked by eye on a device (widget spec §13).
