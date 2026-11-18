# Changelog

All notable changes to **hisaab•** are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Entries cite the decision log (`D…`) and spec IDs (`BR-`, `FR-`) in [docs/](docs/) so each change can be traced to its reasoning.

The app is Android-only and built for Indian users (INR). Dates are `YYYY-MM-DD`. Versions are `pubspec.yaml` versions (`name+build`).

## [Unreleased]

Work after `0.1.0+2`. The daily nudge below is built and tested but **not yet committed**.

### Added
- **Daily nudge** (BR-22, FR-SE-7, D200 to D205). One local evening notification that reminds you to add what you usually spend, so today's number stays true.
  - Timed from your own pattern: it fires 90 minutes after the window in which you usually log a habit (*your usual*, BR-17), never later than 22:00. Someone with no regular habit yet gets one general nudge at 20:00 after two weeks of use.
  - Skipped on days you already added that category, and cancelled the moment you do. It is planned for today and tomorrow each time the app starts, resumes or saves.
  - Backs off by itself: after three ignored nudges in a row it rests for 30 days, then comes back. A nudge counts as worked if you add something within an hour of it.
  - Three rotating phrasings, picked by the date, for both the habit nudge ("Chai today?") and the general one ("Anything to add today?"). The text never carries an amount or a note, and a locked screen hides it.
  - A tap opens the Add tray, exactly like the widget's Add key.
  - Off until you say yes. The question is asked once, right after your first tap on Home's missed-log line, and never again. It is skipped that time if it would cover the 4-second Undo of a one-tap add (D203).
  - **Settings › Reminders › Daily nudge** switch. It reads off, with a line saying where to allow notifications, when the phone's permission is off. Opening Settings never shows Android's permission prompt.
  - New `nudge_state` table (database schema **v6**; backups are v6 too). Older backups restore as before. *Delete everything* clears it.
- **In-app updates** through Google Play (D199).

### Changed
- Notification code now goes through one shared `NotificationHub`, so bill reminders and nudges can both receive taps. Bill reminders behave exactly as before.
- Opening the app clears a nudge that is already showing, because Home asks the same question (D205).

### Deferred
- **Adding the amount from the notification** (Part 2 of the nudge: *Add ₹20* and *Other amount* buttons). Left out on purpose as too complicated for now (D204). The specification stays in SPEC BR-22.9 to BR-22.11, marked *Deferred*. The copy for it is already in `app_en.arb`.

## [0.1.0+2] - 2026-11-14

### Fixed
- **Release builds crashed on launch.** R8 stripped the code WorkManager builds by reflection (`WorkDatabase_Impl`), so every release build, including Play closed-testing `0.1.0+1`, crashed in `InitializationProvider`. Added keep rules in `android/app/proguard-rules.pro` for Room databases, WorkManager workers and the Gson rules the notification plugin needs (D198). Every release is now checked as a release build on a device before upload.

### Added
- **Month story** (BR-20, D193, D194): once a cycle of at least 28 days with at least 10 entries has finished, a look back in up to six full-screen pages, with one bar per day. Reached from Spends only; no notification.
- **Spends graphs** (BR-21, D195 to D197): a split bar of *Everyday* and *Bills*, a comparison line against the same day last cycle, a detail card per category and a strip. New `fillSoft` colour for the *Everyday* part.
- Words for kept money: "Not spent yet" while a cycle runs, "Left over" once it has finished (D196).

## 2026-11-13

### Added
- **Fix my number** (BR-18, D165 to D168, D181, D190): when the number on Home is wrong, say how much of the month is really left and hisaab adjusts, with a preview that says so honestly.
- **Yearly costs with *Used*** (BR-19): set money aside for a yearly cost and mark it used. *Used* is a fourth entry kind that touches no daily share.
- **The missed-log line** on Home (D171, D172): if a regular habit's usual time has passed with nothing added, Home asks once a day. `suggestion_state` gained `asked_on` (schema v5).
- *Not logged* entries, shown and counted apart from *Spent* (D176).
- **Privacy policy** page and link (GitHub Pages workflow), developer details and Play Store link; GitHub social preview and Play feature graphic.
- Keypad sheets pin their controls with a full-width action key and 56dp keys; the 9-digit cap gets a held ring and a spoken line (D178, D184).
- Many tests across shortcuts, the widget snapshot, *your usual*, Bills and the income sheet.

## 2026-11-12

### Added
- **Home-screen widget, Quick Settings tile and app shortcut** for logging a spend without opening the app (FR-WG, FR-SE-6, D147, D156). The widget has four sizes, uses the hero's paper look and carries a day-by-day snapshot that a midnight job refreshes. *Settings › Shortcuts* adds the widget and the tile.
- Delete with Undo, and better empty states.

### Changed
- Imports use the `hisaab` namespace; added the `material_ui` package (D146).

## 2026-11-10

### Added
- App description, features and screenshots in the README; the licence (`LICENSE`).
- Updated onboarding illustrations.

### Changed
- Kotlin incremental compilation is disabled so builds work across drives on Windows.

## 2026-11-04 to 2026-11-06 — Bills, savings, backup

### Added
- **Bills** (BR-9, D118): a bill sheet in Settings, icons chosen from the name, a due-soon row on Home that opens the bill, and a status stamp on each bill.
- **Savings**: set money aside before its day, put in extra (capped at what is left), shown as *Saved* rows, and *Spent · Saved* side by side in Spends. Ask AI tells the AI what you save. Schema v3.
- **Bills that change, and the card bill** (D123, D127): a changing bill (like electricity) waits for you to enter its amount and is reserved at its estimate; a card bill reminds you to pay and is never counted again.
- **Bill reminders** (D126, D132): an optional notification on the day a changing or card bill is due, asked once, never showing an amount. The first use of `flutter_local_notifications`.
- **Backup and restore** as a JSON file through the system *Save to* and open screens, **Delete everything** behind a hold key (D139, D142), category icon changes.
- TodayBar and HatchKey widgets (hatched bars explained), a pace chart that steps up on bill days.

### Fixed
- A bill comes out of the pool on its day, not out of today's share; an edit that keeps the day never moves the next due date; a changing bill is answered once a month.
- Snackbars last 4 seconds instead of 6; swiped rows and their *Delete* background stay inside the card's rounded shape.

## 2026-10-26 to 2026-10-29 — Foundation

### Added
- **Core:** design tokens and light and dark themes (marigold as the single signal colour, no red or green), Anek Latin and Mukta fonts, `Money` in paise with Indian formatting (`₹1,25,000`, `₹1.25L`), the injected `Clock`, `PeriodCalculator`, logging, `get_it` wiring, SQLite with versioned migrations and seeded categories.
- **Onboarding** and the **Home hero**: how much you can safely spend today, with the Day Blocks (animated, with a trail and fill-in).
- **Add tray**: Add, digits, Next, tile. A layered *Spent | Got* pill, a drawn backspace glyph.
- **Recurring engine** (BR-8): income and bills post on their day, with catch-up exactly once.
- **Spends**: pace chart, *Where it went* with limits, insights (BR-14), *Every entry*.
- **Ask AI** (BR-15): builds a prompt deterministically from three cycles of your data, with goal cards, a live preview and a hand-off through the clipboard, share sheet or ChatGPT link. It is the only data that leaves the device, and only when you trigger it.
- **Your usual** (BR-17): learns when you usually add a category and offers it as one tap. Detection maths in `lib/habits/`.
- Hold-to-delete key, snackbar host, focus rings, etched card decoration, and typography across the app.
- Test suite, feature architecture docs, and accessibility work (contrast, semantics, tap targets, 1.5× and 2.0× text).
