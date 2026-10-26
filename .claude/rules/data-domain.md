---
paths:
  - "lib/**/data/**/*.dart"
  - "lib/**/domain/**/*.dart"
  - "lib/core/db/**/*.dart"
  - "lib/core/money/**/*.dart"
  - "lib/core/time/**/*.dart"
---

# Data & domain layer conventions

## Models & entities
- All models and entities immutable — `const` constructors and `copyWith`
- Never mutate an object directly; always return a new instance
- Models (data layer) map database rows (`Map<String, Object?>`) and export JSON; entities (domain layer) have no serialization logic

## Data class equality
- All entities, models and value objects (`Money`, `Period`) extend `Equatable` (or override `==`/`hashCode`)
- Without correct equality, Cubit state comparison silently breaks and triggers spurious rebuilds
- Value objects compare by value, not reference

## Money & time in the domain
- Amounts are `Money(amountMinor: int, currency: CurrencySpec)`; arithmetic happens on `amountMinor`. Never `double`
- Dates that mean "a day" (expense date, payday) are calendar dates (`DateTime` at local midnight, compared with `isSameDay`), never instants with a time of day
- Domain logic takes "today" as a parameter or from the injected `Clock`; it never calls `DateTime.now()`
- Period math (payday clamping to month end, weekly cycles, "it changes" → calendar month) lives only in `PeriodCalculator`

## Use cases
- One use case per operation, named as a verb phrase: `SaveEntry`, `GetCycleSummary`, `PostDueRecurring`
- Expose only a single `call()` method
- Pure: no UI, no Cubit, no direct data source access — only repository calls and pure domain functions
- Implement the abstract `UseCase<T, Params>` from `core/usecases/` — never define the contract inline

## Error handling (fpdart)
- `TaskEither<Failure, T>` for all async use cases and repository methods
- `Either<Failure, T>` for synchronous operations (mappers, validators)
- `Option<T>` instead of `T?` inside domain logic chains where absence has meaning
- Wrap data source calls with `TaskEither.tryCatch(() async { ... }, (err, st) => DatabaseFailure(err))` — never manual `try/catch`
- The base `Failure` sealed class lives in `core/errors/`; feature subtypes live in the feature's `domain/` and extend it
- Never duplicate `Failure` definitions across features
- Chain with `.flatMap`, `.map`, `.mapLeft`; no `.run()` until the Cubit layer
- `fpdart` is added in milestone M0 (see `docs/PLAN.md`); if it is missing, ask before adding it

## Mappers
- Every model ↔ entity conversion lives in a dedicated mapper class, one per aggregate
- Pure functions: `toEntity(model)` and `toModel(entity)` — no side effects
- Never inline mapping in repositories, use cases, or Cubits

## Repository contracts
- One method per operation — no business logic or decision-making
- Interfaces in `domain/`, implementations in `data/`; never merge the two
- Return domain entities or `Either<Failure, T>` — never models or raw rows
- Shape the interface from what the use case needs, not from what the tables offer; keep it small. This is what makes a hand-written fake cheap
- Every repository interface gets a fake in `test/helpers/fakes/` that `implements` it (see `.claude/rules/tests.md`)

## Data sources (sqflite)
- Data sources are the only classes that touch `AppDatabase` / `sqflite`; one per table group (transactions, categories, recurring, settings)
- They deal only with raw rows; map to models before returning
- Each data source has its own interface so it can be faked
- Repositories receive data sources through the constructor; never open the database inside a repository
- Multi-row writes (posting recurring catch-ups, restoring a backup) run inside one `db.transaction`
- Recurring posts are idempotent: rely on the unique index `transactions(recurring_id, date)` and `ConflictAlgorithm.ignore`

## Schema & migrations
- Every schema change bumps the DB version and adds a migration step in `core/db/migrations/`; never edit a shipped migration
- Migrations are additive where possible; test each one from the previous version's schema

## Known pitfall
- sqflite rows are `Map<String, Object?>`: narrow each column with `is` checks (`row['amount_minor'] is int`) and handle `null` at the boundary. An `as` cast throws a `TypeError` when the schema drifts
