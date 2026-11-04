# 16. Changing a fixed bill

## Job of the screen
Change one thing about a bill that already exists. Usually that's the amount (rent goes up, the phone plan changes). Less often it's the day, and the name almost never changes. The user knows exactly what they want to change before they open the bill.

## What's wrong
Changing a bill runs the same three-question wizard as adding one (FR-SE-1, D35). To change only the amount:

| # | Action | Screen change |
|---|---|---|
| 1 | Home → Settings | push |
| 2 | Settings → *Fixed bills* | push |
| 3 | Tap the bill row | push (editor, Name step) |
| 4 | *Next* past the unchanged name | step |
| 5 | Clear the old amount and type the new one, then *Next* | step |
| 6 | Tap the **same day again** to save | pop |

That's five taps plus the digits and five screen changes for a one-field edit. The user has to re-confirm two answers they didn't change. The day step makes it worse: it saves on tap, so the user can't finish without tapping a day, even an unchanged one. Back walks backwards through the steps (`BillEditorPage._canLeave`). Leaving after step 1 means pressing Back up to three times, and nothing says whether the change was kept.

Measured against our own bar: the wizard suits **adding** a bill (one question at a time, pills help name it, D83–D86). It doesn't suit **changing** one.

## Research
- **Create in steps, change in place.** Many form tools use a wizard to create an item and a single view to edit it. In Infowise's forms, wizard mode applies only to new items, and existing items open as a normal form ([Infowise docs](https://www.infowisesolutions.com/documentation/index/207)). The opposite design draws complaints: a Zoho user whose records could only be edited through the wizard, one field at a time, called it tedious ([Zoho community](https://help.zoho.com/portal/hi/community/topic/im-stuck-in-an-edit-only-with-wizard-issue)).
- **Check answers / Change links.** GOV.UK-family design systems show a summary of the answers. Each answer has its own *Change* link that opens that one question, prefilled, and then returns to the summary ([DWP "Add another thing"](https://design-system.dwp.gov.uk/patterns/add-another-thing/how-it-works), [GovStack check answers](https://specs.govstack.global/service-patterns/4-design-patterns/6-page-templates/7.14-check-answers), [GOV.UK check answers](https://design-system.service.gov.uk/patterns/check-answers)). Each Change link carries hidden text that names its answer, so screen readers can tell them apart ([Scottish design system](https://designsystem.gov.scot/patterns/check-answers)). I couldn't reach GOV.UK's own rule for where a Change link returns to; the DWP page states it.
- **Repeated tasks favour fewer screens.** In PatternFly's comparison, 6 of 7 participants preferred a progressive single form to a wizard for tasks they do regularly. The sample is small ([PatternFly](https://medium.com/patternfly/comparing-web-forms-a-progressive-form-vs-a-wizard-110eefc584e7)). Merge.rocks notes that single-question steps work on mobile but feel slow for edits ([Merge.rocks](https://merge.rocks/resources/websites-playbook/ui-patterns/ux-wizard-mastery-7-essential-rules-for-multi-step-flows-that-convert)).
- **Cancel must restore.** Microsoft's wizard pattern: cancelling returns the record to its state before the edit ([Microsoft](https://learn.microsoft.com/cs-cz/dynamics365/fin-ops-core/dev-itpro/user-interface/wizard-form-pattern)).
- **Money apps.** In Rocket Money, editing a manual bill goes item → Options → Edit, a page-level form ([help](https://help.rocketmoney.com/en/articles/2185531-managing-your-bills-and-subscriptions)). Simplifi uses a three-dot menu that opens an "Edit series" screen, and users complain that the setting is hard to find ([Simplifi community](https://community.simplifimoney.com/discussion/comment/23158/)). ZeroSum moved to click-to-edit so a change no longer opens a dialog ([changelog, Mar 2026](https://zerosum.featurebase.app/en/changelog/v123-new-look-and-inline-editing)). None of them is a model to copy, but the trend runs towards fewer layers.
- **Our own precedent.** Editing an *entry* reuses the Add tray, opened prefilled (FR-AD-8). The tray is a sheet over the page, not a new route, so the list stays in view behind it.
- **Not found.** Copilot, YNAB and Walnut have no public screen-level material on editing recurring items.

## Patterns compared
"Taps" counts from the *Fixed bills* list, digits excluded. "Screen changes" counts each step or pushed page, including the list returning.

| Pattern | Change amount | Change day | Change name | Screen changes | Notes |
|---|---|---|---|---|---|
| A. Today: the full wizard | 4 | 3 | 4 + typing | 4 | Re-confirms unchanged answers; day tap forced |
| B. One form page (all three fields) | 2 | 2 | 2 + typing | 2 | Needs a keypad, a grid and a field on one screen: too dense on a phone; a typed field next to an in-app keypad is confusing |
| C. Tray opens on the keypad, with name and day as chips (like Add step 2) | 2 | 3 | 3 + typing | 0 | Fastest for amount; day and name are second-class; Save after changing only the day feels odd |
| **D. Bill sheet: a summary with a Change row per answer** | **3** | **2** | **3 + typing** | **0 pushes** (sheet changes view in place) | Shows the whole bill first, so it's reassuring; each change saves one answer; reuses today's three step widgets |

## Recommendation: D, the bill sheet
Tap a bill row and the tray rises over the *Fixed bills* list:

```
┌──────────────────────────────┐
│  Rent                        │  ← title
│  ₹18,000 · every month on 1  │  ← one sentence, read aloud as one
│                              │
│  Amount            ₹18,000 › │  ← Change rows (one card, hairlines)
│  Day of the month      1st › │
│  Name                 Rent › │
│                              │
│  [ Delete ]                  │  ← chip, as today
└──────────────────────────────┘
```

- **Tap a row** and the sheet swaps in that one question: the keypad (prefilled, like FR-AD-8), the 1–31 grid, or the name field. Back returns to the summary.
- **Amount and name:** the marigold key reads *Save*, not *Next*. **Day:** tapping a day saves, as today.
- **Saving one answer** writes it at once. The sheet goes back to the summary with the new value, plays the `tick` haptic, and the row in the list behind updates. No *Discard changes?* dialog is needed, because nothing is ever half-edited.
- **Close** with Back, a swipe down or a tap on the scrim. Unsaved typing is dropped, and saved answers stay saved.
- **Delete** moves from the Name step to the summary. It closes the sheet and deletes with Undo (BR-9, D35 unchanged).
- **Adding a bill keeps the three-question wizard** (pills, D86), because creating benefits from one question at a time.
- **Rows are ordered by how often they change:** amount, then day, then name.

Result: changing the amount takes 3 taps instead of 4 and no pushed page instead of 3 step changes. Changing the day takes 2 taps instead of 3. No unchanged answer is ever re-confirmed.

Mockup: [27-bill-sheet.html](../../design/mockups/27-bill-sheet.html), which styles the sheet as a paper bill and opens it from Home's due-soon line.

### Marking a bill as paid (owner question, round 3)
Nobody marks a bill as paid. The recurring engine counts it as spent on its day (BR-9), so the stamp says **Counted 5 Oct**, not *Paid*: the app can't know the money left, and a monthly "mark paid" task would be a chore and a nag. The remaining gaps already have a way out: an amount that varied, or a skipped month, is fixed by editing or deleting that month's entry in *Every entry*. Held: a **"Paid already? Count it today"** key on a due-soon bill's sheet, for people who pay early. Today the cycle total is right and only today's figure runs high for a few days, so this waits until someone reports it.

### Not in this change (open questions for the owner)
1. **Shorter way in.** Home → Settings → Fixed bills is still two pushes. Settings holds only *Fixed bills* today, so it's a pass-through page. One option is to make Home's *due soon* line (FR-HO-3) tappable to open that bill's sheet. It's visible, not hidden (D21), but it would need a tappable look. Proposed as a follow-up.
2. **Should Add also use the sheet?** Adding on a page and changing in a sheet is a small inconsistency. Research supports keeping them separate, so I'd leave it as it is.

## Build plan (on approval)
1. **Docs first:** add a DECISIONS row (supersedes the "editing asks three questions" part of FR-SE-1; D35 and D86 stand for Add). Rewrite FR-SE-1 with acceptance criteria for the sheet (AC: one-answer save, Back/scrim close, Delete on the summary, TalkBack labels "Change amount, ₹18,000"). Update UI_DESIGN line 390 and add a mockup `docs/design/mockups/26-bill-sheet.html`.
   → verify: SPEC › UI_DESIGN › mockup agree.
2. **Bloc (TDD):** add `BillSheetBloc`, or extend `BillEditorBloc` with a `summary` stage and per-answer events (`BillSheetAnswerOpened`, `BillSheetAnswerSaved`, `BillSheetBackPressed`). Saving goes through the existing `EditBill`, including D34's day rule. Failing tests come first: amount-only save keeps the day and `next_due`; day-only save follows D34 (payday 29–31, a day already past); a failed save keeps the sheet open with "Couldn't save. Try again."; double-tap is dropped (`droppable()`).
   → verify: `flutter test test/settings`.
3. **Sheet UI:** `BillSheet` follows `AddEntryTray.show`. The summary card reuses the `BillRow` styling, and the three questions reuse `BillAmountStep`, `BillDayStep` and `BillNameStep`. Each takes an `actionLabel`, and the name step has no pills and no Delete. All strings go in `app_en.arb` ("Change", "Save", spoken row labels).
   → verify: widget tests at every `TestWindows` size, a11y test (labels, 48dp targets), `flutter analyze`.
4. **Routing:** `Routes.bills`' `onEdit` opens the sheet instead of pushing `billEditor(editing:)`. `billEditor` keeps add-only, so drop its `editing` and `onDelete` parameters along with the editing branches they feed.
   → verify: existing add-bill tests stay green, and `scripts/changed_lines_coverage.sh` is ≥ 90%.
5. **On device:** check the sheet over the list, Back and predictive back, the keyboard pushing the name step up, and the large-text single column.

## Risks
- **Sheet height.** The keypad step needs about 460dp. On a small or landscape window the sheet must grow to full height (`context.layout`), as the Add tray does.
- **Two containers for one object.** Add is a page and Change is a sheet. Copy keeps them linked: the same three question titles.
- **Instant save per answer** means there's no "cancel all" after a save. That's acceptable: each saved answer is one obvious change, and the list behind shows it at once.
