---
paths:
  - "test/**/*.dart"
  - "integration_test/**/*.dart"
---

# Testing conventions

Test dependencies: `flutter_test` and `sqflite_common_ffi` (real in-memory SQLite for data sources and repositories; `test/helpers/test_database.dart`). `mocktail`, `mockito`, `bloc_test` and `fake_async` are **not** installed: write hand-written fakes and ask before adding a test dependency. `test/helpers/fake_services.dart` wires every service from fakes for widget and app tests.

## When to write tests

- **New code** ships with tests in the same change. Write or update the test alongside the source, not afterwards
- **Bug fixes** get a regression test that fails before the fix and passes after
- **Changing legacy code:** add tests for the behaviour you changed if the code can be tested as-is. If it can't (hard-wired singletons, `static` state, no constructor injection), say so and propose the smallest seam. Don't refactor a legacy file just to test it without asking
- Don't backfill tests for untouched code unless asked

## TDD workflow (red → green → refactor)

Background and sources: `docs/features/tdd-in-flutter/`.

1. **Red:** write one test for one behaviour and run it. It must fail for the expected reason (missing behaviour, not a typo or compile error)
2. **Green:** write the least code that passes. No extra branches or speculative parameters
3. **Refactor:** clean up `lib/` and the test with every test still green. Never edit an assertion during refactor
4. Repeat in small steps, one behaviour per cycle. A bug fix starts with a test that reproduces it
- **Test-first is the default for logic:** use cases, repositories, mappers, validators, Blocs. For layout-only widget work, building first is fine, but the tests land in the same change
- **If the test is hard to write, change the design, not the test:** the usual causes are a hard-wired singleton, a dependency built inside the class, or a function doing more than one thing
- Proportions follow the test pyramid: many unit tests, many widget tests, few integration tests (integration tests aren't set up here)

## Abstraction for testability

- **Abstract each I/O boundary, and only those:** repositories, data sources (sqflite), platform or plugin access (clipboard, share sheet, `url_launcher`, haptics), and clock/ID/random sources. Don't add an interface for pure functions, mappers, entities, or a class with a single implementation and no I/O
- **Define the interface from the consumer's need.** Ask what the use case or bloc must call, not what the API offers. Keep interfaces small; split a wide one rather than faking many methods
- **Inject through the constructor.** The class under test never builds its dependencies, uses `static` state, or looks them up through `BuildContext` (see `.claude/rules/dart-core.md`, "Dependency wiring"). The real implementation is wired only at the feature's composition root
- **The fake implements the same abstract class** as the real one, so a signature change breaks the fake at compile time
- **Legacy code with a hard-wired singleton:** add the smallest seam (a constructor parameter, real thing wired at the composition root) and say so in the report. Ask before refactoring a legacy file only to test it
- **Widgets receive their bloc or dependencies from above** (constructor or `BlocProvider`), so a test can pass a fake or a seeded bloc

## Coverage: every piece of new code is covered

**Thresholds (hard, measured by `scripts/changed_lines_coverage.sh`):**

| Scope | Requirement |
|---|---|
| All lines you added or changed, together | **≥ 90%** covered (hard floor; the script fails below it) |
| Target for those lines | **100%**. Every uncovered line is a named, justified gap (see below), even above the floor |
| Whole repo | No threshold. Don't backfill untouched code |

- **Why 90%, not a hard 100%:** Google's guidance is that per-commit goals of 99% are reasonable and 90% is a good lower threshold, and that chasing 100% gives diminishing returns and a false sense of security. A floor every change can reach, plus honest reporting of gaps, gives better tests than a 100% gate that pushes toward assertion-free tests or `coverage:ignore` comments
- **New pure-Dart logic** (use cases, mappers, validators, repositories with fakes, Blocs) is cheap to test: aim for 100% and expect no gaps. The floor is for what can't be tested as-is (see the acceptable gaps below)

- Every new or changed function, method and branch must be exercised by a test. Being above the floor doesn't excuse a gap: a gap is only acceptable for platform-only code, a hard-wired singleton in legacy code, or a defensive branch that is unreachable; "didn't get to it" is not a reason
- **Metric:** line coverage is the gate. Branch coverage (`--branch-coverage`, `BRDA:` entries in lcov) is collected too; use it to spot an untested `if`/`else` body or `switch` arm on your changed lines, but it has no numeric threshold
- **Excluded from the report** (don't test or list): `*.g.dart`, `*.mocks.dart`, generated l10n (`lib/l10n/gen/`), the `lib/main.dart` entry point, `lib/app/routes.dart` and `lib/core/di/` wiring, and barrel files that only `export`
- **Don't add `// coverage:ignore-line`, `// coverage:ignore-start` … `// coverage:ignore-end`, or `// coverage:ignore-file`.** `flutter test --coverage` honours these comments and drops the lines from `lcov.info`, so they hide gaps instead of closing them. The script fails on every one you add; if one is really needed, list it under `Gaps:` with the reason
- `coverage/` is build output; don't commit it

**Check it before calling work done** (run from the repo root; needs git):
```bash
scripts/changed_lines_coverage.sh            # uncommitted work vs HEAD
scripts/changed_lines_coverage.sh main       # whole branch vs its merge-base with main
SKIP_TESTS=1 scripts/changed_lines_coverage.sh   # reuse existing coverage/lcov.info
```
It runs `flutter test --coverage --branch-coverage`, intersects `git diff -U0` (from the merge-base, renamed files included) with `coverage/lcov.info`, prints uncovered changed lines per file and the total, lists changed files that have no coverage data, and exits non-zero if the total is below 90% or a `coverage:ignore` comment was added. To inspect a single file by hand instead:
```bash
awk -v f="lib/path/to/changed_file.dart" '$0=="SF:"f{p=1;next} /^end_of_record/{p=0} p&&/^DA:/{split(substr($0,4),a,",");if(a[2]==0)print f":"a[1]}' coverage/lcov.info
```

**Reading `coverage/lcov.info`:** one block per file, from `SF:<path>` to `end_of_record`.

| Record | Meaning | Example |
|---|---|---|
| `DA:<line>,<hits>` | **Line data:** an executable line and how many times it ran; `0` = uncovered. The script gates on these only | `DA:11,2` |
| `BRDA:<line>,<block>,<branch>,<taken>` | **Branch data** (only with `--branch-coverage`): a block that can be entered (function body, `if` body, `else` body, `switch` `case`/`default` or switch-expression arm) and how many times it was entered; `0` = never. In Dart's output `<block>,<branch>` is always `0,0`: read the line and the last number | `BRDA:8,0,0,0` |
| `LF`/`LH` | Found/hit totals of `DA` entries. Dart writes no `BRF`/`BRH` totals; count `BRDA` entries yourself | `LF:6` `LH:6` |

- **A line with no `DA` entry is invisible to the gate.** The VM doesn't instrument comments, imports and braces, and also skips some real code, such as `return <constant>;` and `const` expressions. So 100% of changed lines does **not** prove every branch ran:
  ```dart
  if (percent >= 100) {   // DA:8,1 BRDA:8,0,0,0  the condition ran (line covered), the body was never entered
    return 0;             // no DA entry          never counted
  }
  ```
  The script reports this function as 100% while `percent >= 100` is untested.
- **Neither metric sees `?:`, `??`, `&&`/`||` operands.** They get no `BRDA` entry, and an operand only has a `DA` entry when it sits on its own line and isn't a constant. `return v > 0 ? v : null;` shows as covered after one call. Give each operand its own test case from reading the code
- **Before reporting coverage, list the never-taken branches** of each changed file; each one gets a test or is listed under `Gaps:`:
  ```bash
  awk -v f="lib/path/to/changed_file.dart" '$0=="SF:"f{p=1;next} /^end_of_record/{p=0} p&&/^BRDA:/{split(substr($0,6),a,",");if(a[4]=="0")print f":"a[1]" branch never taken"}' coverage/lcov.info
  ```
- **A changed file with no `SF:` block** is listed by the script under `NO COVERAGE DATA` but doesn't fail it, because there are two causes: no test loads the file (its code is untested), or it has no executable lines (an abstract interface, an enum, an `export`-only barrel). For each listed file, confirm which one applies. If it has logic, import it from a test

**Report it in this format** in the final message:
```
Coverage (changed lines): lib/x/presentation/bloc/y_bloc.dart 24/24, lib/x/data/z.dart 10/12
Total: 34/36 (94.4%), floor 90% ✓
Gaps: lib/x/data/z.dart:41-42 — platform channel call, no seam without refactor
```

## One responsibility → complete, focused tests

Testability starts in `lib/`: each function does **one thing** (see `.claude/rules/dart-core.md`). If you can't describe a function's tests without "and", split the function first. For example, keypad input is a pure `String appendDigit(String current, String key)` (leading zeros, the 9-digit cap); formatting the result is `MoneyFormatter`'s job and the haptic is the widget's. Each is tested on its own. The `isValidEmail` example below shows the shape of a complete table of cases.

Every function under test needs all three kinds of case:

| Kind | Covers |
|---|---|
| **Happy path** | Typical valid inputs produce the expected result |
| **Negative path** | Invalid input, failures, exceptions, and error states, each asserted precisely (which `Failure`, which error state) |
| **Edge cases** | Empty, whitespace-only, `null` (at boundaries), min/max length, boundary values (0, -1, max), unicode/special characters, duplicates, very large inputs, and ordering/timing for async code |

Example: the spec for `isValidEmail`. Confirm the actual rules (TLD required? `+` tags allowed?) with the product/backend definition before writing the cases:

```dart
void main() {
  group('isValidEmail', () {
    const List<String> validEmails = <String>[
      'user@example.com',
      'first.last@example.com',
      'user+tag@example.com',
      'user@sub.example.co.in',
      'USER@EXAMPLE.COM',
      'u@example.io',
    ];
    const List<String> invalidEmails = <String>[
      'plainaddress',
      '@example.com',
      'user@',
      'user@@example.com',
      'user@example',
      'user@.com',
      'user@example..com',
      'user..name@example.com',
      '.user@example.com',
      'user.@example.com',
      'user@exa mple.com',
    ];
    const List<String> edgeCaseEmails = <String>[
      '',
      ' ',
      ' user@example.com ',
      'user@example.com\n',
    ];

    for (final String email in validEmails) {
      test('accepts valid email "$email"', () {
        expect(isValidEmail(email), isTrue);
      });
    }
    for (final String email in invalidEmails) {
      test('rejects malformed email "$email"', () {
        expect(isValidEmail(email), isFalse);
      });
    }
    for (final String email in edgeCaseEmails) {
      test('rejects edge-case input "${email.replaceAll('\n', r'\n')}"', () {
        expect(isValidEmail(email), isFalse);
      });
    }
    test('rejects a local part longer than 64 characters', () {
      expect(isValidEmail('${'a' * 65}@example.com'), isFalse);
    });
    test('rejects an address longer than 254 characters', () {
      expect(isValidEmail('user@${'a' * 250}.com'), isFalse);
    });
  });
}

## Location & naming

- `test/` mirrors `lib/`: `lib/add_entry/presentation/bloc/add_entry_bloc.dart` → `test/add_entry/presentation/bloc/add_entry_bloc_test.dart`
- Test files end in `_test.dart`; one test file per source file under test
- Shared test code lives in `test/helpers/`:
  ```
  test/helpers/
  ├── fakes/        ← hand-written fakes of repositories, data sources, services
  ├── mocks/        ← mock declarations (and generated *.mocks.dart, if mockito is ever added)
  ├── fixtures/     ← DB rows, backup JSON, expected AI prompts; one folder per feature
  └── pump_app.dart ← widget-test wrapper (MaterialApp + theme + providers)
  ```
- Accessibility guideline tests go in `test/a11y_test.dart` (see `.claude/rules/accessibility.md`)

## What to test (in priority order)

1. **Use cases & domain logic:** every branch, including every `Failure` path
2. **Mappers and model `fromRow`/`toRow`/`toJson`:** real row shapes, plus missing, `null`, and wrong-typed columns
3. **Repositories:** with fake data sources. Success, thrown exceptions mapped to the right `Failure`, and empty results
   - **Date and money logic gets extra edge cases:** payday on the 29th–31st in February and 30-day months, leap years, a cycle that crosses a year, the last day of a cycle, zero days left, ₹0, the 9-digit cap, overspend larger than the remaining total, recurring catch-up after weeks away (and posted exactly once)
4. **Blocs:** the initial state, the emitted state sequence for each event, error states, overlapping events (a second tap, a newer load), and no emit after `close()`
5. **Widgets:** each Bloc state renders the right UI; key interactions call the right event/callback
6. **Validators, formatters, extensions:** table-style happy, negative, and edge cases (see the `isValidEmail` example above)

Don't test Flutter or third-party behaviour, trivial getters, or private methods directly. Test those through the public API.

## Structure

- `group('<ClassName>', ...)` per class, with a nested `group('<methodName>', ...)` where useful
- Test names describe behaviour: `'emits [Loading, Loaded] when fetch succeeds'`, `'returns ServerFailure when the API throws'`
- Arrange → Act → Assert (set up, one action, expectations), one behaviour per test. A test must not depend on another test's result or on execution order, and must not use artificial delays
- No logic in tests (no `if`/loops deciding what to assert). For table cases, build the list and generate one `test` per entry
- Fresh instances in `setUp`. Close blocs and dispose controllers in `tearDown`
- Tests follow the same lints as `lib/` (`analysis_options.yaml`: no `print`, typed public APIs)

## Test doubles: mocks vs fakes vs stubs

Know which one you're writing, and name it accordingly:

| Double | What it is | Use when | Naming / location |
|---|---|---|---|
| **Fake** | Hand-written, working, lightweight implementation of the real interface (in-memory repository, fixed `FakeClock`) | **Default.** The test cares about *outcomes* (state, return value) | `FakeX` in `test/helpers/fakes/` |
| **Stub** | Returns canned values only, with no logic or recording | A dependency just has to answer so the code under test can run | `StubX`, next to the test or in `fakes/` |
| **Mock** | Records and verifies *interactions* (was `send()` called once with these args?). Usually **generated** by a library (`mockito` with `@GenerateNiceMocks` → `*.mocks.dart`) or created with `mocktail` | The interaction *is* the behaviour, e.g. analytics fired, a logger called, a repository **not** called on invalid input | `MockX` in `test/helpers/mocks/` |

Rules:
- Assert on outcomes with fakes first. Reach for a mock only when the call itself is what matters; over-mocking ties tests to implementation details
- **Never mock the class under test**, value objects/entities, or simple pure functions. Use the real thing
- **Generated mocks are build output:** never hand-edit `*.mocks.dart`. Change the `@GenerateNiceMocks` annotation and regenerate with `dart run build_runner build --delete-conflicting-outputs`
- No mocking library is installed today. Until one is added (ask first), write fakes, and record calls on a fake when you need to verify an interaction

Details:
- Prefer **hand-written fakes** that implement the real interface (`class FakeLedgerRepository implements LedgerRepository`). Constructor injection makes this straightforward
- Fakes return configurable canned results and record calls when a test needs to assert on them:
  ```dart
  class FakeLedgerRepository implements LedgerRepository {
    TaskEither<Failure, TransactionEntity> result = TaskEither.right(testEntry);
    final List<NewEntry> saved = <NewEntry>[];

    @override
    TaskEither<Failure, TransactionEntity> save(NewEntry entry) {
      saved.add(entry);
      return result;
    }
  }
  ```
- The `TaskEither` examples assume `fpdart`, which lands in milestone M0
- Never touch the real on-device database, the clipboard, the share sheet, `url_launcher` or haptics in unit/widget tests. Inject a fake (an in-memory `sqflite_common_ffi` database only for data-source tests)
- Never depend on wall-clock time or randomness. Inject `FakeClock` for anything involving "today", paydays or cycles

## Bloc tests (without `bloc_test`)

`test/helpers/bloc_dispatch.dart` adds `bloc.dispatch(event)`: it adds the event and waits for the handler and its awaited fakes.

```dart
test('emits [Loading, Loaded] when the load succeeds', () async {
  final FakeItemsRepository repository = FakeItemsRepository();
  final ItemsBloc bloc = ItemsBloc(repository: repository);
  addTearDown(bloc.close);

  final Future<void> expectation = expectLater(
    bloc.stream,
    emitsInOrder(<Matcher>[isA<ItemsLoading>(), isA<ItemsLoaded>()]),
  );

  await bloc.dispatch(const ItemsLoadRequested());
  await expectation;
});
```

- Set up `expectLater` **before** acting, so no emission is missed
- Assert on state types with `isA<T>()`, and on fields with `.having(...)` when the values matter
- Also test the initial state, and that closing mid-request doesn't throw: `bloc.add(event); await expectLater(bloc.close(), completes);`
- **Every transformer gets a test that fails without it.** The fakes answer at once, so overlap never happens by itself: gate the fake (`nextReadGate`, `nextDeleteGate`, a `Completer`) so the first event is still in flight when the second arrives. For `restartable()`, a slow load with stale data must not land last; for `droppable()`, a second save while the first is gated must not write twice

## `TaskEither` / `Either` results

```dart
final Either<Failure, UserEntity> result = await getUserProfile('id').run();
expect(result.isLeft(), isTrue);
result.fold(
  (Failure failure) => expect(failure, isA<ServerFailure>()),
  (UserEntity _) => fail('expected Left'),
);
```

## Widget tests

- Wrap with `pumpApp` from `test/helpers/pump_app.dart` (MaterialApp, app theme, `BlocProvider.value` with a seeded fake/real bloc), not bare widgets
- Find by `Key` (`find.byKey(const ValueKey<String>('submit-button'))`), semantics label, or text, in that order of preference. Avoid finding by widget type when several instances exist
- `await tester.tap(...)` then `await tester.pump()`. Use `pumpAndSettle` only when no infinite animation (e.g. a spinner) is on screen
- **A bloc handles events in the zone it was built in.** Build it in `setUp` or with `tester.buildBloc(...)`, outside the test's fake async zone (one built inside never finishes `close()` in a tear-down). After an interaction that adds an event, call `tester.settle()` (from `bloc_dispatch.dart`), not `pumpAndSettle()`, so the bloc gets a real event-loop turn
- Cover the loading, error, empty, and success states of any widget that switches on Bloc state

## Existing tests are the contract. Don't edit them to pass

- Once a test is in place, it defines the expected behaviour. **Change the code to satisfy the test, never the test to satisfy the code**
- Don't modify, loosen, delete, or `skip:` an existing test as part of making your change pass. That includes changing expected values, swapping precise matchers for looser ones (`isA<Failure>()` in place of `isA<ServerFailure>()`), and removing cases from a table
- If an existing test seems wrong, or a requirement genuinely changed, **stop and ask the user**. Explain which test, what it asserts, and why it should change. Edit it only after they confirm, and say so in your report
- New behaviour gets **new** tests; add cases rather than rewriting old ones
- Allowed without asking: purely mechanical updates that keep every assertion identical (e.g. an import path after a file move the user asked for). List them in your report

## Fixtures

- Store row sets, backup files and expected prompt text in `test/helpers/fixtures/<feature>/`
- **Sanitise fixtures:** no real names, notes, phone numbers, UPI IDs or account details
- Keep fixtures minimal; add a separate fixture per edge case rather than one giant file

## Not set up — don't add unasked

Golden tests, integration tests (`integration_test/`), CI pipelines (including a CI coverage gate; `scripts/changed_lines_coverage.sh` is the local gate and can be wired into CI or a pre-push hook if the team asks), and new test packages (including mock generators).

## Running & reporting

- `flutter test` (all), `flutter test test/path/file_test.dart` (one file), `flutter test --name '<test name>'` (one test)
- Before calling work done:
  1. The new tests **and all existing tests** for the touched code pass
  2. `scripts/changed_lines_coverage.sh` passes (changed lines ≥ 90% in total), and every uncovered line is listed with a reason in the report format above
  3. `flutter analyze` is clean for the changed files
- Report failures honestly, with the output. A failing existing test means the code is wrong until the user says otherwise
