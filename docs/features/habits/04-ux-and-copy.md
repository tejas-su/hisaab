# Habits: UX and copy

> **Status: proposed** (content-writer and UX-critic review merged). Awaiting the user's review.

## Principles for every helper

1. **Nothing moves.** No reordering, no layout shift, no pop-in while a screen is visible.
2. **Silent when unsure.** Warm-up plus strict bars (`03-detection-maths.md`).
3. **One voice per screen.** One slot each on Home, Add step 1 and Spends.
4. **Ignoring is free.** No guilt copy, no urgency, no notifications.
5. **Nudge toward saving, never toward spending.**
6. **No marigold** anywhere in this feature; it stays "today / act" (UI_DESIGN §2).

## Slots and priority

**Home: one note line** under the hero (where `DueSoonNote` sits today in `lib/home/presentation/pages/home_page.dart`). Top item wins:

| Priority | Item | Source |
|---|---|---|
| 1 | Over today's share | FR-HO-5 |
| 2 | Bill due soon | FR-HO-3, BR-9 |
| 3 | "You saved ₹X yesterday" | BR-8 |
| 4 | Missed-log question | this feature |

Chosen on load or resume only; an item leaves only through the user acting (tap, ×, save, Undo). This is a SPEC change: today due-soon and the over card may stack.

**Add step 1: the preview line** (`SpendPreviewLine`, `lib/add_entry/presentation/widgets/spend_preview_line.dart`) becomes a fixed 48dp slot for everyone. At ₹0 it can hold the pill; once there is an amount it shows the FR-AD-3 preview as today. Keep ≥ 12dp clear above the quick chips.

**Add step 2:** the 8 tiles untouched. A tracked-item tile row sits under the grid (`05-tracked-items.md`).

**Spends: the insights list** (BR-14). Bill finder and tracked-item candidate join as insights within the 3-insight cap. In two-pane layouts they wait while Home's note is visible.

## Your usual (Add step 1)

- **Shows only** on Spent, new entry (not FR-AD-8 edit mode), amount ₹0, before any input, when the date is today. Never in a tray opened from `NoIncomeCard`.
- **First frame or never:** read from the cached result; never appears late.
- **Disappears** on the first digit, chip, ⌫ or kind switch; does not return until the tray reopens.
- **Look:** fully rounded pill, hairline `ink2` outline on `surface`, no fill; category Hugeicon 18dp, amount in Anek with tabular figures, "· your usual" in `ink2`. At large text drop "· your usual"; if it still doesn't fit one line, show nothing.
- **Tap:** adds at once. Pill flashes ink 120ms, tray drops, block drains, number rolls, `successNotification`. Snackbar "Added ₹55 to Food" with Undo for 4 s (kept until dismissed under TalkBack). Undo also quiets the habit for the day.
- **Motion:** 150ms crossfade to the preview text, no height change; same under reduced motion.
- **Home hand-off:** tapping the missed-log question opens the tray carrying that habit, and the pill shows it regardless of the time window.

## Missed-log question (Home)

- Same container as `DueSoonNote`; category icon; 48dp × on the trailing edge.
- At most once a day; ≥ 90 min after the window; never while a higher-priority note qualifies.
- Tap: opens Add with the habit carried (tick haptic). ×: fades and collapses with the `standard` spring (tick haptic); crossfade under reduced motion.
- One merged TalkBack node; × is a separate node.

## Bill finder (Spends insight)

- One action, *Make it a fixed bill*, and a text button, *Not a bill*.
- The action opens the Settings bill flow (FR-SE-1) prefilled with name, amount and day; the user confirms by tapping the day. D33 applies; a month already logged is skipped.
- After acceptance the row collapses with `standard` and `successNotification`; that pattern stops feeding the usual pill and the Home question.

## Every string (ARB keys proposed)

| Key | Shown | TalkBack |
|---|---|---|
| `usualSuggestion` | `{category} {amount} · your usual` | `usualSuggestionSpoken`: "Add {category}, {spokenAmount}, your usual" |
| `usualAdded` | `Added {amount} to {category}` + existing `undo` | "Added {spokenAmount} to {category}" |
| `missedLogTitle` | `Spent on {category} today?` | merged with body + "double-tap to add" |
| `missedLogBody` | `Usually around {time}.` | |
| `notToday` | × | "Not today" |
| `billFinderTitle` | `{name} {amount} every month, around day {day}` | same |
| `billFinderAction` | `Make it a fixed bill` | "Make {name} a fixed bill" |
| `billFinderDismiss` | `Not a bill` | "Not a bill, don't ask again" |

`{time}` comes from `DateFormat.j` with `en_IN` ("1 pm"). Days are "day {day}" as in the existing `billDetail` / `billEveryMonth`; no ordinals.

## Voice rules for this feature

1. Describe the person's habit, not the app watching: "usually", "your usual"; never "we noticed", "learned", "based on", "smart", "AI".
2. Hedge every guess with "usually" or "around". A guess is never a command and never an amount to spend.
3. The action word is **Add**. "Saved" stays reserved for money kept.
4. Ask only when "no" is a good answer. × and *Not a bill* stay silent: no confirmation, no guilt.
5. Write so any category name and any language fits: `{category}` at the start or after a preposition; no ordinals; no idioms.
6. No name for the feature in the UI: no "Smart", no "Suggestions" heading, no "why am I seeing this".
