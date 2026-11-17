# 38. Changing an entry that's already logged

**Outcome:** approved as D200 (2026-11-17): A2 + New, with the dock stepping aside and the landscape board (rounds 3b–3e). Built per SPEC FR-AD-8. Mockup [47-entry-edit.html](../../design/mockups/47-entry-edit.html).

## Job of the screen
Fix one thing about something already logged. Usually it's the amount (a typo, or the bill came to ₹20 more) or the category (logged under Food, but it was Travel). Less often it's the note or the day. The user knows what's wrong before they tap the row, and almost never changes everything.

## What's wrong today
Tapping a row reopens the Add tray, prefilled (FR-AD-8, BR-10). Editing replays adding:

| # | Problem | Where it comes from |
|---|---|---|
| 1 | **The category has to be picked again** even when it hasn't changed. Step 2 only saves on a tile tap, so a note-only or day-only change ends with re-tapping the same tile | `CategoryStep`: tile tap is the only save |
| 2 | **The grid doesn't show the current category.** The user has to remember it, and a wrong tap moves the entry without warning | `CategoryStep._tile` marks only the press flash |
| 3 | **Typing appends to the old amount.** On ₹250, typing "3" gives ₹2,503. The old amount must be cleared first (⌫ three times, or a long-press) | `AmountInput.append` on the prefilled rupees |
| 4 | **Every change starts on the keypad**, even when the amount is right: one extra *Next* for every non-amount fix | FR-AD-8 "opens step 1" |
| 5 | **Delete is hidden on step 2**, behind *Next* | `CategoryStep` |
| 6 | **No Undo after an edit.** An overwrite is the one change you can't see again, and the old values are gone | BR-10: a tray save has no Undo |
| 7 | **Nothing says it's an edit.** Step 1 looks exactly like Add | `AmountStep` |

Costs from the row, digits and typing excluded: amount 4 taps, category 3, note 4, day 5, delete 3.

The Add flow is right for **adding**. It's fast because a tile tap both answers and saves. But that same rule is what forces a re-confirm when editing. Case study 16 found the same thing for bills ("create in steps, change in place") and moved bill editing to a sheet (D118).

## Research
- **Create in steps, change in place.** Already gathered in case study 16: form tools use a wizard for new items and a single view for existing ones (Infowise). A Zoho user stuck editing through a wizard called it tedious. In PatternFly's small study, 6 of 7 preferred one form for repeated tasks.
- **Money apps open the whole record.** Wallet (BudgetBakers): selecting a record lets you edit every field of a manual record on one screen, including switching Expense/Income at the top ([Everything about transactions](https://support.budgetbakers.com/hc/en-us/articles/7149271363090-Everything-About-Transactions-Add-edit-clone-split-duplicates)). YNAB mobile: each field opens on its own, and the editor ends in *Save*. Its release notes show it cut friction from editing: the category list no longer opens the keyboard by itself, and "the editor now saves, regardless of where your cursor is" ([App Store notes](https://apps.apple.com/us/app/ynab/id1010865877)). Its newer floating bar categorises selected transactions without menus ([YNAB what's new](https://www.ynab.com/whats-new/a-simpler-way-to-approve-and-edit-transactions)).
- **Category as one row, "tap to change".** An open-source Indian SMS expense tracker replaced a sheet full of category chips with one row (icon, name, "Tap to change"), because the chips pushed the details out of view. TalkBack reads "Category, Food" with *change* as the action ([PR #177](https://github.com/bharathmay-boop/sms-expense-tracker/pull/177)). Another tracker gives the reason for having edit at all: typos in amount and category are the most common data errors in manual trackers ([issue #59](https://github.com/Sabin78910/expense-tracker-android/issues/59)).
- **On-screen keypads: the first key replaces.** AgOpenWeb's on-screen keypad opens with the value picked. The first digit replaces it; ⌫ as the first key keeps the value and removes one digit; Cancel restores it ([PR #517](https://github.com/AgOpenGPS-Official/AgOpenWeb/pull/517), [issue #491](https://github.com/AgOpenGPS-Official/AgOpenWeb/issues/491), which cites the original desktop app's "clear on first key"). The known pitfall is a selection that eats the next keystroke ([nimbalyst #1199](https://github.com/nimbalyst/nimbalyst/issues/1199)). An in-app keypad has no OS selection, so a "fresh" flag in the Bloc avoids it.
- **Save and discard.** Material: a form with an explicit *Save* needs a "discard changes?" confirmation when dismissed with changes, and none without changes ([M3 dialogs](https://m3.material.io/components/dialogs/guidelines), [M2 dialogs](https://m2.material.io/components/dialogs)). Bottom sheets suit a quick one- or two-field edit ([M2 bottom sheets](https://m2.material.io/components/sheets-bottom)). Designs that save each answer on its own avoid the prompt entirely (our bill sheet, D118).
- **Not found:** no public screen-level material from Indian trackers (Walnut, Money Manager, Spendee) on editing; no usability numbers for edit flows in money apps.

## Versions
Taps start from the entry row. Fewest per task in bold.

| Task | Today | V1 Patched tray | V2 Entry card | V3 One form | V4 Opens on category |
|---|---|---|---|---|---|
| Amount | 4 | **3** | **3** | 4 | **3** |
| Category | 3 | 3 | 3 | 3 | **2** |
| Note | 4 | 4 | **3** | **3** | **3** |
| Day | 5 | 5 | **3** | 4 | 4 |
| Delete | 3 | **2** | **2** | **2** | **2** |
| Re-confirm an unchanged answer | always | always | **never** | **never** | **never** |
| Discard prompt needed | no | no | **no** | yes | only if the note or day was changed and then Back |
| Build | none | **smallest** | new sheet, reuses step widgets | new sheet, compact grid | small: start on step 2, add a Save key |

### V1: patched tray (smallest change)
Keep the two steps. The first digit replaces the amount, the grid marks the current tile, and Delete moves to step 1. It removes the ₹2,503 trap (#3) and the guesswork (#2), but still makes the user re-tap the category (#1) and pass the keypad (#4).

### V2: entry card with Change rows (like the bill sheet, D118)
The row opens a card: the amount large, then rows *Amount*, *For*, *Day*, *Note*, then *Delete*. Each row swaps in that one question. The keypad's key reads *Save*, a tile tap saves, a day tap saves, and the note field has *Save*. The sheet closes after the save, and a snackbar offers Undo.
- For: matches bills, so one rule ("tap it, see it whole, change one thing") covers both. Never re-confirms. No discard prompt. Most reassuring: the entry is read before it's touched.
- Against: a new container to learn. Moving category is 3 taps, not 2. Two changes mean opening it twice (or returning to the card, which costs a close tap; the bill sheet returns to its summary).

### V3: one edit form
Everything on one sheet with one *Save*: the amount (tap for the keypad), a compact 4×2 grid with the current tile marked, day and note chips, Delete. This is the Wallet/YNAB pattern.
- For: the most familiar from other apps. Several changes can be made in one pass.
- Against: a tile *picks* here but *saves* in Add, so the same control behaves two ways. It needs a discard prompt (Material). The keypad and grid can't fit together, so the amount still swaps the sheet. The grid shrinks below Add's, and a landscape or large-text window is tight.

### V4: tray opens on the category step (recommended)
Same tray, same widgets as Add, but editing opens on step 2:
- The title shows the amount with an *Amount* chip. Tap either to slide in the keypad, with the old amount picked: the first digit replaces it and the key reads *Save*. Back returns to step 2 unchanged.
- The current tile has an ink outline and a tick. **Tapping another tile saves there**, the same gesture as Add, so moving category is 2 taps.
- The day and note chips are prefilled. A full-width marigold **Save** under them saves without re-picking the tile. A quiet **Delete** sits beside it.
- Spent/Got stays on the keypad step: changing the kind is rare, and the tiles change with it.

Why V4:
1. **Fastest for the two common fixes**: category in 2, amount in 3.
2. **No new container or rule.** A tile tap still means "save here", exactly as in Add, so nothing new to learn. The *Save* key only adds a way out that doesn't force a tile.
3. **Smallest build that fixes all seven problems.** It's a start step and a key on the existing tray, not a new sheet.
4. **Add is untouched:** Add → digits → Next → tile, no new tap or field (CLAUDE.md's entry-speed rule).

V2 is the strong alternative if the owner values one rule across bills and entries over the extra tap for category.

## Applies to any version
- **First key replaces** a prefilled amount; ⌫ first removes one digit. A `fresh` flag in `AddEntryBloc`, test-first: "3" on ₹250 → ₹3; ⌫ on ₹250 → ₹25; a quick chip on ₹250 → ₹300 (chips still add, FR-AD-1).
- **Current category marked** by outline and a tick, read as "Food, now" (accessibility rules: state by shape and words).
- **Undo after an edit:** 4 s, held with TalkBack (D105), naming what changed: "Moved to Travel", "Changed to ₹350", "Note changed". Undo restores the old entry exactly, `created_at` included (BR-17 learning). This changes BR-10.
- **Unchanged:** fixes (*Not logged*) and *Used*, *Saved* and card-paid entries stay non-editable in the tray (BR-10, BR-18, BR-19, D120, D123). The *your usual* pill never shows in edit (FR-AD-10 AC-1). A bill's posted entry still feeds next month's estimate (D127).

## Open questions for the owner
1. **V4 or V2?** (Or V1 as a stopgap now.)
2. **Back after typing a note or picking a day in V4:** drop it silently (as the tray does today), or ask "Leave without saving?"? I'd drop it silently. The *Save* key is in view, and nothing typed so far is money.
3. **Undo on edit:** OK to change BR-10?

## If approved: build plan
1. **Docs:** a DECISIONS row; rewrite FR-AD-8 with acceptance criteria (opens on step 2, current tile marked, Save key, amount chip, first key replaces, Delete beside Save, Undo snackbar); BR-10's Undo line; UI_DESIGN's tray section. → verify: SPEC › UI_DESIGN › mockup agree.
2. **Bloc (TDD):** start step for edit; a `fresh` amount flag; `AddEntrySaveRequested` that keeps the category; Undo restoring the old entry. Failing tests first, with `FakeClock`, a back-dated entry, a bill-posted entry and the 9-digit cap. → verify: `flutter test test/add_entry`.
3. **UI:** `CategoryStep` edit variant (marked tile, Save and Delete keys, amount chip); `AmountStep` key label; ARB strings via design-content. → verify: widget tests at every `TestWindows` size, an a11y test, `flutter analyze`, `scripts/changed_lines_coverage.sh`.
4. **On device:** Today list, Every entry, a back-dated entry, large text, landscape.

## Round 2 (owner: "this isn't right")
The owner didn't like V1–V4 but couldn't say why. All four start from the Add tray or a form, so changing an entry still feels like filling it in again. Round 2 starts from the entry itself. Clickable prototypes: [48-entry-edit-directions.html](../../design/mockups/48-entry-edit-directions.html).

### More research
- **Tapping shows the thing first.** Things 3: a task "will pop out into a card-like form while the rest of the list fades into the background", and its notes and checklist show in full on the card ([MacStories](https://www.macstories.net/reviews/things-3-beauty-and-delight-in-a-task-manager/), [Cultured Code](https://culturedcode.com/things/features/)). Splitwise opens a details page with edit and delete ([Pratt critique](https://ixd.prattsi.org/2020/02/design-critique-splitwise-android-app/)). Money Manager opens the entry's editing page ([Realbyte help](https://help.realbyteapps.com/hc/en-us/articles/360042743374-How-to-make-a-bookmark)).
- **The value is the button.** Copilot: "tap on the current transaction date or name to edit them"; on iPad, tap a transaction's category to edit it without opening the transaction ([Copilot help](https://help.copilot.money/en/articles/9554412-transactions-tab-overview)). Monzo: "tap the category shown at the top", "Add notes and #tags" ([Monzo](https://monzo.com/blog/monzo-business-how-to-add-information-to-transactions)). A Monzo user found the category didn't look tappable and asked for a "Change category" label ([community](https://community.monzo.com/t/we-re-making-some-changes-to-our-payments-flow/155254?page=2)).
- **Re-entering unchanged answers is the complaint.** Monefy, when editing: accounts "are reset and have to manually specify them. That's difficult when I can't recall what the previous accounts were exactly" ([Play review](https://play.google.com/store/apps/details?id=com.monefy.app.lite&hl=en_SG)).
- **Stay in place; quick actions under the row.** Monzo users complain the app returns to the home page after an edit, and ask for quick actions under each transaction so they don't have to open another screen ([returns to homepage](https://community.monzo.com/t/app-returns-to-homepage-after-editing-transactions/183148), [quick actions](https://community.monzo.com/t/quick-actions-on-transaction-list/116562)).
- **Undo over confirmation** for reversible changes; keep dialogs for the irreversible ([NN/g confirmation dialogs](https://www.nngroup.com/articles/confirmation-dialog/), [NN/g serial task switching](https://www.nngroup.com/articles/serial-task-switching/)). Cashew added an activity log of modified and deleted transactions ([Cashew releases](https://github.com/jameskokoska/Cashew/releases/)).
- **Indian UPI apps** (GPay, PhonePe, Paytm) don't publicly document editing a past payment's category or note. Third-party trackers (Glass Money) let you recategorise one at a time or in bulk ([Glass Money](https://glassmoney.app/upi-expense-tracking)).

### Principles
1. Tap shows the entry; it doesn't replay Add.
2. Each value is its own button. No Edit mode, no form, no Next.
3. Never ask again what didn't change.
4. Picking saves; Undo instead of Save, Discard or a confirmation.
5. Stay where you were.

### Directions (clickable)
| | A Opens in place | B Sentence | C Entry page | D Quick fixes under the row |
|---|---|---|---|---|
| Model | Things 3 | Home's hero sentence | Copilot, Monzo, Money Manager | Monzo users' ask |
| Tap the row and… | it grows into a card in the list | a sheet reads "Spent ₹250 on Food, today." with each underlined part tappable | a page for that entry, with context ("Food this cycle ₹3,240") | 4 buttons drop under it: Amount, Category, Note, Day, plus delete |
| Move category | 4 taps (3 without Done) | 4 (3) | 4 (3) | **3** |
| Sees the whole entry | yes | yes, as words | yes, with context | no |
| Two fixes at once | yes, one Undo for all | yes | yes | open twice |
| Risk | card inside a scrolling list at large text and landscape | underlines must look tappable without colour | heaviest; a new screen | reads as actions, not the entry |

Not proposed: drag an entry onto a category (direct manipulation, NN/g): hidden, hard with TalkBack and Switch Access; a long-press menu: hidden.

No recommendation yet. The owner tries the prototypes first. B is closest to the app's voice and the 5-year-old bar; D is the cheapest; C has the most room to grow.

### Round 2b (owner picks A, 2026-11-17)
The owner likes **A, the row opens up where it is**, with two changes, both in mockup 48:
1. **The note is typed in the card itself**, not in a sheet. It saves on *Done*, on the keyboard's done key, or when another part is tapped; Undo covers a slip. While typing, the card rises above the keyboard (the hero scrolls away).
2. **The category didn't read as tappable** at first sight. *Food ▾* and *Today ▾* now carry a caret (the tray's date chip already uses ▾), the amount keeps its dotted underline, and until the first change the card reads "Tap any part to change it". No flash or pulse: the signal colour and motion are for *today / act* only, and the cue must work with reduced motion.

## Round 3 (owner: keep A only, improve it, add motion)
B, C and D are dropped (removed from mockup 48). Four versions of A, clickable, with switches for slow motion, reduced motion and a haptic readout: [49-entry-card-motion.html](../../design/mockups/49-entry-card-motion.html).

| | A1 Card with sheets | A2 Everything inside the card | A3 A2 with "was" | A4 Tap where it's wrong |
|---|---|---|---|---|
| Idea | Round 2b's card, polished | Amount keypad, category grid and day pills unfold inside the card, one at a time | Each change leaves "~~₹250~~ Put back" in the card | Row has tap zones: amount opens the keypad, icon opens the categories; a one-time drawn underline teaches what's tappable |
| Move to Travel | row, Food, Travel, Done | same | same | **row icon, Travel, Done** |
| Fix amount | row, ₹250, digits, Save, Done | row, ₹250, digits, Done | same as A2 | **row amount, digits, Done** |

**Shared motion** (UI_DESIGN §6; delight scales inversely with frequency):
- The row grows into the card on `standard`, while the other rows fade to 35% and the hero tucks into one line reading "updates when you're done". This keeps D91's rule visible: Home holds its number while you edit.
- The ▾ turns over when its part opens.
- The first digit lifts the old amount away (`snap`).
- Each saved part draws a tick that fades at 1.6 s. The amount rolls (300 ms). A new category's icon slides in.
- Done folds the card back into the row, which outlines once. Then the hero opens, rolls and the bar moves, with `success` on that frame. A Done with no change plays no haptic.
- Reduced motion: 150 ms crossfades, no shake, and the ticks and lines just appear.

**New copy ideas** (draft, need design-content): "Tap any part to change it", "Keep ₹250" / "Change to ₹350" on the keypad key, "updates when you're done", "Put back", "2 changes saved · Undo".

**Rule that makes A2–A4 work:** moving on saves. Tapping another part, Done or the note keeps what you typed, just like the note. Nothing is ever half-saved, and one Undo after Done reverses the whole visit.

### Round 3b (owner picks A2, 2026-11-17)
**A2, everything inside the card.** The category part shows the same grid as the Add tray: the 8 built-in tiles in their places, then the user's own in row 3 under the "Your own" rule (D138), so no tile moves between adding and changing. A hidden category of the user's own shows **only** when it holds the entry being changed, marked as current; otherwise it stays out of the grid, as in Add. *Your usual* never shows (FR-AD-10 AC-1). Open: whether the *New* tile belongs in the card.

### Round 3c: A2 with the *New* tile (owner asked for a mockup)
Mockup 49, phone "A2 + New". The dashed *New* tile sits after the user's own, as in Add (FR-AD-9). Tapping it folds the grid into a naming step **inside the card**, and the note and Done wait underneath:
- *‹ Categories* goes back to the grid with nothing made.
- "What's it called?" with a focused field and the six name chips, which narrow as you type and leave out names already shown.
- "Icon from the name: Bag · Change". *Change* unfolds 8 icons in the card.
- One marigold key, "Move to {name}", disabled while the name is empty. A name that matches reads "You have Food already. It moves there."
- The 4-own limit removes the tile and shows FR-AD-9 AC-1's line.

Saving makes the category, moves the entry, folds the step and slides the chip's icon in. **Undo moves the entry back but keeps the new category**, as when the entry's save fails after the category is made (FR-AD-9 AC-4). Copy differs from Add's *Save in {name}* because nothing new is saved here, only moved: draft, needs design-content.

### Round 3d: the dock and other windows (owner: "you didn't account for the dock and landscape")
Rounds 1–3c drew a portrait phone with no dock. Fixed in mockup 49:
- **The dock steps aside.** While the card is open, the floating dock (§4) slides down on `standard`; it comes back on Done or Delete, and the Undo snackbar sits above it (D105). Mid-edit, *Home*, *Add* and *Spends* mean nothing, and Add would open a second tray over a half-changed entry. This also frees about 90dp for the keypad.
- **Expanded windows (phone landscape, tablet, unfolded landscape): the part opens in the other pane.** Home's pane is about 360dp tall, too short for a keypad inside the card. The card stays in its list; the keypad, grid, days or New category take the other pane over Spends (dimmed), with its own title and "₹250 · Food · Today", then slide out. The Add key leaves the Home pane while editing. Mirror rule for an entry opened in the Spends pane. The note stays in the card.
- **Rule:** the card stays where the row was; the part goes where there's room. Under the chips when tall; beside the card when wide; below the fold in tabletop; in a short narrow window (split-screen) the list scrolls the card to the top, keys drop to 48dp, and the open part's key stays pinned. Full table in mockup 49 ("Every other window"). Each row becomes a `TestWindows` case at build time.

### Round 3e: owner picks "A2 + New"; hero, dock and the landscape board
- **Hero (portrait):** not hidden. It tucks into one line while the card is open, holding its number (D91). Once something changes it previews the result, "Safe today ₹430 → ₹330 · after Done", like Add's preview line (FR-AD-3). It hides only while the keyboard is up.
- **Dock (portrait):** slides off while the card is open and back on Done or Delete; Undo sits above it.
- **Landscape and other expanded windows use the space:** the other pane becomes a **board with every part at once**: day pills on top, the keypad left, the category grid (your own and New included) right, and a live line ("Today's share ₹430 → ₹280", or "Moves off today: …"). Nothing is opened first: move category = row → tile → Done; fix amount = row → digits → Done. Tapping a part in the card outlines its place on the board. New swaps the grid for the naming step in place; the keypad and days stay. Supersedes 3d's one-part-at-a-time pane.
