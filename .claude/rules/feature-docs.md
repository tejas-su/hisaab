---
paths:
  - "docs/**/*.md"
---

# Feature documentation (`docs/`)

Feature-level knowledge (architecture, flows, behaviour, risks) lives in markdown under `docs/`. Code-level docs (dartdoc, `// why:` comments) stay in the Dart files; see `.claude/rules/code-docs.md`.

## Location

```
docs/
└── features/
    ├── add-entry/
    │   ├── 01-architecture-overview.md
    │   ├── 02-save-flow.md
    │   └── ...
    ├── tdd-in-flutter/        ← background reading for .claude/rules/tests.md
    └── <feature-name>/
        ├── 01-architecture-overview.md
        └── 02-<topic>.md
```

- One folder per feature: `docs/features/<feature-name>/`
- `<feature-name>` is kebab-case and names the feature, not a class (`add-entry`, `ask-ai`, `ledger`). If the feature has its own `lib/` folder, use the same name in kebab-case (`lib/add_entry` → `add-entry`)
- A sub-feature gets its own folder under `docs/features/` (e.g. `recurring-engine`, even though its code sits in `lib/ledger/`). Don't nest feature folders
- Never write new feature docs at the `docs/` root, inside `lib/`, or next to the code

## Files inside a feature folder

- Name files `NN-kebab-case-topic.md` with a two-digit prefix: `01-`, `02-`, …
- `01-architecture-overview.md` always comes first. It's the entry point for the feature (see the `document-feature` skill for its sections)
- One topic per file: a flow, a behaviour, a mapping, a decision. Split any file that grows past ~150 lines
- When adding a topic, use the next free number. Never renumber existing files, because links and people rely on the names
- Typical sequence: `01-architecture-overview`, `02-…-flow` (one per user flow), then behaviour/mapping files, and finally `NN-risks-and-refactor-options`

## Writing style

- Start with an `# H1` title naming the topic
- Name real files as backticked repo-relative paths (`lib/add_entry/presentation/bloc/add_entry_bloc.dart`) and real class/method names. Read the source first; never guess names
- Describe flows as numbered steps; use tables for mappings (class → layer → responsibility)
- Keep it to 1–2 sentences per item, no padding. State what the code does today; mark planned or uncertain behaviour explicitly
- When a doc was written from a branch diff, add a short "Source scope" list naming the files it covers

## Keeping docs in sync

- Before changing a feature, check `docs/features/<feature-name>/` and read the relevant files
- If your change alters documented behaviour, update the matching doc in the same change. If no doc exists yet, mention it rather than creating one unasked
- Product-level docs stay at the `docs/` root:
  - `docs/SPEC.md`: behaviour, with BR/FR/NFR IDs. Tests cite these IDs.
  - `docs/UI_DESIGN.md`: design spec.
  - `docs/PLAN.md`: build plan.
  - `docs/DECISIONS.md`: decision log; append rows, never rewrite them.
  - `docs/design/`: HTML mockups.
  - When a change alters something recorded there (a rule, a token, a screen, a milestone), update that doc in the same change. When docs disagree, SPEC › UI_DESIGN › mockups › PLAN
