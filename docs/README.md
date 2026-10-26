# hisaab• docs

Start with the spec, then the design, then the plan.

| Doc | Read it for |
|---|---|
| [SPEC.md](SPEC.md) | **What the app does, exactly.** Business rules with formulas and worked examples (BR-), screen requirements with acceptance criteria (FR-), edge cases, non-functional requirements, open questions |
| [UI_DESIGN.md](UI_DESIGN.md) | **How it looks and feels.** Concept, tokens, type, screens, motion, haptics, voice, accessibility, research sources |
| [design/](design/README.md) | **Mockups.** Static HTML screens that match the spec's worked example |
| [PLAN.md](PLAN.md) | **How it gets built.** Scope, zero-config defaults, data model, architecture, milestones M0–M6 |
| [DECISIONS.md](DECISIONS.md) | **Why things are the way they are.** The decision log |
| [features/](features/) | **Per-feature architecture**, one folder each (`01-architecture-overview.md` first). They are marked *planned* until the code lands |
| [features/tdd-in-flutter/](features/tdd-in-flutter/) | Background for the testing rules in `.claude/rules/tests.md` |

**Precedence when docs disagree:** SPEC (behaviour) › UI_DESIGN (look and interaction) › mockups › PLAN. Fix the loser in the same change.

**Conventions:** see [`.claude/rules/feature-docs.md`](../.claude/rules/feature-docs.md). Product-level docs live at this root; feature docs go in `features/<feature-name>/` with numbered files.
