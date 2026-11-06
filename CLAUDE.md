# CLAUDE.md

**hisaab•** is an Android-only Flutter expense tracker and budgeting app for Indian users (INR). It answers one question: *how much can I safely spend today?* The user enters recurring income once. Every expense drains today's share. The **Ask AI** screen exports a ready-made prompt to ChatGPT or any other AI.

The bar is "a 5-year-old can use it". Every decision trades features for simplicity.

Rules and skills are adapted from the team's `melento-nocode-flutter` setup. When a convention changes in one, consider the other.

## Read first

| Doc | What it decides |
|---|---|
| [docs/SPEC.md](docs/SPEC.md) | **Behaviour, exactly:** business rules with formulas and worked examples (BR-), screen requirements with acceptance criteria (FR-), edge cases, NFRs. Tests cite these IDs |
| [docs/UI_DESIGN.md](docs/UI_DESIGN.md) | Design spec: Day Blocks concept, tokens, type, screens, motion, haptics, copy, accessibility, with research sources |
| [docs/design/](docs/design/README.md) | HTML mockups matching the spec's worked example |
| [docs/design-research/](docs/design-research/README.md) | UX/UI case studies, principles learned from other apps, and research sources. Add to it when researching a design |
| [docs/PLAN.md](docs/PLAN.md) | Product scope, the zero-config defaults (§2), data model, architecture, milestones M0–M6 |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Decision log; append a row when a decision changes |

Before building or changing anything, read its BR/FR entries in `SPEC.md` and its section in `UI_DESIGN.md`. When docs disagree, SPEC › UI_DESIGN › mockups › PLAN. If a change departs from them, say so and update the doc in the same change.

## Working approach

- **Think before coding:** state assumptions explicitly. If there are several interpretations, present them. If something is unclear, stop and ask. If a simpler approach exists, say so.
- **Simplicity first:** add nothing beyond what was asked. No abstractions for single-use code, no unrequested configurability, and no error handling for impossible scenarios. For the product itself, choose a sensible default rather than add a user-facing setting (PLAN §2).
- **Surgical changes:** don't "improve" adjacent code, comments or formatting, and don't refactor what isn't broken. Mention unrelated dead code instead of deleting it. Every changed line should trace back to the request.
- **Goal-driven execution:** for multi-step tasks, state a brief plan first:
  ```
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
  ```

## Stack and commands

- Flutter 3.47 / Dart ^3.13, Android only. The other platform folders exist but are not built or tested.
- Packages:

  | Package | Use |
  |---|---|
  | `flutter_bloc` | State management: Bloc with sealed events everywhere, no Cubits |
  | `bloc_concurrency` | Event transformers: `restartable()` for loads, `droppable()` for saves |
  | `get_it` | DI, used only at the composition root |
  | `equatable` | Value equality |
  | `sqflite` | Local database |
  | `intl` + `flutter_localizations` | Formatting and l10n, via gen-l10n |
  | `hugeicons` | Icons |
  | `fpdart` | `Either` / `TaskEither` errors |
  | `file_picker` | The system *Save to* and open screens for backup and restore, used only in `lib/backup/data/platform/` (D139) |
  | Bundled fonts | Anek Latin and Mukta in `assets/fonts/`, with OFL licences |

- `path` is also installed. Planned later: `animations`, `fl_chart`, `share_plus`, `url_launcher`. **Ask before adding any dependency not listed in PLAN §11.**
- Commands:

  | Command | Purpose |
  |---|---|
  | `flutter pub get` | Install packages |
  | `flutter gen-l10n` | Regenerate strings after editing `lib/l10n/app_en.arb` |
  | `flutter analyze` | Lint (team lint set in `analysis_options.yaml`) |
  | `flutter test` | Run tests |
  | `flutter run -d <device>` | Run the app |

- The git repo is **local only**. Never add a remote and never push. Commit only when asked.

## Architecture

The architecture is feature-first clean architecture (full tree in PLAN §9):

- `lib/core/`: `db`, `design`, `di`, `errors`, `logging`, `money`, `time`, `usecases`, `widgets`.
- `lib/ledger/`: shared money data (transactions, categories, recurring). Other features import it only through `ledger.dart`.
- `lib/{onboarding,home,add_entry,spends,ask_ai,settings}/`: screens, as `presentation/` plus `domain/` where the feature owns logic.
- `lib/app/`: app shell and `routes.dart`. `lib/l10n/`: ARB files and generated code.

## Non-negotiables

These are app-specific, and the rules files carry the details.

- **Money:**
  - Amounts are `int` paise in a `Money` object, never `double`.
  - Display amounts only through `MoneyFormatter` with `en_IN` (`₹1,25,000`, `₹1.25L`).
  - Never show paise.
- **Time:** "today" comes from the injected `Clock`. All cycle and payday math lives in `PeriodCalculator`.
- **Strings:** all user-facing text lives in `lib/l10n/app_en.arb`. Never write a literal string in a widget. Banned words: "transaction", "debit/credit", "budget period", "Oops".
- **Design tokens only:**
  - Colours come from `HisaabColors` and type from the theme `TextTheme`. Fonts are Anek Latin for amounts and Mukta for body text, with tabular figures on amounts.
  - Motion uses the spring tokens and respects reduced motion. Haptics go through the `Haptics` wrapper.
  - Never use `Color(0xFF…)`, `Colors.*` or `Icons.*` in a widget.
- **One signal colour:** marigold `#FFB020` means *today / act* only. It is never placed bare on the light background.
- **No red, no green, no category colours.** State is shown by fill, outline, hatch and words.
- **Icons:** Hugeicons only, through `AppIcon`, always with a label. A glyph the free set lacks is drawn in Hugeicons' format in `HisaabGlyphs` (`lib/core/design/hisaab_glyphs.dart`), reusing an original's corner curves (D48).
- **Adaptive layout:** never lock orientation or assume a portrait phone. Read `context.layout` (`lib/core/layout/`), never raw `MediaQuery` widths. Nothing straddles a fold. New screens are tested at the `TestWindows` sizes (UI_DESIGN §13).
- **Entry speed:** the Add flow is Add → digits → Next → tile. Never add a tap or a field to it, and never reorder categories, the keypad or the dock. The one control off that path is the *New* tile after the categories (D138); it moves nothing.
- **Privacy:** no network access, no analytics. Never log notes or amounts with personal text. The only data that leaves the device is the Ask AI export the user triggers and previews.

## Where the detailed guidance lives

**Rules** (`.claude/rules/`) load automatically when you work on files that match their `paths:`:

| File | Covers | Applies to |
|---|---|---|
| [dart-core.md](.claude/rules/dart-core.md) | Architecture, core layer, naming, function design, money/date/locale rules, null and type safety, DI with get_it, exports, enums, keys, hygiene, logging | `lib/**/*.dart`, `test/**/*.dart` |
| [bloc.md](.claude/rules/bloc.md) | Bloc everywhere, event naming, sealed states and events, concurrency transformers, async, streams, tracing | `bloc/`, `*_bloc.dart`, `*_event.dart` |
| [data-domain.md](.claude/rules/data-domain.md) | Entities and models, equality, money and dates in the domain, use cases, fpdart errors, mappers, repositories, sqflite data sources, migrations | `data/`, `domain/`, `core/db`, `core/money`, `core/time` |
| [presentation.md](.claude/rules/presentation.md) | Widget structure, navigation, Bloc usage, performance, the design-system rules, focus | `presentation/`, `core/widgets`, `core/design`, `app/` |
| [accessibility.md](.claude/rules/accessibility.md) | Semantics, tap targets, contrast, Hisaab conventions (spoken amounts, hero sentence, DayBlocks), a11y tests | widget files |
| [code-docs.md](.claude/rules/code-docs.md) | Dartdoc on public APIs, what to document per kind, `// why:` comments, TODO/deprecation format | `lib/**/*.dart`, `test/**/*.dart` |
| [tests.md](.claude/rules/tests.md) | When to test, TDD, layout, fakes (no mocking library), date and money edge cases, Bloc and widget patterns, coverage gate | `test/**`, `integration_test/**` |
| [feature-docs.md](.claude/rules/feature-docs.md) | Feature docs location, numbering, style, keeping PLAN/UI_DESIGN in sync | `docs/**/*.md` |

**Skills** (`.claude/skills/`) load on demand, or you can run them with `/<name>`:

| Skill | Use when |
|---|---|
| [new-feature](.claude/skills/new-feature/SKILL.md) | Scaffolding a feature in the clean-architecture layout, with tests |
| [debug-flutter](.claude/skills/debug-flutter/SKILL.md) | Crashes, wrong amounts or dates, duplicate recurring entries, jank, leaks, rebuild thrashing |
| [live-app-inspection](.claude/skills/live-app-inspection/SKILL.md) | Inspecting or driving the running app (Dart MCP, hot reload, adb, screenshots) |
| [document-code](.claude/skills/document-code/SKILL.md) | Adding or reviewing docs across a file or folder (applies `code-docs.md`) |
| [document-feature](.claude/skills/document-feature/SKILL.md) | Writing or updating `docs/features/<feature-name>/` |
| [generate-tests-csv](.claude/skills/generate-tests-csv/SKILL.md) | Generating an FE/BE test-case CSV for a feature |
| [better-colors](.claude/skills/better-colors/SKILL.md) | Any colour or token change: ramps with step jobs, measured OKLCH and contrast (third-party, jakubkrehel/skills; case study 08) |

**Design agents** (`.claude/agents/`) are subagents, one per design discipline. Start with `design-product`; it routes to the others:

| Agent | Discipline |
|---|---|
| [design-product](.claude/agents/design-product.md) | Product design: problem framing, end-to-end journeys, feature scope, routing |
| [design-ux-research](.claude/agents/design-ux-research.md) | UX research: competitive and desk research, usability tests, synthesis into `docs/design-research/` |
| [design-ux](.claude/agents/design-ux.md) | UX design: flows, task flows, wireframes, error prevention, recovery |
| [design-ia](.claude/agents/design-ia.md) | Information architecture: navigation, hierarchy, taxonomy, labels |
| [design-interaction](.claude/agents/design-interaction.md) | Interaction design: patterns, states, gestures, micro-interactions, input |
| [design-ui](.claude/agents/design-ui.md) | UI design: hierarchy, layout, spacing, colour and type use, hi-fi mockups |
| [design-system](.claude/agents/design-system.md) | Design system: tokens, themes, shared components, governance |
| [design-brand](.claude/agents/design-brand.md) | Brand: identity, app icon, splash, glyphs, Play Store visuals |
| [design-motion](.claude/agents/design-motion.md) | Motion: springs, transitions, choreography, reduced motion |
| [design-content](.claude/agents/design-content.md) | Content design and UX writing: ARB copy, voice, errors, empty states |
| [design-accessibility](.claude/agents/design-accessibility.md) | Accessibility: WCAG 2.2 AA, TalkBack, contrast, targets, cognitive load |
| [design-validation](.claude/agents/design-validation.md) | Prototyping and validation: mockups, test plans, design QA against the build |
| [design-platform](.claude/agents/design-platform.md) | Android and adaptive design: window classes, foldables, insets, predictive back |
| [design-ops](.claude/agents/design-ops.md) | DesignOps: doc sync, quality audits, handoff, process improvement |

## Testing

Read [tests.md](.claude/rules/tests.md) before writing or changing any test.

- **Coverage:** new or changed code is covered in the same change. The hard floor is **≥ 90% of changed lines** and the target is 100%. List every uncovered line with a reason, and don't use `// coverage:ignore`. Check with `scripts/changed_lines_coverage.sh [base-ref]`.
- **TDD for logic:** use cases, `PeriodCalculator`, `SafeToSpend`, the recurring engine, `PromptBuilder`, mappers and Blocs are written test-first. A bug fix starts with a failing regression test.
- **Dates and money get edge cases:** payday on the 29th–31st, leap years, year-crossing cycles, zero days left, ₹0, the 9-digit cap, overspend larger than the remaining total, and a recurring catch-up posted exactly once. Pin "today" with `FakeClock`.
- **Test doubles:** hand-written fakes by default. `sqflite_common_ffi` runs real SQLite in tests. Ask before adding `mocktail` or `bloc_test`.
- **Existing tests are the contract:** change the code, not the test. If a test looks wrong, stop and ask.
- **Layout:** `test/` mirrors `lib/`. Shared fakes and fixtures go in `test/helpers/`.
- **Done means:** tests pass, the coverage script passes (or gaps are reported), and `flutter analyze` is clean.

## Documentation

- Product decisions live in `docs/PLAN.md` and `docs/UI_DESIGN.md`. Keep them in sync with the code.
- Feature docs live in `docs/features/<feature-name>/` with numbered files starting at `01-architecture-overview.md` (see [feature-docs.md](.claude/rules/feature-docs.md)). `docs/features/tdd-in-flutter/` is background reading for the testing rules.
