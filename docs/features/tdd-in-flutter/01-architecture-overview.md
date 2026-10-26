# TDD in Dart/Flutter: overview

Research summary of how test-driven development is practised in Dart and Flutter, and how it maps onto this repo's rules. Written from web research on 2026-10-09; see `04-sources-and-gaps.md` for sources and limits. This is team guidance, not a description of one feature's code.

## Core idea

Write a failing test first, make it pass with the least code, then clean up while the tests stay green. The test is the first user of the code, so it forces a small, injectable, clearly named API.

## Red → green → refactor

| Step | Do | Check |
|---|---|---|
| Red | Write one test for one behaviour. Run it and see it fail for the expected reason | A failing test that fails because the behaviour is missing, not because of a typo |
| Green | Write the minimum code that passes. No extra branches, no speculative parameters | All tests pass |
| Refactor | Rename, extract, remove duplication, in `lib/` and in the test | All tests still pass, no assertion edited |

- Repeat in small steps: one behaviour per cycle, minutes not hours.
- A bug fix starts with a test that reproduces the bug (red), then the fix (green).
- TDD is not required for every line. Throwaway spikes and pure layout are fine to build first, but add tests before the change is done.

## Test-first shapes the design

- If the test is hard to write, the design is wrong: too many responsibilities, a hard-wired singleton, or a dependency created inside the class. Change the design, not the test.
- Writing the test first makes you name the dependency by what the class needs from it, which is where abstract interfaces come from (see `02-abstraction-and-injection.md`).

## Test types and proportions

| Type | Scope | Speed | Confidence | Use for |
|---|---|---|---|---|
| Unit | one function/class, dependencies faked | fastest | lower | use cases, mappers, repositories, cubits/blocs, validators |
| Widget | one widget or screen, fakes injected | fast | higher | each state renders; interactions call the right callback |
| Integration | whole app or large flow, on a device | slow | highest | a few critical journeys (not set up in this repo) |

Shape: many unit tests, many widget tests, few integration tests (Flutter docs).

## Shape of one test

Set up → one action → expectations (Arrange / Act / Assert). One behaviour per test, no delays, no hidden dependencies, no dependence on test order. Name it by behaviour: `'emits [Loading, Loaded] when fetch succeeds'`.

## Files in this folder

| File | Topic |
|---|---|
| `02-abstraction-and-injection.md` | Abstract interfaces, constructor injection, where to draw the seam |
| `03-test-doubles-and-layers.md` | Fakes vs mocks vs stubs, and how each layer is tested |
| `04-sources-and-gaps.md` | Sources, what is and isn't verified, open decisions |
