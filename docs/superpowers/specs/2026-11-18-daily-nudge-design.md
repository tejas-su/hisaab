# Daily nudge: design

Status: **Part 1 is the release; Part 2 is deferred by the owner on 2026-11-18** (D204). Part 1 is built. Part 2 is kept below as the specification for a later phase.

## Intent

People stop using a tracker when they forget to log, and then the day's number is wrong. The Home *missed-log line* (BR-17, D171) already asks "no chai today?" when a regular habit's window has passed, but only if the app is open. The nudge delivers that same question as a local notification, at a time learned from the user's own pattern, and **backs off by itself when it is ignored**.

"Experiment" here means on-device adaptation to one person. The app has no analytics (CLAUDE.md, Privacy), so nothing is compared across users and nothing leaves the phone.

## Goals

- One local notification a day, at the time the user usually logs plus the grace period, only on days that category has no entry yet.
- The text names the habit; the time comes from BR-17's learned window.
- A nudge that keeps being ignored stops (rest of up to 30 days) and comes back on its own.
- No new package: `flutter_local_notifications` is already installed (D126).

## Non-goals and anti-goals

- No amount and no note in the notification's **title or body**, ever; a locked screen hides the text (same as bill reminders). Part 2 adds action buttons; their labels are the one place an amount may appear, and a private notification hides them too until unlock.
- No exact-alarm permission, no sound or vibration beyond the channel default.
- No more than one nudge a day in total, shared with the missed-log line.
- No streaks, badges, guilt or urgency words. A nudge must read like the rest of the app (UI_DESIGN §8 voice).
- No per-user time picker. The learned time is the default; the system's own channel settings are the off switch for the sound.
- Anti-goal: a nudge that fires after the user already logged. That is worse than none.

## Constraints

- Entry speed: the Add flow gains no tap and no field. A tap on the nudge opens the existing Add tray (`hisaab://nudge`, which opens the plain Add tray like the widget's Add key). No new Add behaviour.
- Scheduled notifications cannot check anything when they fire, so every condition is checked when arming, and arming repeats on every start, resume and write (as the bill reminders do through `RemindersBloc`).
- Strings only in `lib/l10n/app_en.arb`; banned words apply ("transaction", "debit/credit", "Oops"). Copy goes through the `design-content` agent.
- Android 13+ needs the notification permission; refusal is respected and never re-asked (E30 pattern).

## Approaches considered

| | What | Trade-off |
|---|---|---|
| A | Fixed 9 pm nudge, skipped if anything is logged | Smallest, but ignores the pattern and can't adapt |
| B | Pattern-timed from BR-17 windows | Right time and wording; keeps nagging if the user doesn't want it |
| **C (chosen by the owner)** | B plus on-device back-off | A little more state and one table; stops being a nuisance |

## Design

### Behaviour (new SPEC BR-22, edits BR-17's last bullet)

1. **Candidate.** The same pick as the missed-log line: a Regular habit of the day type, not fading, open gate, category shown on Home, no entry dated that day. Time = window end + 90 min, same local date; a window crossing midnight gives none; a time after 22:00 gives none (my call).
2. **Fallback (droppable, my call).** With no Regular habit but at least 10 days with a learned entry, one general nudge at 20:00 on a day with no entry at all: "Anything to log today?".
3. **Armed ahead.** Today (if the time is still ahead) and tomorrow. Tomorrow assumes nothing is logged yet and uses tomorrow's day type. The id is derived from the date, so re-arming never shows two.
4. **Cancelled** by any write that makes the condition false (an entry in that category today), by the missed-log line having been asked today (`asked_on` = today, so the user isn't asked twice), and by *Forget* or a rest.
5. **Settling.** When a past armed nudge is found at arming time, it counts as *worked* if a Spent entry in that category was logged from its time to 60 min later (my call), otherwise *ignored*. *Worked* resets the streak. Three *ignored* in a row rest the nudge until the end of the 30th day after, then the streak resets. Entries are read by `created_at`, as BR-17 does.
6. **Tap** opens the Add tray. Dismissal needs no handling: ignoring and swiping away are the same signal.
7. **Text.** Title "{category} today?" and body "Tap to add it" as the working copy, rotated through at most three phrasings by date. Final wording is the `design-content` agent's.

### Where it goes

| Piece | Home | Notes |
|---|---|---|
| `NudgePlanner` (pure) | `lib/habits/domain/` | Takes `HabitIndex`, `now`, categories, nudge state; returns the nudges to arm. Reuses `MissedLogDetector` for step 1, so the line and the nudge never disagree |
| `NudgeSettler` (pure) | `lib/habits/domain/` | Step 5; takes armed-for instants and entries |
| `nudge_state` table | migration 006, `lib/habits/data/` | Per category (or the general nudge): `armed_for`, `ignored_streak`, `rest_until`. Dates and ids only. Schema v6 |
| Arm and cancel | `lib/core/notifications/` | A sibling of `android_bill_reminders.dart` behind an interface with a hand-written fake; its own Android channel "Daily nudge", private visibility |
| Driver | `lib/app/bloc/` | Extends the existing arm-on-start/resume/write path of `RemindersBloc` rather than a second bloc, if that stays readable |
| Permission and off switch | Settings, near the bill reminders | See open question 1 |
| Backup, restore, *Delete everything* | `lib/backup/` | Carries `nudge_state`; backup schema version 6 (BR-16); the old file restores as before |

### Docs to change in the same change

`SPEC.md` (BR-17 last bullet "nothing is notified", new BR-22, FR for the Settings row, edge cases), `UI_DESIGN.md` §8 (copy) and §7 (notification), `PLAN.md` (schema v6, milestone M11), `DECISIONS.md` (D200 onwards), the ARB file, and `docs/features/habits/` if it describes notifications.

### Testing (tests cite BR-22 IDs)

TDD for `NudgePlanner` and `NudgeSettler` with `FakeClock`: window ends 21:30 (nudge 23:00, skipped); window crossing midnight; weekday vs weekend; DST-free but year-crossing dates; the 3-ignored rest and its end on day 31; *Worked* resetting; an entry at +60 min exactly; logging cancels; `asked_on` suppresses. Migration 006 and backup round trip on real SQLite (`sqflite_common_ffi`). Fake notifier for arm/cancel. Widget tests for the ask and the Settings row at the `TestWindows` sizes and 2.0× text. Coverage floor 90% of changed lines.

## Part 2: add the amount from the notification itself

> **Deferred to a later phase (owner decision 2026-11-18).** Not part of this release; see D204.

Requested by the owner after the first draft. **Ships in the same release as Part 1** (owner's decision; the builder's recommendation had been a later release). To contain the risk it is built second, as its own plan stage, and is checked on a real device before the release is cut. Part 1 works alone, so if the background save fails that check the actions are cut and Part 1 ships.

### Behaviour (BR-22 continued)

The notification gets up to two actions, both saving a **Spent** entry dated today in the nudge's category, with `created_at` = now, so it feeds BR-17 like any entry:

1. **"Add ₹{usual}"**: shown only when the habit has an exact amount (BR-17 rule 4). One tap saves it. Like the *your usual* pill (FR-AD-10) it is followed by a confirmation with **Undo** (4 s), and Undo deletes the entry and quiets the category until midnight (BR-17).
2. **"Other amount"**: Android's inline text reply. The user types digits and sends. It saves that amount with **no Undo**, the same as a save from the Add tray. Input follows BR-10: whole rupees, 1 to 9 digits, no paise; anything else keeps the notification and shows "Enter an amount" instead of saving. The general (fallback) nudge has no category and no usual, so it shows only the **tap**, which opens the Add tray; no inline add.

After a save the notification is replaced by a short confirmation with no amount in it ("Added to Chai"), which times out by itself. The save counts as *worked* in the back-off (step 5) at once.

### Why it is built this way

- It adds no tap and no field to the Add flow (CLAUDE.md Entry speed). It is a **third control off that path**, beside *New* and *your usual*; CLAUDE.md and BR-17's list of off-path controls need the one-line update.
- Both actions run **without opening the app**, in a background isolate (`onDidReceiveBackgroundNotificationResponse`, a top-level function; no UI). That isolate needs its own database connection and use cases, and cannot use the app's `get_it` graph.

### Risks, and what the builder must prove

| Risk | Plan |
|---|---|
| A second SQLite connection while the app is open | Run the save in one short transaction on the app's database file; test two connections writing on real SQLite (`sqflite_common_ffi`) |
| Home and the widget stay stale after a background save | The widget's snapshot is written by Dart on changes (`lib/shortcuts/`). The action must write the snapshot after saving and ask the widget to redraw; a running app must hear about the write (its ledger `changes` stream does not fire across isolates), so it re-reads on resume. Test both |
| Double save (two taps, or the user also logs in the app) | The nudge's id is cleared on the first save; the action is a no-op if the category already has an entry today and says so |
| Locked phone | Actions need an unlock first (private visibility); nothing extra to build, to be checked on a device |
| Android versions | Inline reply needs Android 7+; the app's minimum is higher, so no fallback is needed (check `minSdk`) |
| Cap and bad input | 9-digit cap, `0`, empty and non-digit text each have a test (BR-10, E-cases) |

### Where it goes

| Piece | Home |
|---|---|
| Background entry point (top-level, `@pragma('vm:entry-point')`) | `lib/core/notifications/` |
| `AddNudgeEntry` use case (pure given a repository): parse amount, save, return what to confirm | `lib/habits/domain/usecase/`, uses `ledger.dart` |
| Reply parsing | reuses `Money` parsing from `lib/core/money/`, never `double` |
| Undo of a nudge add | reuses `UndoUsualAdd` (the pill's undo) |
| Snapshot refresh after a background save | `lib/shortcuts/` use case, called from the entry point |

### Part 2 testing

TDD for `AddNudgeEntry` (valid, 0, 10 digits, blank, "12.5", the usual amount, category already logged today). Fake notifier asserts the confirmation, the cancel and the Undo. A real-SQLite test of a save from a second connection. The Android action wiring is checked on a device with `adb` (`live-app-inspection` skill): tap *Add ₹20*, type an amount, lock screen, app closed, app open.

## Decisions (owner, 2026-11-18)

1. **Switch-on:** asked once, in context, right after the user taps the Home missed-log line (*Remind me* / *Not now*, never asked again, the D126 pattern), plus one off switch in Settings.
2. **Fallback:** keep the 20:00 general nudge for people with no regular habit yet.
3. **Part 2:** both actions, *Add ₹{usual}* and *Other amount*. (Superseded: Part 2 deferred, D204.)
4. **Part 2 timing:** same release as Part 1, built second and gated on a device check (see Part 2). (Superseded: Part 2 deferred, D204.)

## Left to the builder

The `RemindersBloc` extension versus a separate bloc, the exact table column types, how tomorrow's day type is derived across the 22:00 cut-off, and the final copy.
