# Habits: ideation log

Record of the brainstorm on 2026-10-26: the starting idea, approaches weighed, what changed and why. Status per item: **Agreed** (the user said yes), **Decided** (the user delegated it), **Proposed** (awaiting the user's review).

## 1. Starting idea

The user: "I go to breakfast every day between 9 and 10:30, so at that time the app can show the amount I usually use, say ₹55 for food. Instead of +10 / +50 / +100 on the Add page it could adapt to my usage. More micro-UX like this so entry is smooth and efficient."

## 2. Timeline

| # | Step | Outcome | Status |
|---|---|---|---|
| 1 | First helper list: usual chip, category hint, missed-log nudge, bill detection, today forecast, note autocomplete | User wants all of them, phased | Agreed |
| 2 | No LLM; algorithmic, decoupled, FSM-like | Approach A (below) | Agreed |
| 3 | Use SQL for what it is good at | SQL groups rows; Dart does the maths | Agreed |
| 4 | Research big-fintech engagement and dark patterns | Habit loops on *logging*, never on spending; CCPA 2023 line (`06-research-and-guardrails.md`) | Agreed |
| 5 | North-star metric | Days logged per pay cycle | Decided |
| 6 | Stance on nudging | No nagging; the only push is toward spending less and saving; UX is the goal | Agreed |
| 7 | Plain-language HTML overview | Draft v1, then v2 after reviews | Agreed for v1 |
| 8 | Content-writer and UX-critic reviews | Five helpers cut to three; copy rewritten; Home slot model; stricter bars | Proposed |
| 9 | Custom categories (cigarettes, alcohol, partying) | Tracked items inside a category, two-tap entry via the pill | Proposed |
| 10 | User: "the design looks good"; wants tracked items as tiles like Food or Travel, expressed differently | Chip row replaced by a tile row under the grid | Proposed |
| 11 | User: tracked tiles must not stand out, only hint subtly | Same `CategoryTile` in a third grid row (4 slots); hint is a 12dp parent-category mark (A) or "in {category}" caption (B) | Superseded by 12 |
| 12 | Critique of A and B; user picks C ("even I thought like this") | No mark on the tile; a 16dp gap groups the third row; "in Fun" shown in Spends, Settings and TalkBack; habit-pull prompt for untagged look-alikes | Agreed |
| 13 | Research pass and mockups (2026-11-13; case study 32, mockup 40) | Kept the thresholds; added a pooled weekday/weekend fallback, *Your usual* with *Forget* in the category sheet, the pill from the app shortcut and QS tile; tracked items overtaken by D138; ship the pill first | Proposed |
| 14 | Owner: layout B for the slot, the pill on the Add screen, and change the CLAUDE.md rule | D153; SPEC BR-17, FR-AD-10, FR-SE-2 AC-6, E58–E65; UI_DESIGN §5.3; CLAUDE.md entry-speed exception | Agreed |

## 3. Approaches weighed

**Engine**

| Option | Summary | Verdict |
|---|---|---|
| A | Shared immutable `HabitIndex` rebuilt from entries; independent pure detectors; FSMs only for lifecycle | **Chosen.** Edits, deletes and restore can never leave stale stats |
| B | Online counters updated on each save | Rejected: edit/delete/restore must un-count correctly; migration burden |
| C | One rules engine or global FSM | Rejected: couples every helper |

**Custom categories** (`05-tracked-items.md`)

| Option | Summary | Verdict |
|---|---|---|
| A | Tracked items inside a category, third grid row of normal tiles with a subtle category mark in step 2, learned by the pill | **Proposed** (first drafted as a chip row above the grid; changed to tiles at the user's request) |
| B | Real extra categories | Rejected: grid grows past 2×4, breaks BR-11 and principle 5 |
| C | Rename a tile (FR-SE-2, exists today) | Kept as-is, but costs one of the 8 tiles |

## 4. Deviations from the first draft

| First draft | Now | Why |
|---|---|---|
| Five helpers | Three: usual, missed-log, bill finder | Reviews |
| "Usually about ₹180 more today" on Home | **Cut** | Second number about today breaks principle 1; anchors spending upward; duplicates BR-7 |
| Outline on the likely category tile | **Deferred** | Saves zero taps (tiles never move); reads as "selected"; anchors wrong choices |
| Note autocomplete | Deferred | Not needed for fewer taps |
| "Existing data works from day one" | **Wrong.** Fix `replace`/`restore` first; learn only from same-day, non-recurring entries | `created_at` is re-stamped on edit and restore; it records logging time, not spending time |
| Usual pill in the ~20dp preview line | Preview line becomes a fixed 48dp slot for everyone | NFR-4 touch target; no layout shift |
| Pill tap "same Undo as a normal save" | New 6 s Undo snackbar for one-tap add only | Normal saves have no Undo; only delete does (BR-10) |
| Amount bar 50% | ≥ 70% on one exact amount and ≥ 5 hits | Up to half of one-tap saves would be wrong |
| Show from first use | Silent until ≥ 14 days since first entry and ≥ 10 active days | "3 of 3" on day 4 fires falsely |
| Separate notes on Home | One note line with fixed priority | Over card, due-soon and the new card would stack |
| "Did you forget?" / "Hide" | "Spent on Food today?" / "Not today" | Guilt copy; a question lets "no" be a good answer |
| "Save" as the action word | "Add" | "Saved" means money kept in Hisaab |
| "Usual now · Food ₹55" | "Food ₹55 · your usual" | "Now" implies a timer |
| Bill finder creates the rule | Opens the Settings bill flow prefilled; user confirms the day | Nothing silent; avoids double-posting |
| Hide twice → 30 days | Two "Not today" within 14 days → rest 30 days; one hide clears only today | Two honest Sundays shouldn't mute a habit |
| One pooled time profile | Weekday and weekend profiles | Weekend false positives |

## 5. Spec changes this will need (on approval)

- SPEC: new BR for habit learning; FR-AD-1 (usual pill, 48dp slot), FR-AD-5 (one-tap add path), BR-10 (Undo after one-tap add), FR-HO-3/FR-HO-5 (one Home note line with priority), BR-14 (bill finder and tracked-item insights), BR-11 (tracked items), FR-SE-2 (Things to track), BR-15 (hide tracked names with notes), BR-16 (backup includes tracked items).
- UI_DESIGN: §5.2, §5.3, §5.4, §8 Voice additions.
- DECISIONS: rows for the engine choice, north-star, one-tap add, Home note priority, the cuts, tracked items.

## 6. Open questions

1. Undo after every save, or only after one-tap add? **Proposed:** one-tap add only.
2. Tracked items capped at 4? **Proposed:** yes, one full grid row.
3. CSV export: add a `tracked` column, or fold the name into `note`? Not yet discussed.
4. Android launcher shortcuts ("Cigarettes ₹20" from the app icon) need `quick_actions`, a new dependency. Parked; ask before adding.
5. Gamification (streaks etc.) is a separate session.
