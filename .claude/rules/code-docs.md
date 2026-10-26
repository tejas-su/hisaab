---
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Code documentation (Dart)

Applies whenever you write or change Dart code. Document the code **you add or change** to this standard. Don't backfill docs across untouched files unless asked; that's what the `document-code` skill is for.

Feature-level docs (architecture, flows, behaviour) don't go in code comments. They go in `docs/features/<feature-name>/` (see `.claude/rules/feature-docs.md`).

## Philosophy

This codebase is **self-documenting by naming**. Code explains *what* through clear names; comments explain only *why*: decisions, constraints, and trade-offs you can't see from the code.

If a comment would be deleted on first read because it adds nothing, it must not exist. If you feel you need a comment to explain *what* code does, rename or extract first.

## Dartdoc (`///`) — public API

Add `///` to every **public** class, mixin, enum, extension, typedef, method, constructor, and property.

**Required on:**
- All public classes: what the class is for, in one sentence
- All public methods: one sentence minimum stating what it does
- Non-obvious constructor parameters (valid range, format, units, who owns disposal)
- Anything returning `TaskEither`, `Either`, or `Option`: state what Left and Right (or None) represent
- Public `Future`/`Stream` APIs: when they complete or emit, and whether they can error

**Not required on:**
- Private members (`_name`) unless the logic is genuinely surprising
- Self-evident getters/setters (`bool get isLoading`)
- Overrides where the parent already documents the contract (`build`, `close`, `props`, `toString`)

**Format:**
```dart
/// Loads the summary of the pay cycle that contains [day].
///
/// Returns [Right] with [CycleSummary] on success, or [Left] with
/// [DatabaseFailure] if the read fails or [NoIncomeFailure] when no
/// income has been set up yet.
///
/// [day] is a calendar date; its time of day is ignored.
TaskEither<Failure, CycleSummary> call(DateTime day) { ... }
```

- First line: one sentence summary starting with a verb (methods) or a noun phrase (classes); no full stop needed
- Blank `///` line before any extended description
- Reference symbols with `[ClassName]`, `[methodName]`, `[parameterName]`
- No `@param` / `@return` / `@throws` tags. Use prose and `[references]`
- Put code samples in fenced ```dart blocks inside the dartdoc, only when usage isn't obvious
- Use `///`, never `/** */`

## What to document, by kind

| Kind | Document |
|---|---|
| Entity | The business concept it represents, not its fields' types |
| Model | The table it maps, and column names that differ from the field names |
| Mapper | Only non-obvious conversions (defaults, unit changes, fallbacks) |
| Use case | The operation, its params, and what Left/Right mean |
| Repository contract | Each method's contract: inputs, outputs, failure cases |
| Bloc/Cubit | What state it owns and who drives it (methods/events, repository streams, parent screen) |
| Bloc events | The user intent or trigger each event represents |
| Bloc states | The UI situation each state maps to |
| Widget | What it renders and when to use it; required inputs and callbacks |
| Enum | The set as a whole, plus any value whose meaning isn't obvious from its name |
| Extension | The type it extends and the behaviour it adds |
| Barrel file | A `library;` dartdoc saying what the feature exposes |

## Failures

Every `Failure` variant documents what causes it:

```dart
/// A sqflite read or write threw.
final class DatabaseFailure extends Failure { ... }

/// No recurring income exists yet, so no pay cycle can be computed.
final class NoIncomeFailure extends Failure { ... }
```

## Inline comments (`//`): why only

Use them only for non-obvious decisions, prefixed with `// why:`:

```dart
// why: Delay avoids a race condition with the keyboard dismiss animation.
await Future.delayed(const Duration(milliseconds: 150));

// why: rows written before migration v2 have no note value — treat as empty.
final Object? rawNote = row['note'];
final String note = rawNote is String ? rawNote : '';
```

Things that warrant a `// why:`:
- Workarounds for framework, plugin, or backend bugs (link the issue if one exists)
- Business rules that aren't visible from names
- Ordering or timing that matters (race conditions, debounce values)
- Every `!` force-unwrap: state the invariant that guarantees non-null
- Deliberately swallowed errors, and ignored lints (`// ignore:` must be followed by a reason)

## Deprecation

Mark with `@Deprecated('Use [NewThing] instead. Remove after <version/date>.')` and say in the dartdoc what replaces it.

## TODOs

Always use `// TODO(owner): description`, with an owner and, once an issue tracker exists, a ticket (`// TODO(tejas): #12 — description`). No bare `// TODO`.

## Never write

- Comments restating the code: `// increment the counter` above `counter++`
- Comments restating the name: `// get user` above `getUser()`
- Section dividers: `// ---- helpers ----`
- Commented-out code: delete it; version control has the history
- Change logs or author/date headers in files: git has that
- Comments that will go stale immediately (line numbers, "see above", current ticket status)

## When you change code

- Keep existing dartdoc accurate. If your change alters behaviour, parameters, or failure cases, update the doc in the same edit
- Delete comments that your change makes wrong or obsolete
