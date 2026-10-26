# Memory Leak / OOM

## 1. Establish a baseline

Ask the user to:
1. Open DevTools → **Memory** tab
2. Take a snapshot at app start
3. Go through the leaking flow 5 times
4. Take a second snapshot
5. Use **Diff** to see what accumulated

Look for bloc instances, `StreamController`, `StreamSubscription`, `AnimationController`, `TextEditingController`.

## 2. Audit checklist

**Stream subscriptions**
- Search the suspected file for `StreamSubscription` fields and verify each is cancelled in `close()`/`dispose()`
- Repository change-stream listeners inside blocs (e.g. Home listening for saved entries) — is the subscription stored *and* cancelled?

**Controllers not disposed**
- Check StatefulWidgets for `TextEditingController`, `ScrollController`, `AnimationController`, `FocusNode`
- Animated widgets (`AmountText`, `DayBlocks`, `Tray`) — every `AnimationController` disposed

**Static caches never cleared**
- Static lists/maps and lazy caches (e.g. a memoised cycle summary) that survive a data restore or reset

**get_it lifetimes**
- A Bloc registered as a singleton in `core/di/` lives forever and keeps its subscriptions. Blocs are created per route, never registered as singletons

**`BlocProvider` scope too wide**
- A `BlocProvider` placed high in the tree (e.g. wrapping the `Navigator`) keeps the bloc alive forever. Confirm it is scoped to the route that needs it (`lib/app/routes.dart`)

## 3. Fix and verify
- Fix one leak at a time
- Take a new snapshot after each fix and confirm the object count drops
- Ask the user to confirm before moving to the next leak
