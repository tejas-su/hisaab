---
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Core Dart conventions

## Architecture
- Clean Architecture: `data` → `domain` → `presentation` layers, strictly no cross-layer leakage
- Feature-first folder structure; each feature owns its `data/`, `domain/`, and `presentation/` (only the layers it needs)
- Domain layer must be pure Dart — no Flutter, no Bloc, no `sqflite`, no JSON imports
- Repository contracts in `domain/`, implementations in `data/`
- `lib/ledger/` is the shared money feature: entities, repositories and use cases for transactions, categories and recurring rules. UI features (`home`, `add_entry`, `spends`, `ask_ai`, `onboarding`, `settings`) import it through its barrel `ledger.dart`, never its internal files

## Core layer (`lib/core/`)
- Shared, app-wide code lives in `lib/core/`, never inside a feature folder:
  ```
  lib/core/
  ├── db/           ← AppDatabase (sqflite), versioned migrations
  ├── design/       ← tokens (HisaabColors), type, motion, haptics, AppIcon/AppIcons
  ├── di/           ← get_it registration (composition root only)
  ├── errors/       ← base Failure abstract class and shared Failure subtypes
  ├── extensions/   ← extension methods on Dart/Flutter types
  ├── layout/       ← AppLayout.resolve, AppLayoutScope (adaptive panes, folds)
  ├── logging/      ← AppLogger
  ├── money/        ← Money, CurrencySpec, MoneyFormatter
  ├── time/         ← Clock abstraction, PeriodCalculator
  ├── usecases/     ← abstract UseCase<T, Params> base class
  └── widgets/      ← shared UI components (Keypad, AmountText, DayBlocks, SignalKey, Tray…)
  ```
- Core has **no knowledge of any feature**: no imports from `lib/<feature>/`
- Never put feature-specific business logic, models, or entities in `core/`
- A file belongs in `core/` only if two or more unrelated features would otherwise duplicate it
- `core/errors/` defines the base `Failure` abstract class (not `sealed`: Dart forbids subclassing a sealed class from another library); features extend it in their own `domain/`
- `core/usecases/` defines the abstract `UseCase<T, Params>`; all feature use cases implement it

## Naming
- Files: `snake_case.dart`; classes: `PascalCase`; private members: `_camelCase`
- Cubit files: `<feature>_cubit.dart`, `<feature>_state.dart`; Bloc files add `<feature>_bloc.dart`, `<feature>_event.dart`

## Code quality
- SOLID principles; prefer composition over inheritance
- Self-documenting names — no abbreviations; comments explain only *why* (see `.claude/rules/code-docs.md`)
- No magic numbers or strings; extract to constants (design values live in `core/design/` tokens)

## Function design
- One function = one responsibility; if you need "and" to describe it, split it
- Name must state exactly what the function does — no `handleData`, `processStuff`
- Max ~20 lines per function; extract longer logic into named helpers
- Max 3 parameters; group related params into a value object if more are needed
- Early returns / guard clauses — never more than 2 levels of indentation
- No `else` after a `return`

## Functional programming
- Prefer pure functions — same input, same output, no side effects
- Use `map`, `where`, `fold`, `reduce`, `expand` over imperative `for` loops
- Never mutate a list or map in place; transform and return a new collection
- Side effects (I/O, database, clipboard, share sheet) only in data sources and Blocs/Cubits

## Money, dates and locale (app-specific, non-negotiable)
- Money is **always** `int` minor units (paise) wrapped in `Money`; never `double` for an amount
- Format amounts only through `MoneyFormatter` (`en_IN`: `₹1,25,000`, compact `₹1.25L`); never build `₹` strings by hand
- "Now" comes from the injected `Clock`, never `DateTime.now()` in logic; period math lives in `PeriodCalculator`
- User-facing text comes from `AppLocalizations` (`lib/l10n/app_en.arb`), never a string literal in a widget

## Null safety
- Never use `!` without an explicit invariant guarantee and a `// why:` comment explaining it
- Prefer `??` for defaults, `?.` for optional chaining, early guard returns for required values
- Unwrap nullables at system boundaries (database rows, user input); pass non-nullable types inward

## Type safety
- No `dynamic` or `Object` unless interfacing with untyped data (sqflite rows) — cast and narrow immediately
- Explicit return and parameter types on every public signature; `var`/`final` without a type is fine for locals
- Full generics: `List<TransactionEntity>` not `List`, `Map<String, Object?>` not `Map`
- Avoid `as` casts; prefer `is` checks with narrowing or pattern matching

## Dependency wiring
- `get_it` is the service locator, used **only** in `lib/core/di/` and at composition roots (route/page builders). Nothing else calls `GetIt.I`
- Pass dependencies via constructor arguments; never instantiate them inside Blocs/Cubits or widgets
- Depend on an abstract class at every I/O boundary (repository, data source, platform service such as clipboard, share, haptics, clock) so a fake can replace it in tests; don't add interfaces elsewhere (see `.claude/rules/tests.md`, "Abstraction for testability")
- The page receives what it needs through its constructor from the route builder; below the page, dependencies travel through constructors too — no service lookup through `BuildContext`, and no default parameter that builds a concrete data-layer class

## Exports
- Each feature exposes a single barrel file (`<feature>.dart`) with its public API
- Never re-export internal files (data sources, mappers) from the barrel

## Enums & finite state
- Use `enum` or `sealed` for any finite set of values — never raw `String`/`int` constants
- Always handle enums exhaustively in `switch`

## Late initialisation
- Avoid `late` unless guaranteed assigned before first access and not constructor-injectable
- Prefer nullable + guard check or constructor injection

## Extension methods
- Add behaviour to existing types, not a utility dumping ground
- One extension per file, named `<Type>Extensions`; stateless and pure

## Keys
- Pass a `Key` to widgets in lists or conditionally-rendered subtrees
- Prefer `ValueKey`/`ObjectKey` over `UniqueKey` (forces a full rebuild every time)
- Avoid `GlobalKey` unless necessary (e.g. `FormState`)

## Code hygiene
- No commented-out code — delete it
- Remove unused imports and variables
- String interpolation (`'$name'`) over concatenation

## Logging
- Use `AppLogger` from `lib/core/logging/` (`AppLogger.log(tag: '...', data: {...})`, `AppLogger.recordError(error, stackTrace)`) — never `print()` (`avoid_print` is enabled)
- Never log amounts together with notes or any other personal text
