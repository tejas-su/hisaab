# Wrong State / Logic Bug

## 1. Trace the state back

Flow: **Event → Handler → emit(State) → BlocBuilder/BlocListener**

Ask: "What state do you *expect*, and what do you *see*?" Then trace backwards:

1. Which `BlocBuilder` / `BlocConsumer` renders the wrong data?
2. Which state subclass and field is it rendering?
3. Which bloc emits that state — find the `emit(...)` call
4. What event or method triggered that emit — follow the call chain
5. Where did the *data* come from — repository, a domain calculation (`SafeToSpend`, `PeriodCalculator`), or local state?

## 2. Enable BLoC tracing (ask the user to add it temporarily)

In `lib/main.dart`, before `runApp()` (debug builds only, remove afterwards):

```dart
Bloc.observer = _DebugBlocObserver();

class _DebugBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('[BLOC] ${bloc.runtimeType} received $event');
  }
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('[BLOC] ${bloc.runtimeType}: ${transition.currentState} → ${transition.nextState}');
  }
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('[BLOC ERROR] ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }
}
```

Every state holder is a Bloc, and `AppBlocObserver` already logs each transition as `bloc.transition` (bloc, event, from, to; type names only). Ask the user to reproduce and paste those lines first; add the temporary observer above only when you need field values.

## 3. Wrong-number suspects in this app
- **Date math** — payday on the 29th–31st in a short month, a cycle crossing the year, "today" taken from `DateTime.now()` instead of the injected `Clock`, or a `DateTime` with a time of day compared as if it were a date. Reproduce with `FakeClock` pinned to the reported date
- **Off-by-one days left** — whether today counts as a day; `DayBlocks` and `SafeToSpend` must agree
- **Recurring catch-up** — posted twice (missing unique index) or skipped (wrong `next_due` advance)
- **Money precision** — a `double` slipped into an amount path; amounts must stay `int` paise
- **Month start setting** — "Payday" vs "1st of month" not passed into `PeriodCalculator`
- **Stale summary after a save** — the Home bloc didn't re-read after the Add tray saved (no repository change stream, or the listener isn't wired)

## 4. Fix and verify
- Fix only the state transition that is wrong
- Ask the user to confirm the correct state now emits
