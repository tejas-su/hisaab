---
name: document-feature
description: Write or update feature-level docs in docs/features/<feature-name>/ (numbered markdown files starting with 01-architecture-overview.md covering purpose, entry point, data flow, key classes, states, failures, dependencies). Use when the user asks to document, explain, or write up how a feature works end-to-end.
argument-hint: "Feature folder name (e.g. add_entry, ledger)"
---

Generate a feature-level architecture document for: **$ARGUMENTS**

A developer should be able to read it in under 5 minutes and understand how the feature works end-to-end.

## Where the output goes

Follow `.claude/rules/feature-docs.md`:

1. Work out the kebab-case `<feature-name>` (e.g. `lib/add_entry` → `add-entry`)
2. Check whether `docs/features/<feature-name>/` exists and read what's already there
3. **New feature folder:** create `docs/features/<feature-name>/01-architecture-overview.md` with the sections below. If a specific flow or behaviour needs more than a few lines, put it in its own `02-<topic>.md`, `03-<topic>.md`, … and link to it from the overview
4. **Existing folder:** update the file that covers the topic. Add new topics as the next free `NN-<topic>.md` and never renumber. Don't overwrite the existing overview wholesale; merge your changes into it
5. Afterwards, list every file created or changed

If the user asks only for text (e.g. for a PR description), give it in the reply and skip writing the file.

## Sections of `01-architecture-overview.md`

### 1. Purpose
One paragraph — what the feature does for the user and what business problem it solves.

### 2. Entry point
The starting file/widget and how it is reached (route in `lib/app/routes.dart`, the dock, the Add key, an app shortcut, etc.).

### 3. Data flow
A text diagram, with each arrow annotated with the real class or method name:

```
User Action
  → Bloc event
    → Use Case
      → Repository
        → Local Data Source (sqflite)
          → Model (row)
            → Mapper
              → Entity
                → Bloc state
                  → UI rebuild
```

If a feature skips layers, draw the flow as it actually is. For updates pushed after a save, include the repository change stream → bloc reload event path.

### 4. Key classes

| Class | Layer | Responsibility |
|-------|-------|----------------|
| `FeatureNamePage` | presentation | entry widget, wires Bloc |
| `FeatureNameBloc` | presentation/bloc | state management via events |
| `GetFeatureUseCase` | domain | orchestrates the fetch |
| `FeatureRepository` | domain | contract |
| `FeatureRepositoryImpl` | data | implementation |
| `FeatureMapper` | data | model ↔ entity |
| `FeatureModel` | data | database row DTO |
| `FeatureEntity` | domain | immutable domain object |

Fill in the real class names and add any extra feature-specific classes.

### 5. State variants
All state classes and the UI state each maps to.

### 6. Failure types
All `Failure` subclasses (or error states) the feature can produce, and what causes each.

### 7. External dependencies
Other features (usually `ledger`), core services (`MoneyFormatter`, `PeriodCalculator`, `Clock`), packages, and platform integrations (clipboard, share sheet, `url_launcher`).

### 8. Design spec
The `docs/UI_DESIGN.md` sections the feature implements, and any deliberate deviation from them.

### 9. Known limitations / TODOs
Known gaps, temporary workarounds, or future work noted in the code.

## Rules
- Read the actual source files first — never guess class names
- 1–2 sentences per item; no padding
- Name real files as backticked repo-relative paths
- Start the file with an `# <Feature name> Architecture Overview` title
- Clean markdown only; no HTML
