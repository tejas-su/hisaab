# Test doubles and testing each layer

## Fake, stub, mock

| Double | What | Default? |
|---|---|---|
| Fake | Working lightweight implementation of the interface (in-memory repo, `StreamController` socket). Can record calls | **Yes**. Assert on outcomes (state, return value) |
| Stub | Returns canned values only | When a dependency just has to answer |
| Mock | Verifies interactions ("called once with X"), usually via `mocktail`/`mockito` | Only when the call itself is the behaviour (analytics fired, repo not called on invalid input), or for awkward externals such as a router |

- Flutter's own architecture guide fakes repositories for view-model and widget tests, and uses `mocktail` for externals like the router.
- Never mock the class under test, entities, or pure functions.
- This repo has no mocking library; write fakes and record calls on them. Adding `mocktail` or `bloc_test` needs the team's approval.

## Layer by layer

| Layer | Test kind | Fakes in |
|---|---|---|
| Use case / domain logic | unit | fake repository |
| Repository | unit | fake data source / API client |
| Cubit / Bloc | unit | fake repository or use case |
| Widget / page | widget | fake repository behind a real or seeded cubit, wrapped by `pumpApp` |
| Mapper, validator, model `fromJson` | unit | none (real fixtures) |

## Bloc/Cubit tests

The community standard is `bloc_test`'s `blocTest` with `build`, `act`, `expect`. Without that package, the equivalent in this repo is `expectLater(cubit.stream, emitsInOrder(...))` set up **before** the action (see `.claude/rules/tests.md`). Test the initial state, the full state sequence, error states, and no emit after `close()`.

## Widget tests

Load the widget through one helper that injects fakes and wraps `MaterialApp`; find by key, semantics label, then text; cover loading, error, empty and success.

## Keeping tests trustworthy

- A test fails only for a valid reason: a bug, or a changed requirement.
- Existing tests are the contract. If one looks wrong, ask before editing it.
- Tests contain no logic; table cases generate one `test` per entry.
