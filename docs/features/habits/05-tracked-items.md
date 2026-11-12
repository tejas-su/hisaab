# Habits: tracked items

> **Status: superseded by D138 (your own categories); dropped by D153.** Kept as a record. Answered the user's request for custom categories (cigarettes, alcohol, partying) without adding taps.

## Problem

Each user has something personal to watch. BR-11 fixes the categories at 8 tiles in a 2×4 grid that never scrolls or reorders, and principle 3 ("Never add a tap") rules out a sub-category step. Most users will not write notes.

## Approach

A **tracked item** is a name plus an icon that lives **inside** an existing category. "Cigarettes" inside Fun still counts toward Fun, so category totals, charts and limits stay correct.

## Tap budget

| Entry | Taps |
|---|---|
| Any spend today | Add → digits → Next → tile |
| Tracked item, typed amount | Add → digits → Next → **item tile** (same count; one more tile to pick from, not a second step) |
| Tracked item, usual amount | Add → **"Cigarettes ₹20 · your usual"** pill (2 taps) |

Fixed-price, frequent spends (cigarettes, chai, drinks) are the fastest habits for the pill to learn, so the things users most want to watch become the cheapest to log.

## Where they appear

- **Add step 2: a third grid row.** Four fixed slots in the same 4-column grid, filled left to right; an empty slot stays blank (as `_tile` already does past the list end in `lib/add_entry/presentation/widgets/category_step.dart`), so adding an item never moves another. The row appears once the first item exists. The 8 category tiles never move. Tapping a tracked tile saves exactly like a category tile (FR-AD-5).
  - **Blends in:** the same `CategoryTile` (`lib/core/widgets/category_tile.dart`): `sunk` fill, 96dp, radius 22, Hugeicon plus word, same flash and haptics.
  - **The layout is the hint (agreed, option C):** no mark or caption on the tile. The third row sits 16dp below the grid instead of the usual 10dp gap, so proximity groups it as "yours". The parent category is shown where it is used: Spends ("Fun ₹2,100 · includes Cigarettes ₹1,240"), Settings › Things to track ("Cigarettes · in Fun") and TalkBack.
  - **Rejected hints:** (A) a 12dp parent-category icon in the corner breaks principle 7 (icon without a word), is unreadable at that size, and reads as a notification badge; (B) an "in {category}" caption overflows 96dp at 1.5× text, repeats when several items share a category, and adds reading to every entry for information needed only in Spends.
  - **Bottom placement:** closest to the thumb, and the grid above never shifts.
  - **Height:** three rows (~310dp) stay shorter than step 1's keypad screen, so the tray should not grow past its current height; verify on the short `TestWindows` sizes at 1.5× text.
  - **TalkBack:** "{item}, in {category}. Save", after the 8 tiles in focus order.
  - **Considered:** outlined 64dp tiles in a 3-slot row (user: stands out too much); a chip row above the grid (shifts the grid down once and reads as secondary).
- **Add step 1:** a tracked item can be the usual pill like any habit (habit key includes `tracked_item_id`, `03-detection-maths.md`).
- **Spends category row:** a parent category with tracked items shows "includes {item} {amount}" under its total, so the split is never a surprise.
- **Spends:** one card per item, facts only: "Cigarettes ₹1,240 this cycle · 62 times · about ₹15,000 a year at this pace". Yearly figure rounded and prefixed "about" as in BR-7. Never "quit", "too much" or judgement.

## How items get created

1. **From the pattern (no notes needed):** same category and same amount ≥ 6 times in 14 days → Spends insight "Fun ₹20, 9 times in 2 weeks. Give it a name?" One text field; the matching entries in that window get the name too. *Not now* follows FSM 2.
2. **From notes (fallback):** the same note text ≥ 5 times → the same question, name prefilled from the note.
3. **Manually:** Settings › Categories › *Things to track* › Add: name, then tap the tile it belongs to.

**Habit pull:** users may still tap the parent tile out of habit. When untagged entries in the parent category match an item's usual amount ≥ 3 times, Spends asks once: "3 Fun ₹20 entries look like Cigarettes. Add them?" Nothing is retagged silently; *Not now* follows FSM 2.

## Data (planned)

- New table `tracked_items(id, name, category_id, icon, active)`; at most 4 active.
- New nullable column `transactions.tracked_item_id` with an index; set by the tracked tile, the pill or the retro-tag on naming.
- Deleting an item deactivates it (like D35); past entries keep their link.
- Backup and restore include the table (BR-16).

## Privacy

- Item names never appear in logs (NFR-3).
- Ask AI's *Hide my notes* also hides item names (BR-15).
- Nothing outside the app shows them: no notifications, no widget text.

## Open questions

1. Cap at 4? Proposed yes: one full grid row, each tile as wide as the category tiles.
2. CSV export: separate `tracked` column, or fold into `note`?
3. Android launcher shortcuts for one-press entry need `quick_actions` (new dependency; ask first).
