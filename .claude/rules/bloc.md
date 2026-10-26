---
paths:
  - "lib/**/bloc/**/*.dart"
  - "lib/**/*_bloc.dart"
  - "lib/**/*_event.dart"
---

# BLoC conventions

## State management
- **Bloc everywhere; no `Cubit`.** Every state holder is a `Bloc<Event, State>` with sealed events, so every change has a named cause: `AppBlocObserver` logs each transition (event → state), and concurrency is set per event with a transformer instead of hand-rolled guards (D58)
- Files live in `presentation/bloc/`: `<name>_bloc.dart`, `<name>_event.dart`, `<name>_state.dart`
- Events name what happened, in the past tense, prefixed with the bloc: `AddEntryKeyPressed`, `HomeLoadRequested`, `BillEditorDayChosen`. A request for data is `<Name>LoadRequested`
- Register one `on<Event>` per event in the constructor, each with a private `_on<Event>` handler (or a one-line closure that calls a shared helper)
- No `setState` outside isolated leaf widgets (e.g. a key's pressed animation)
- States and events must be immutable: `const` constructors, `final` fields, `copyWith`
- One Bloc per independent concern of a screen, not one per feature: split off a slice of state that has its own inputs (e.g. the Add tray vs the Home summary); keep together state that the same events read and write
- Blocs never reference each other: coordinate them through a `BlocListener` in the page, or have both listen to a shared repository stream (e.g. `LedgerRepository.changes`)
- Keep Blocs thin — delegate all logic to use cases and pure domain functions (`SafeToSpend`, `PeriodCalculator`)
- Receive use cases or repository interfaces through the constructor, never concrete data classes, `GetIt.I`, or singletons, so a test can inject a fake
- States and events need value equality (`Equatable`); state-sequence tests depend on it
- An event can't return a value. Where a widget needs an answer (e.g. "can back leave the page?"), read it from the state (`PopScope.canPop`), not from the bloc
- Test-first: write the expected state sequence for the event, watch it fail, then implement (see `.claude/rules/tests.md`)

## Concurrency (`bloc_concurrency`)
Every handler runs `concurrent()` unless it says otherwise. Choose a transformer when two events of the same kind can overlap, and give it a `// why:`:

| Event kind | Transformer | Why |
|---|---|---|
| Loads and reloads (`…LoadRequested`, change-stream reloads, cycle navigation) | `restartable()` | The newest request wins; an older, slower read can't land stale data last |
| Saves and deletes (tile tap, day chosen, Done, Delete, "Use these limits") | `droppable()` | A second tap while the first write is in flight is dropped, even when no in-between state guards it |
| Keystrokes, toggles, filters, haptic-only events | default | Synchronous handlers; order is already kept |

- Events that must share one cancellation group (e.g. load, ‹ and › on Spends) extend a sealed sub-type and are registered once: `on<SpendsCycleEvent>(…, transformer: restartable())`, then `switch` on the event
- Debounce or throttle (search as you type) with a custom `EventTransformer` built on `Stream` operators; ask before adding `rxdart` for it
- Never replace a transformer with a hand-rolled request counter or busy flag

## Sealed classes & pattern matching
- Use `sealed` classes for states and events — enforces exhaustive `switch` at compile time
- Exhaustive `switch` expressions with no `default` fallthrough, so new variants cause compile errors
- Prefer `switch` expressions that return a value over `switch` statements with side effects

## Async
- All async operations belong in Blocs or use cases — never `await` inside `build()` or widget callbacks
- No `FutureBuilder` / `StreamBuilder` when a Bloc can own the state
- `await` everything inside a handler; `emit` is only valid until the handler's future completes
- Consume `TaskEither` results by calling `.run()` in the handler, then `.match(onLeft, onRight)`:
  ```dart
  final Either<Failure, Entry> saved = await _saveEntry(params).run();
  saved.match(
    (Failure failure) => emit(AddEntryEditing(form, failed: true)),
    (Entry _) => emit(AddEntryFinished(form)),
  );
  ```

## Streams
- Streams only for genuinely continuous data (repository change notifications after a write), not as a substitute for one-shot futures
- A repository change stream feeds the bloc by adding an event: `_changes = ledger.changes.listen((_) => add(const HomeLoadRequested()))`. Never emit from a stream callback
- Every manually opened `StreamSubscription` is cancelled in `close()`, before `super.close()`
- Own streams inside Blocs or data sources only — never in widgets

## Safety
- After an `await`, emit through the handler's `Emitter` only: it ignores emits once the bloc is closed, so no `isClosed` checks are needed
- When a handler needs another handler's work (a failed delete reloads), call the shared private helper with the same `emit` (`_load(emit)`); don't `add` an event and wait for it
- Show a write's result before the write when the UI needs it at once (a swiped row leaves the list in the first emit, so the `Dismissible` is gone by the next frame), and say so in a `// why:`

## Tracing
- `AppBlocObserver` (`lib/core/logging/`) is installed in `main` and logs each transition as `bloc.transition` with the bloc, event and state type names only. Never log an event's or state's fields: they carry amounts and notes
