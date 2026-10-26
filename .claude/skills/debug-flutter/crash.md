# Crash / Exception

## 1. Locate the error
- Read the full stack trace. Don't guess from the message alone
- If only a symptom is given, search for `AppLogger.recordError` tags near the suspected flow
- Find the **innermost** frame that belongs to this codebase (not Flutter framework frames)

## 2. Classify the origin

| Origin | Where to look |
|---|---|
| Database | `core/db/`, `*_data_source*.dart` — migration errors, constraint violations, `as` casts on rows |
| Repository | `*_repository_impl.dart` — is the exception mapped to a `Failure` or swallowed? |
| Use case | `*_usecase.dart` — does the exception propagate or get swallowed? |
| Bloc/Cubit | the `on<Event>` handler or cubit method — missing `isClosed` guard before `emit()` |
| Widget | `initState`, `dispose`, `BlocProvider.of()` outside `build` |

## 3. Crash patterns to check first
- **`emit()` after close** — a save or load finishes after the tray or page closed. Check for an `isClosed` guard after every `await`
- **Migration failure on upgrade** — `onUpgrade` throws, so the app crashes at startup for existing users only. Reproduce by installing the previous version's schema, then upgrading
- **Row cast errors** — a model's `fromRow` uses `as` on a column that can be `null` or the wrong type. Narrow with `is`
- **Unique-constraint violation** — a recurring post inserted twice without `ConflictAlgorithm.ignore`
- **Missing l10n key** — a string was added to code but not to `app_en.arb`, or `flutter gen-l10n` wasn't run
- **`BlocProvider.of(context)` in `initState`** — stale context if the widget re-mounts
- **Silently swallowed exceptions** — bare `catch (e) {}` with no `AppLogger.recordError`

## 4. Fix and verify
- Make the minimal change. Don't refactor surrounding code
- Confirm the error path now reaches `AppLogger.recordError`; add it if not
- Ask the user to reproduce and confirm the crash is gone
