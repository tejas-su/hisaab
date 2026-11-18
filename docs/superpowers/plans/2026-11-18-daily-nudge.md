# Daily Nudge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One local evening notification, timed from the user's own *your usual* pattern, that backs off when ignored and lets the user add the amount from the notification itself.

**Architecture:** Pure planning and settling logic in `lib/habits/domain/` reuses `MissedLogDetector` and `HabitIndex`. Arming rides the existing start/resume/write path of `RemindersBloc`. The notification actions run in a background isolate whose entry point lives in `lib/app/` (the composition root), because `lib/core/` may not import features.

**Tech Stack:** Flutter, Bloc, sqflite (schema v6), `flutter_local_notifications` 22.3.x (already installed, no new package), fpdart, hand-written fakes.

**Spec:** `docs/superpowers/specs/2026-11-18-daily-nudge-design.md` (approved 2026-11-18). Read it first; this plan only decides what the spec leaves open.

## Global Constraints

- Docs before code: BR-22 and its edge cases are written in Task 1; tests cite those IDs (CLAUDE.md).
- Money is `int` paise in `Money`, never `double`; amounts typed are whole rupees, 1 to 9 digits (`AmountInput.maxRupees` = 999999999); never show paise.
- "Today" comes from the injected `Clock`; tests pin it with `FakeClock`.
- Notification **title and body never carry an amount or a note**; `NotificationVisibility.private`; no exact-alarm permission (`inexactAllowWhileIdle`).
- No new package. Ask before adding any.
- Strings only in `lib/l10n/app_en.arb` (`flutter gen-l10n` after). Banned words: "transaction", "debit/credit", "budget period", "Oops". Final copy comes from the `design-content` agent.
- Colours, icons and motion only through tokens (`HisaabColors`, `AppIcon`, spring tokens). Import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
- No red, no green, no category colours. Entry speed: no tap or field added to the Add flow.
- Test doubles are hand-written fakes; ask before adding `mocktail` or `bloc_test`. Existing tests are the contract: change code, not tests.
- Hard floor: ≥ 90% of changed lines covered (`scripts/changed_lines_coverage.sh`); list uncovered lines with a reason. `flutter analyze` clean.
- The git repo is local only: never add a remote, never push. **Commit only when the owner asks**, so each "Checkpoint" step below means: run the checks, and commit only if asked.
- Never read, print or copy `key.properties` or keystores.

## Review Focus

Spec-implied inputs no single task's happy path covers, most likely first:

1. **Window ends late** (21:30 → 23:00 is past the 22:00 cut-off): no nudge, no crash. Owner: Task 2.
2. **Logged before the nudge time** must clear it without counting as ignored. Owner: Task 3.
3. **A second tap, or a tap after the app logged the same category** must not save twice. Owner: Task 9.
4. **Typed amounts** such as `1,200`, ` 50 `, `₹50`, `0`, `12.5`, empty, 10 digits. Owner: Task 9.
5. **Notifications refused or turned off later**: arming never throws, nothing is re-asked, the Settings switch still reads correctly (E30 pattern). Owner: Task 5 and Task 7.

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/habits/domain/entities/nudge.dart` (new) | `Nudge`: one armed notification (date, optional category, instant, derived id) |
| `lib/habits/domain/entities/nudge_state.dart` (new) | `NudgeState`: `armedFor`, `ignoredStreak`, `restUntil` per category or general |
| `lib/habits/domain/nudge_rules.dart` (new) | The numbers: 90, 22:00, 20:00, 10 days, 3, 30, 60 |
| `lib/habits/domain/nudge_planner.dart` (new) | Pure: which nudges to arm |
| `lib/habits/domain/nudge_settler.dart` (new) | Pure: worked / ignored / cancelled, streak and rest |
| `lib/habits/domain/nudge_amount.dart` (new) | Pure: typed text → whole rupees |
| `lib/habits/domain/repository/nudge_state_repository.dart` + `data/` (new) | Persistence of `NudgeState` |
| `lib/habits/domain/usecase/arm_nudges.dart` (new) | Settle, plan, arm |
| `lib/habits/domain/usecase/add_nudge_entry.dart` (new) | Save from a notification action |
| `lib/core/db/migrations/migration_006_nudge_state.dart` (new) | Schema v6 |
| `lib/core/notifications/notification_hub.dart` (new) | Owns the one plugin instance; routes responses by payload |
| `lib/core/notifications/nudges.dart`, `android_nudges.dart` (new) | The `Nudges` interface and its Android implementation |
| `lib/core/notifications/android_bill_reminders.dart` (modify) | Takes the hub instead of initialising the plugin itself |
| `lib/app/nudge_background.dart` (new) | Top-level background handler, own DB connection |
| `lib/app/bloc/reminders_bloc.dart` (modify) | Also arms nudges |
| `lib/settings/` (modify) | `nudgeChoice` preference, ask sheet, Settings row |

---

### Task 1: Spec, design docs and decisions first

**Files:** Modify `docs/SPEC.md` (BR-17 last bullet; new BR-22; FR for the Settings row; edge cases after the current last E-number), `docs/UI_DESIGN.md` (§7 notification, §8 copy), `docs/PLAN.md` (schema v6, milestone M11), `docs/DECISIONS.md` (D200 onwards), `CLAUDE.md` (Entry speed: a third off-path control).

**Interfaces:** Produces the IDs (BR-22, FR-SE-n, E-n) that later tests cite.

- [ ] **Step 1:** In `SPEC.md` replace BR-17's last bullet ("nothing is sent or notified") with "the only thing that leaves is the nudge (BR-22), a local notification".
- [ ] **Step 2:** Add **BR-22 Daily nudge** copying the design doc's "Behaviour" steps 1 to 7 and Part 2's actions, with numbered rules BR-22.1 to BR-22.N and worked examples: window ends 14:00 → nudge 15:30; ends 21:30 → none; three ignored → rest to the end of day 30; typed `1,200` saves ₹1,200.
- [ ] **Step 3:** Add the Settings row requirement, the ask sheet, and edge cases for: permission refused, window crossing midnight, backup restored with `armed_for` in the future, *Delete everything*, double action, category already logged.
- [ ] **Step 4:** `UI_DESIGN.md` §7/§8: the notification (title, body, two actions, confirmation, channel name). Copy is a placeholder until Task 8.
- [ ] **Step 5:** `PLAN.md` M11 row and schema v6; `DECISIONS.md` D200 (nudge), D201 (back-off 3/30/60), D202 (actions run in a background isolate, Part 2 same release gated on device check); `CLAUDE.md`: Entry speed names three off-path controls (*New*, *your usual*, the nudge actions).
- [ ] **Step 6:** Verify: `grep -n "BR-22" docs/SPEC.md` shows the section; no doc says "nothing is notified" any more. Checkpoint.

### Task 2: `NudgePlanner` (pure, test-first)

**Files:** Create `lib/habits/domain/nudge_rules.dart`, `entities/nudge.dart`, `nudge_planner.dart`; Test `test/habits/domain/nudge_planner_test.dart`.

**Interfaces:**
- Consumes: `HabitIndex` (`habits`, `loggedToday`, `states`, `builtOn`), `UsualHabit` (`window`, `dayType`, `categoryId`, `fading`, `amount`), `MissedLogDetector.graceMinutes`, `SuggestionGate`, `DayType.of(CalendarDate)`, `TimeWindow`.
- Produces:
  - `final class Nudge extends Equatable { final CalendarDate date; final Option<int> categoryId; final DateTime at; int get id; }` where `id` = `date` days since 2020-01-01 × 1000 + (categoryId or 0), kept below 2^31 and distinct from `BillReminder.id` (use a fixed offset of 2,000,000,000 minus; builder picks and documents).
  - `abstract final class NudgePlanner { static List<Nudge> plan(HabitIndex index, {required DateTime now, required List<Category> categories, required Map<int, NudgeState> nudgeStates, required bool hasEnoughDays}) }` returning today's (only if `at` is after `now`) and tomorrow's nudge, at most one per date.

- [ ] **Step 1: Write failing tests** (all with `FakeClock`): window ends 14:00 → `at` 15:30 same date; ends 21:30 → none; window crossing midnight → none; category logged today → no nudge for today but tomorrow still planned; `asked_on` = today → none for today; category resting (`restUntil` ≥ date) → none for that date; Undo-quiet today → none for today; weekend habit used on Saturday not Friday; tomorrow uses tomorrow's day type; `now` after `at` → today skipped; two qualifying habits → one nudge (pill tie-break `UsualSpendDetector.rank`); no Regular habit and `hasEnoughDays` → general nudge at 20:00 only when `loggedToday` is empty and no `nudgeStates[0]` rest; no habit and not `hasEnoughDays` → none; a rested general nudge → none.
- [ ] **Step 2:** `flutter test test/habits/domain/nudge_planner_test.dart` → FAIL (symbols undefined).
- [ ] **Step 3:** Implement `NudgeRules` (constants named in the spec) and `NudgePlanner.plan`; reuse the detector's candidate filters rather than copying them (extract a shared private-to-library helper only if reuse needs it).
- [ ] **Step 4:** Same command → PASS; `flutter analyze` clean. Checkpoint.

### Task 3: `NudgeState` and `NudgeSettler` (pure, test-first)

**Files:** Create `entities/nudge_state.dart`, `nudge_settler.dart`; Test `test/habits/domain/nudge_settler_test.dart`.

**Interfaces:**
- Produces: `final class NudgeState extends Equatable { final int categoryId; /* 0 = the general nudge */ final Option<DateTime> armedFor; final int ignoredStreak; final Option<CalendarDate> restUntil; }`
- `abstract final class NudgeSettler { static NudgeState settle(NudgeState state, {required DateTime now, required List<DateTime> loggedAt}) }`, where `loggedAt` is the `created_at` of that category's Spent entries (any category for the general nudge) dated the armed day.

- [ ] **Step 1: Write failing tests:** no `armedFor` → unchanged; `armedFor` still in the future or within 60 min of `now` → unchanged (no verdict yet); entry logged **before** `armedFor` → cleared, streak unchanged (cancelled, Review Focus 2); entry at `armedFor` and at exactly +60 min → worked, streak 0; none in the window → ignored, streak +1; third ignored in a row → `restUntil` = end of day 30 after the armed day, streak 0; worked after two ignored → streak 0; an armed nudge from days ago is settled once only.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement. **Step 4:** run → PASS. Checkpoint.

### Task 4: Schema v6 and persistence

**Files:** Create `lib/core/db/migrations/migration_006_nudge_state.dart`, `lib/habits/data/{model,mapper,datasource,repository}/nudge_state_*.dart`, `lib/habits/domain/repository/nudge_state_repository.dart`; Modify `lib/core/db/migrations/migrations.dart`, `lib/core/db/db_schema.dart` (`Tables.nudgeState`, `NudgeStateColumns`), `lib/habits/di/habits_module.dart`, backup and *Delete everything* (follow exactly how `suggestion_state` is carried: `lib/backup/` and `lib/backup/domain/usecase/delete_everything.dart`); Tests under `test/core/db/`, `test/habits/data/`, `test/backup/`.

**Interfaces:**
- Consumes: `NudgeState` (Task 3).
- Produces: `abstract interface class NudgeStateRepository { TaskEither<Failure, Map<int, NudgeState>> all(); TaskEither<Failure, Unit> put(NudgeState state); TaskEither<Failure, Unit> clear(); }` and `migration006NudgeState`.

- [ ] **Step 1: Write failing tests** on real SQLite (`sqflite_common_ffi`, `test/helpers/test_database.dart`): migrating v5 → v6 keeps every old table and row; `put` then `all` round trips including `Option` none; backup round trip; restore of an older (v5) file works as before; *Delete everything* empties it. Table: `category_id INTEGER PRIMARY KEY` (0 = general, so **no foreign key**), `armed_for TEXT`, `ignored_streak INTEGER NOT NULL DEFAULT 0`, `rest_until TEXT`.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement; append the migration (never edit shipped ones); backup schema version 6 (BR-16). **Step 4:** run the new tests plus `flutter test test/core/db test/backup` → PASS. Checkpoint.

### Task 5: Notification hub and `Nudges` (Android)

**Files:** Create `lib/core/notifications/notification_hub.dart`, `nudges.dart`, `android_nudges.dart`; Modify `android_bill_reminders.dart`, `lib/app/app_services.dart`, `lib/core/di/service_locator.dart`; Test `test/core/notifications/`.

**Interfaces:**
- Produces:
  - `final class NotificationHub { static Future<NotificationHub> start({required Future<void> Function(NotificationResponse) onBackground}); FlutterLocalNotificationsPlugin get plugin; Stream<NotificationResponse> get responses; }` — it is the **only** caller of `plugin.initialize`, because a second `initialize` would replace the first's callbacks.
  - `abstract interface class Nudges { Future<void> arm(List<Nudge> upcoming); Future<bool> requestPermission(); Stream<void> get taps; Future<bool> launchedByNudge(); Future<void> showAdded({required String categoryName, int? undoEntryId}); }` (hand-written `FakeNudges` in `test/helpers/fakes/`).
- `AndroidBillReminders.start` now takes the hub; its public behaviour is unchanged.

- [ ] **Step 1:** Existing `bill_reminder_test.dart` and every bill-reminder test must still pass unchanged: run them first as the baseline.
- [ ] **Step 2: Write failing tests** for what is pure: the payload router (`hisaab://bill/...` → bill listener, `hisaab://add` with a `nudge` marker → nudge listener, anything else ignored); `Nudge.id` never equals a `BillReminder.id`.
- [ ] **Step 3:** Implement the hub and `AndroidNudges`: its own channel `daily_nudge` (name and description from the ARB), `NotificationVisibility.private`, category reminder, `inexactAllowWhileIdle`, scheduling a nudge by its id so re-arming never duplicates, removing any pending or shown nudge not in `upcoming`. Every call goes through a `_quietly`-style guard (Review Focus 5). Part 2's action buttons are added in Task 10, not here.
- [ ] **Step 4:** Run `flutter test test/core/notifications` and the bill-reminder tests → PASS. Checkpoint.

### Task 6: `ArmNudges` and wiring into the arm path

**Files:** Create `lib/habits/domain/usecase/arm_nudges.dart`; Modify `lib/habits/di/habits_module.dart`, `lib/app/bloc/reminders_bloc.dart`, `lib/app/routes.dart` or the composition root that builds `RemindersBloc`; Tests `test/habits/domain/usecase/arm_nudges_test.dart`, `test/app/bloc/reminders_bloc_test.dart` (extend).

**Interfaces:**
- Consumes: `GetHabitIndex`, `NudgeStateRepository`, `LedgerRepository.entriesBetween`, `NudgePlanner.plan`, `NudgeSettler.settle`, `Nudges.arm`, `Clock`, categories from the ledger.
- Produces: `final class ArmNudges implements UseCase<Unit, bool>` (param = whether the user switched nudges on); `RemindersBloc` takes `required ArmNudges armNudges` and `required AppPreferencesRepository` already present.

- [ ] **Step 1: Write failing tests** with fakes: off → `Nudges.arm([])` and pending ones removed; on → settles past `armedFor`, persists the new state, plans, stores `armedFor` for each armed nudge, arms; a read failure arms nothing and returns `Left`; a ledger write after the nudge time cancels today's; `RemindersBloc` calls `ArmNudges` on start, resume and every ledger/rule change, and never throws when it fails.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement; `hasEnoughDays` = at least 10 distinct days with a learned entry (reuse the habit index builder's count, don't re-query if it exposes one). **Step 4:** run → PASS; `flutter test test/app test/habits` green. Checkpoint.

### Task 7: Opt-in, ask sheet and Settings row

**Files:** Modify `lib/settings/domain/repository/app_preferences_repository.dart` + impl (`nudgeChoice(): TaskEither<Failure, Option<bool>>`, `saveNudgeChoice({required bool on})`), `lib/home/presentation/bloc/home_lines_bloc.dart` (after the missed-log tap, ask once when `nudgeChoice` is none), `lib/settings/presentation/pages/` (a `nudge_ask_sheet.dart` modelled on `remind_ask_sheet.dart`, and the Settings row), `lib/l10n/app_en.arb`; Tests beside each.

**Interfaces:**
- Produces: `AppPreferencesRepository.nudgeChoice` and `.saveNudgeChoice`; `ShouldAskNudge` use case (true when the choice is none and the user has tapped the missed-log line), mirroring `should_ask_bill_reminders.dart`.

- [ ] **Step 1: Write failing tests:** the ask appears once after the missed-log tap and never again after either answer; *Remind me* requests the permission and, if refused, shows the refusal line and stores *off* (E30 pattern); the Settings row toggles the preference and calls `ArmNudges` through `RemindersBloc`; the row reads off when the system permission is off. Widget tests at every `TestWindows` size and at 2.0× text.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement with tokens only; strings use the placeholders until Task 8. **Step 4:** run → PASS. Checkpoint.

### Task 8: Tap opens the Add tray, and the real copy

**Files:** Modify `lib/shortcuts/domain/entities/launch_action.dart` only if the existing `hisaab://add` link cannot carry the nudge marker (prefer reusing it); `lib/app/` launch handling; `lib/l10n/app_en.arb`; Tests `test/shortcuts/`, `test/app/`.

- [ ] **Step 1:** Ask the **`design-content` agent** for the title, body (up to three phrasings rotated by date), the general nudge text, channel name and description, the ask sheet and Settings row, the "Enter an amount" and "Added to {category}" lines, and the Undo label. No amount, no banned words.
- [ ] **Step 2: Write failing tests:** a nudge tap while running and at cold start opens the Add tray (`LaunchAction.add`); a bill tap is unaffected; phrasing is a pure function of the date.
- [ ] **Step 3:** Implement and `flutter gen-l10n`. **Step 4:** run → PASS. Checkpoint. **Part 1 is now complete and shippable on its own.**

### Task 9: `AddNudgeEntry` and `NudgeAmount` (pure, test-first)

> Deferred: owner decision 2026-11-18 (see D204); not part of this release.

**Files:** Create `lib/habits/domain/nudge_amount.dart`, `lib/habits/domain/usecase/add_nudge_entry.dart`; Tests beside.

**Interfaces:**
- Consumes: `SaveEntry`, `EntryDraft`, `AmountInput.maxRupees`, `UndoUsualAdd`, `GetHabitIndex` (for `loggedToday`).
- Produces:
  - `abstract final class NudgeAmount { static Option<int> parse(String text) }`: trims, removes spaces, commas and a leading `₹`, then requires 1 to 9 digits and a value ≥ 1.
  - `final class AddNudgeEntry implements UseCase<Entry, AddNudgeParams>` with `AddNudgeParams({required int categoryId, required int rupees})`; fails with `NudgeAlreadyLoggedFailure` (new `Failure` in `lib/core/errors/`, following the file's pattern) when the category already has an entry today.

- [ ] **Step 1: Write failing tests:** `parse` of `250`, `1,200`, ` 50 `, `₹50` → Some; `0`, `00`, ``, `12.5`, `abc`, `1234567890` (10 digits) → None; `999999999` → Some; saving creates a **Spent** entry dated today with the habit's category and no note; a second call the same day → `NudgeAlreadyLoggedFailure` and nothing saved (Review Focus 3); Undo of a usual add reuses `UndoUsualAdd` and quiets the category until midnight.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement. **Step 4:** run → PASS. Checkpoint.

### Task 10: Notification actions and the background isolate

> Deferred: owner decision 2026-11-18 (see D204); not part of this release.

**Files:** Create `lib/app/nudge_background.dart`; Modify `lib/core/notifications/android_nudges.dart` (actions), `lib/core/notifications/notification_hub.dart` (pass the background callback), `lib/main.dart`, `android/app/src/main/AndroidManifest.xml` only if the plugin's action receiver needs it; Tests `test/app/nudge_background_test.dart`.

**Interfaces:**
- Produces: `@pragma('vm:entry-point') Future<void> nudgeBackgroundHandler(NotificationResponse response)` (top-level) and `final class NudgeActionRunner { Future<NudgeActionResult> run(NotificationResponse response); }`, where the result is *saved*, *invalid*, *alreadyLogged*, *undone* or *ignored*. The runner is the testable part; the handler only builds it.

- [ ] **Step 1: Write failing tests** for `NudgeActionRunner` with fakes: *Add ₹{usual}* action id saves the habit's amount; *Other amount* with valid input saves it; invalid text → `invalid` and the notification is kept (shows "Enter an amount"); already logged → `alreadyLogged`; *Undo* deletes the entry and quiets the category; the confirmation carries no amount; the general nudge exposes **no** action buttons.
- [ ] **Step 2: Write the cross-connection test** on real SQLite: a second `AppDatabase` connection saves an entry while the first holds the file open; the first sees it after a re-read.
- [ ] **Step 3:** Implement. `AndroidNudges` schedules `AndroidNotificationAction` with ids `add_usual` (label from ARB with the amount, shown only when the habit has an exact amount) and `add_other` with an `AndroidNotificationActionInput`, `showsUserInterface: false`, `cancelNotification: true`; replace the notification with the "Added to {category}" confirmation (auto-timeout, no amount; an *Undo* action only for the usual add). The handler opens its own database and builds only what the runner needs; it cannot use `get_it`.
- [ ] **Step 4:** After a save the runner must **refresh the widget snapshot** (find the use case `ShortcutsBloc` calls in `lib/app/bloc/shortcuts_bloc.dart` and reuse it) and re-arm nudges, so Home and the widget are right. A running app re-reads on resume (a ledger change in another isolate does not reach its `changes` stream): test that resume triggers a reload.
- [ ] **Step 5:** `flutter test test/app test/habits test/core` → PASS. Checkpoint.

### Task 11: Device check, docs sync and the final gates

**Files:** `docs/features/habits/` (add `NN-daily-nudge.md`, next free number, per `feature-docs.md`), the docs from Task 1 (reconcile), `CLAUDE.md`.

- [ ] **Step 1: Device check with the `live-app-inspection` skill** (`adb`): Part 1 only, no action buttons: the nudge fires at the planned time on a seeded history (use a debug-built clock or seed entries so the window is soon); the tap opens the Add tray; the Settings switch turns it on and off; denying the permission; swiping the nudge away; reboot re-arms.
- [ ] **Step 2:** Run the Review Focus cases above once more against the built app where they are visible.
- [ ] **Step 3:** `flutter analyze` clean; `flutter test` all green; `scripts/changed_lines_coverage.sh main` ≥ 90% with every uncovered line listed and explained.
- [ ] **Step 4:** Update the feature doc and reconcile SPEC / UI_DESIGN / PLAN / DECISIONS with what was built. Checkpoint; commit only if the owner asks.

---

## Self-review

- **Spec coverage:** goals and behaviour steps 1–7 → Tasks 2, 3, 6, 8; opt-in and Settings → 7; Part 2 actions and Undo → 9, 10; schema, backup, delete everything → 4; docs → 1, 11; device gate and cut rule → 11; non-goals are enforced by the Global Constraints.
- **Type consistency:** `Nudge`, `NudgeState`, `NudgePlanner.plan`, `NudgeSettler.settle`, `NudgeStateRepository`, `Nudges`, `ArmNudges`, `AddNudgeEntry`, `NudgeAmount`, `NudgeActionRunner` are each defined once and used with the same names.
- **Open for the builder:** exact `Nudge.id` arithmetic, the shared candidate helper, where the day count for `hasEnoughDays` comes from, and the widget-refresh use case's real name.
