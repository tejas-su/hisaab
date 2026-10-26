# Sources, limits and open decisions

## Sources used

- Flutter docs, testing overview: https://docs.flutter.dev/testing/overview
- Flutter docs, architecture case study, testing: https://docs.flutter.dev/app-architecture/case-study/testing
- Very Good Ventures, "Flutter testing: a very good guide": https://www.verygood.ventures/blog/guide-to-flutter-testing
- bloclibrary.dev, testing: https://bloclibrary.dev/testing/
- Andrea Bizzotto, abstract classes and DI for tests: https://codewithandrea.com/articles/testing-flutter-apps
- Yczar, "TDD in Dart": https://github.com/Yczar/test-driven-dart/blob/master/6_Special_Topics/6.1_TDD_in_Dart.md

## Limits

- Web search results were uneven; blog and skill-directory pages were used only where an official or well-known source backed the same point.
- The Andrea Bizzotto example is old (pre-null-safety); the pattern is current, the syntax is not.
- Pyramid proportions are guidance, not measured numbers.
- The Dart team's own testing documentation was not read in depth.

## Open decisions for the team

| Question | Current state |
|---|---|
| Add `mocktail` for interaction checks and external mocks? | Not installed; ask first |
| Add `bloc_test` for `blocTest`? | Not installed; hand-written `expectLater` pattern used |
| Strict test-first for every change, or test-first for logic only? | Rules require tests in the same change; test-first is the default for logic (use cases, cubits, mappers) |
| Wire `scripts/changed_lines_coverage.sh` into CI or a pre-push hook? | Local check only |
