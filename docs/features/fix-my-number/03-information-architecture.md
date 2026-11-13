# Information architecture for Fix my number, yearly costs and the missed-log line

> **Status: signed off 2026-11-13 (`08-design-qa-and-signoff.md` §8; X27, X29 to X32, X35 to X38 and O5, O6 applied below).** One IA pass over the three features so Home and Settings stay one coherent picture. Nothing here is in SPEC, PLAN, UI_DESIGN or DECISIONS yet, and no code exists; SPEC wins once written. It builds on `01-ux-flow.md` and `02-accounting-and-edge-cases.md` (this folder), `docs/features/yearly-costs/01-ux-flow.md` and `docs/features/habits/08-missed-log-line.md`, and the binding owner answers in case study 33. Copy is a placeholder for `design-content`, layout for `design-ui`. Where this file and the UX docs differ on placement, this file is the recommendation to confirm.

## 0. The object map

| Object | Is | Lives in | Found a second time by |
|---|---|---|---|
| Entry kinds | *Spent*, *Got*, *Saved* (money put into a saving, D120), and new: *Used* (paid from a saving, touches no number) | Today list, Every entry | Home *See all* > Every entry |
| Not logged | Not a kind. A hidden **category** on an ordinary *Spent* or *Got* entry (as `saved`, `card_paid`) | Same lists | Same; no chip of its own (4.4) |
| Saving | A monthly rule plus a **set-aside balance** (computed) | Settings > Money > Savings | Home due-soon row (before a put-in), Settings |
| Fix my number | An **action**, not a setting; it makes one *Not logged* entry | A sheet opened from three doors | Home foot row, Settings row, one-time Home line |
| Missed-log line | A question, never stored as content; writes only `asked_on` | Home's nudge slot | It is not "found"; it comes once a day or not at all |

Four questions, answered once:
- **Adds a level, tab or setting?** No tab, no setting, no Settings level. Home gains one row (the foot row) and the slot gains two possible lines; Settings gains one row. Settings > Savings > saving > *Used* question is the same depth as Bills > bill > *Amount* question (a question inside the sheet, FR-SE-1 AC-3). Nothing new is asked in onboarding (Q6 stays closed).
- **What was removed or defaulted instead (PLAN §2)?** The guard threshold is derived from income, not a setting. *Used* has no date field and no reminder (owner). Fix my number has no date picker and no edit mode. The missed-log line has no ×.
- **Clash with glossary or banned words?** See section 5.

## 1. The nudge slot (FR-HO-3)

### 1.1 What actually sits where
Reading `lib/home/presentation/pages/home_page.dart`: the order today is hero, over card, **saved-yesterday note**, **nudge slot**, Today list. So the note is not a slot item; it is a separate one-line note directly **above** the slot. It never competes for the slot, but the two stack. The slot itself shows one line.

### 1.2 Final order (highest first)

| # | Line | Why here |
|---|---|---|
| 1 | **Waiting bill** (BR-9) | The bill's money is already out; the number is wrong until it is answered. The guarantee behind the due-day reminder (D126) |
| 2 | **Due-soon bill or saving** | A promise about money to come; it opens a sheet the user may need (it is also the passive door to *Used*, section 3) |
| 3 | **Install line** (P1, one time) | A one-time offer with a short life. It must beat the repeating line: the missed-log line can appear every day from day 14, the install line can appear once |
| 4 | **Missed-log line** (P4′) | Optional and repeating (once a day), a question about a habit; ignoring it is free, so it always yields |
| not in the slot | Saved-yesterday note | Information, not a question. Stays where it is. **It does not silence the missed-log line** (answers 08 open question 4): they say different things in different places, and the note is about yesterday, the line about today |

Rank logic: money the user owes an answer to, then money to come, then a one-time pointer, then a repeating question. Bills are a promise; the last two are offers.

### 1.3 Rules that make the order stable
1. **Higher may preempt, lower may not appear mid-view.** Extend the missed-log rule (08 §1 "evaluation points") to the whole slot. Lower lines (3, 4) are decided at an *evaluation point* only: cold start and resume (a door that opens a tray over Home resumes the app, so that resume is the point; **a tray closing can only remove a line, never add one**, X36, 05-F7). A bill line (1, 2) may arrive at any reload (midnight, the engine posting a bill, Undo of a card bill paid), because the money guarantee outranks calm.
2. **When a higher item clears mid-day** (the user answers the waiting bill, deletes the saving, pays the due-soon bill): the slot **collapses to empty**. The next lower item does **not** slide in. It is evaluated at the next evaluation point. Reasons: a line arriving the moment the user finishes a task reads as a second ask; Home must not pop content in behind a bill sheet (the same reason 08 refuses a late-arriving line); the Today list below would shift twice.
3. **When a lower line is on screen and a higher item arrives** (midnight): the higher takes the slot and the lower leaves. A line that was *seen* stays used: the install line's *seen* flag and the missed-log's `asked_on` were already written, so neither returns. This is the only way the install line can be "lost", and it was seen first.
4. **The install line starves safely.** *Seen* is written only when the line is on screen with Home visible. A bill line holding the slot, a tray over Home or an over state means it was not seen, so it waits. **Expiry:** it is offered only in the cycle in which the app was installed, and never after that cycle ends (the next payday starts a clean cycle, which is Q6's own answer). It is also consumed by any *Not logged* entry (the user already found the door).
5. **Over states.** The calm over card (FR-HO-5) keeps one next step. In over states **both lines 3 and 4 wait** (08 already says so for line 4; this extends it to line 3, to keep one next step). Bill lines 1 and 2 still show. The foot row is not a next step and stays (section 2).
6. **No income:** no lines 3 or 4 (no number to fix, no habits to ask about), no foot row. Lines 1 and 2 cannot exist without rules.
7. **Nothing counts, nothing badges.** No count of waiting lines, no "2 more".

## 2. P1 entry points

### 2.1 Is a permanent Home foot row right?
**Yes, with three guard-rails. Settings-only fails the finding test.** The user who needs it is the one staring at a wrong hero; a door two levels away behind the word *Settings* is the severity-3 miss the UX doc already names (I-1). Front doors (Brown) says a frequently *felt* need, even if rarely *used*, wants a door where the feeling happens: Home.

Options weighed:

| Option | Verdict | Reason |
|---|---|---|
| **A. Foot row, always except *No income*** | **Chosen** | At the end of the scroll, below everything, so it moves nothing above it (the dock and the Add key stay put). Appearing or disappearing shifts no other element. Predictable: it is always there |
| B. Conditional foot row (shows when hisaab "suspects" drift) | Rejected | A hidden rule; a door that moves breaks "find it a second time" and reads as a nudge (principle 48). Needs a drift model that does not exist |
| C. Under the Today list's *See all* / in the card header | Rejected | *See all* means "list of entries". Fix my number is not a list. A second link in one header breaks D131's one-link-per-title |
| D. The hero's range line | Rejected | The hero answers the question and is tapped to toggle Today/This week (FR-HO-2). Putting a "my number is wrong" link inside the answer undermines trust in it, and adds a second tap target to the card |
| E. The over card | Rejected (UX doc agrees) | One next step; shame-adjacent |
| F. Spends | Rejected | Wrong moment; the doubt is felt on Home |
| G. Settings only (+ install line) | Rejected as the only door; **kept as the fallback** | Fails recognition over recall |

Does it clutter Home or invite lazy logging? Clutter: it is one quiet row after the last Today row, below the fold on a busy day, and at the end it competes with nothing. Lazy logging: it is not cheaper than logging one item (it needs a figure read off a bank app, 7 taps), only cheaper than logging three or more, which is the point. The owner chose visibility over limits; each fix is a labelled row in Spends and the export, so the loop is open, not hidden. Residual risk: the habit "fix every Sunday instead of logging". Accepted; test in the hallway (section 6).

**Guard-rails (IA constraints for `design-ui`):**
1. **It must not look like the nudge slot.** The slot line is a `sunk` squircle (radius 18, min 56dp) with a `surface` icon well, as `DueSoonRow` is in `lib/home/presentation/widgets/due_soon_row.dart` (X31: mockup 41's "`DueSoonNote`, `surface` card" claim is wrong). Same look means "the same kind of thing", so a sunk foot row would read as a nudge that never leaves. Decided (X30): a **text row** (label and chevron, no `sunk` fill, no icon well, `ink2`), 48dp or more, no second line, no count. `01` W1 now draws it that way.
2. **One line, no second line, no count.** Never "Last fixed 3 days ago".
3. **Hidden** in *No income*, and while Home is loading or failed. **Shown** in over states, with the foot row below the Today list, not near the card.

### 2.2 The label
**"Fix my number"** everywhere (foot row, Settings row, install line's second line, snackbar). The user's own word for the hero is "number" ("your daily number doesn't change", yearly costs S5). The page title is a question, a different job ("How much of this month's money is left?"); a door's label and a page's title may differ. One word for the idea, so no "Match", "Reconcile" or "Fix balance" anywhere (*balance* is also avoided for a saving's pot, which uses *set aside*). Pending the blind read in study 34.

### 2.3 Settings home: *Money*, not *Your hisaab*
**Recommendation: the last row of the *Money* group, after *My month starts on*.** *Your hisaab* (FR-SE-4) is about the data on the phone: Back up, Restore, *Delete everything*. A corrective act on this month's figure beside *Delete everything* reads as a data-repair or destructive tool, and "Your hisaab" is the vaguest group name for someone hunting for a wrong number. *Money* is where the money rules live (Money coming in, Bills, Savings, My month starts on), is the **first** group, and holds an action already (*Put in extra* sits under Savings). Add at the end so no existing row moves. Second line (the deck's, X25): "When the number on Home looks wrong." (it says *when*, in the user's words).

Confidence is medium (`01` first chose *Your hisaab*; X29 settled on *Money*, pending the tree test): both candidates go in tree test T8 and the pass mark decides; a tie keeps *Money*. The user test does not block the build (08 §8.3). Hidden in *No income*.

## 3. P2′ *Used*: discovery

**Confirm Settings-only for v1, with no Home element, and add a ladder with a trigger instead of guessing.** Reasoning:
- The cost's date is not stored (owner: no reminder), so no honest Home moment exists to ask. Any "paid your insurance?" line is a guess, and the slot is already four items deep.
- The harm of missing *Used* is bounded: the pot reads high in Settings (informational); the hero is unaffected. The costly path (paying in Add as *Spent*, I-3) is not fixable on the Add path (no tap or field may be added, and matching notes is rejected as guesswork).
- Two existing doors already reach the sheet: the list's "₹4,000 set aside" third line (X37), and Home's due-soon row (FR-HO-3), which opens the saving's sheet monthly in the days before a put-in.

**Zero-cost cues to add now (no new element on Home):**
1. For the three yearly chips only, the setup caption gets a second sentence (free; X26, X38): "Paid once a year? Each month, put in the cost divided by 12." then "When you pay it, tap Used some of it." The user is thinking about the cost at that moment. The body scrolls above the fixed keypad if it does not fit.
2. **The sheet hint** "Paid the cost from this? Tap Used some of it." shows **only on the three yearly chips** (O6) and stays until hallway test T7 shows the key alone is understood (4 of 5), then it is dropped (X38).
3. The due-soon row for a saving that has something set aside stays as the UX doc says; no new wording.

**The ladder, with a trigger** (no analytics, so the trigger is the hallway test, section 6):
- Rung 1 (now): the above.
- Rung 2, if fewer than 4 of 5 testers reach *Used some of it* unaided: a *Saved* row in the Today list and Every entry becomes tappable and opens that saving's sheet (as the due-soon row does). This breaks FR-HO-4's "a saving has no tap" but adds no new control kind. It reaches the key the day money was put in, which is a weak but honest moment. **Not pre-approved (O21):** decide only if the hallway test fails.
- Rung 3 is **never** a Home banner or a notification (principle 48).

## 4. Labels and taxonomy

### 4.1 One word per idea (D132)
| Idea | Word | Never |
|---|---|---|
| Money out you logged | *Spent* | transaction, debit |
| Money in | *Got* | credit |
| Money put into a saving | *Saved*, "put in" | (*saved* is never an underspend, D121) |
| Money in a saving not yet used | "set aside" | balance, worth, fund |
| Paying a cost from that pot | *Used* ("Used some of it" on the key) | withdrew, redeemed |
| Gap fix, either direction | *Not logged* (the category), "Fix my number" (the act) | reconcile, adjust, true-up, balance |
| The hero | "number" (colloquial), "Safe to spend today" (title) | budget |

### 4.2 How each entry reads
Rows have a title, a kind word (omitted for ordinary *Spent*), an amount, and in Every entry an explaining second line. No sign, no colour; direction is a word. None is a bite on Today's bar and none is in the header total (the saving precedent, D120). **Two-line shape (X22, X27):** the first line is the name (the saving's name, or "Not logged"), the second the kind word, amount at the end, like the *Saved* row; a one-string title does not fit a 176dp column.

| Entry | Home Today list | Every entry | Ask AI / CSV |
|---|---|---|---|
| Typed spend | Food · Chai ₹60 | same | kind `spent`, category, note |
| Saved | RD · Saved · ₹1,000 (no tap) | same | kind `saved`, category `savings` |
| **Used** | Line 1 "Insurance", line 2 "Used from savings", ₹4,000 at the end (no tap, swipe deletes). Spoken: "Insurance. Used from savings 4,000 rupees." | extra line "Paid from what you set aside." | kind `used`, category `savings`, note = the saving's name; facts clause says it is paid from savings |
| **Not logged, Spent** | Line 1 "Not logged", line 2 "Spent", ₹4,200. Spoken: "Not logged. Spent 4,200 rupees." | extra line "Added when you fixed your number." | kind `spent`, category `not logged`, note "Not logged"; facts clause says it is money not logged item by item |
| **Not logged, Got** | "Not logged" / "Got", ₹1,000. Spoken: "Not logged. Got 1,000 rupees." | same extra line | kind `got`, category `not logged` |

Two notes. (a) The direction word is always shown for *Not logged* because colour and sign are unavailable and direction is the whole point. (b) *Used* is shown as "Used from savings" (X27, deck R7), which cannot be read as an insurance *claim*; the blind read still checks it (fallbacks: "Paid from savings"). Rows without a bite share the 5-row Today list in time order; a fix posted now sits on top. Accepted.

### 4.3 Spends: "Spent · Saved · Not logged", three parts at most (FR-SP-4a; O5, X32, X33)
**Three parts, because *Used* is not spending (O5).** *Used from savings* does not appear on this line; it shows in Every entry and on the Savings list, where "set aside" lives (`06` G2: at most two new terms per screen).
- **Order fixed:** *Spent* · *Saved* · *Not logged*. Spent and Saved never move, so the common line is untouched; the new part only appends.
- **Present only when above ₹0.** Each part is unbreakable; the line wraps **between** parts at narrow widths or 1.5x text, with no trailing dots (mockup 42 option B fixes the 2dp overhang). TalkBack reads one sentence: "Spent 27,570 rupees. Saved 1,000 rupees. Not logged, spent 4,200 rupees." (X28).
- **The *Spent* figure excludes *Not logged*, as it excludes *Saved* (X33).** The part is its own number, not inside "Spent". Put it in SPEC FR-SP-4a and in the Ask AI facts clause.
- **Not logged on this line is the Spent side only** ("Not logged ₹4,200"). A *Got* fix is money in; Spends' line shows no *Got* total for any entry, so it is not added here. It is visible in Every entry and the export (this meets "visible in Spends", O2).
- Why not a second row of different meaning: the parts have no honest split (Saved moves the number, Not logged moves the pool), so any grouping invents a taxonomy. Wrapping is simpler.

### 4.4 Every entry: category chips and hidden categories
- Chips stay "All plus each **pickable** category with entries" (FR-SP-6): the 8 built-in, the user's own (including user-hidden ones with entries), and *Got* categories.
- **System categories get no chip of their own:** `saved` / savings (so *Used* rides with it), `card_paid` and `not logged`. Their entries show under *All*, in date order, and their rows have a different form (kind word, no category tile). A chip for each would be a filter for "what did I spend on X", and these are not X. **Check:** `lib/spends/presentation/pages/entries_page.dart` builds chips from `state.chips`; confirm during build whether a Savings chip already exists (the SPEC is silent) and keep whichever behaviour is current for *Saved*, with *Used* the same.
- If testing shows a user cannot find a fix to delete it, add a trailing *Not logged* chip, which appears only in cycles that have one (cheap, no reorder). Not now.
- A *Not logged* row is **never** in *Where it went*, percentages, limits or insights (BR-12 to 14). Home's *Today*, Every entry and the export are the only places.

### 4.5 Label clashes to flag
| Clash | Severity | Note |
|---|---|---|
| *Used* (a saving) and the over card's "This month's money is **used up**" | Low | Same root, two ideas (D132). Different screens and sentence shapes; *Used some of it* is on a key in Settings. Keep, but the blind read should include both. Fallback for the key: "I paid from it" |
| *Used* and *Saved* adjacent | Low | Opposite verbs on one pot; fine |
| "Not logged" may read as a failure (I-5) | Medium | Row second line explains. Fallback "Added to match" (study 34) |
| Glossary lacks *Not logged*, *Used*, *set aside*, "Fix my number" | n/a | Add on approval (section 7) |

## 5. Content hierarchy (changed screens only)

**Home** (primary, secondary, on demand)
- Primary: hero, today's bar, range line.
- Secondary: over card (when over), saved-yesterday note, the **one** slot line (section 1), Today list.
- On demand / quiet: **foot row "Fix my number"** (text row, end of scroll), *See all*, Settings button.

**Fix my number sheet:** primary the amount and the question; secondary the preview (one fixed-height slot); on demand the large-higher second question.

**Spends:** primary the cycle and *Ask AI* card as today; secondary the Spent/Saved line (+ *Not logged* when present); on demand Every entry with the new row kinds.

**Settings:** *Money* group gains the row at its end; *Savings* list rows gain a **third** line "₹4,000 set aside" (X37; the schedule line "Every month on the 5th" stays; only above ₹0) and the footer a second line; the saving's sheet gains a balance line and *Used some of it* (outlined, mid-sheet, far from *Delete saving*).

## 6. Sitemap delta (changes marked `+`)

```
BEFORE                                  AFTER
Home                                    Home
  hero card                               hero card
  over card (when over)                   over card (when over)
  saved-yesterday note                    saved-yesterday note
  nudge slot: waiting | due-soon | none   nudge slot: waiting | due-soon | + install line | + missed-log line | none
  Today list (+ See all)                  Today list (+ See all); rows + Used, + Not logged
                                          + foot row: Fix my number (text row)
  dock: Home | Add | Spends               dock: unchanged
  Settings (top right)                    Settings (top right)
Spends                                  Spends
  Ask AI card                             Ask AI card
  chart, Spent·Saved line                 chart, Spent·Saved [+ Not logged]
  Where it went                           Where it went (unchanged: new kinds excluded)
  See all > Every entry                   See all > Every entry; rows + Used, + Not logged; chips unchanged
Settings                                Settings
  Money: Money coming in, Bills,          Money: Money coming in, Bills, Savings,
    Savings, My month starts on             My month starts on, + Fix my number
    Savings sheet: amount, day, name        Savings sheet: + balance, + Used some of it (question inside the sheet)
    Savings list: rows, footer              Savings list: + "set aside" third line, + footer line 2
  Look, Categories, Your hisaab,          Look, Categories, Your hisaab (unchanged), Shortcuts
    Shortcuts
                                        + Fix my number sheet (bill-sheet route): from the Home foot row,
                                          Home install line, or Settings > Money (not a child of Settings)
```

## 7. Study plan (hisaab has no analytics; hand-run, 5 to 8 people, no code needed)

| Study | Question | Method | Pass line |
|---|---|---|---|
| **A. Tree test, Settings placement** | Money or Your hisaab for *Fix my number*? | Text tree of Settings with the row in each position (two between-subject variants). Task: "The number on Home looks too high. Where would you go to fix it?" | 80% first-click success and 70% direct (no backtrack); else the winner, else the UX doc's choice. Run before build |
| **B. Closed card sort (5 to 8 cards)** | Do Used / Not logged / Saved / Spent group sensibly? | Cards: the four row labels plus their second lines; groups "money I spent", "money I moved", "fixed by hisaab". Read aloud for the 5-year-old bar | Used is placed with "moved" by most; "Not logged" is not read as an error (also covers I-5) |
| **C. Hallway, Used discovery** | Can a user mark a paid yearly cost from savings? | Scenario: a saving with ₹4,000 set aside; "You paid the insurer from the bank. Tell hisaab." Observe from Home | 4 of 5 unaided within 60 s; else rung 2 (3) |
| **D. Hallway, foot row** | Does the foot row get seen, and does it read as a nudge? | Ask "How would you correct a wrong number?" with Home open and the row below the fold; then "What is that row?" | 3 of 5 find it; none call it a message |

## 8. Doc edits needed (listed, not made)

| Doc | Edit |
|---|---|
| UI_DESIGN §4 | One line: Home's end of scroll holds a quiet *Fix my number* text row; Settings > Money gains the same row. No new tab or level |
| UI_DESIGN §5.2 | Slot order of four lines; collapse-empty rule; foot row as a text row not the sunk nudge shape |
| SPEC FR-HO-3 | Slot order, install line, missed-log line, no lower line appearing mid-view, over-state and *No income* rules (1.3) |
| SPEC FR-SP-4a | Three parts (*Spent · Saved · Not logged*), fixed order, conditional, wraps between parts; *Spent* excludes *Not logged*; *Not logged* is the Spent side only; *Used* is not on the line |
| SPEC FR-SP-6 | System categories get no chip |
| SPEC FR-SE-1 | *Fix my number* row at the end of *Money* |
| SPEC §2 glossary | *Used*, *set aside*, *Not logged*, "Fix my number" ("number" = the hero) |
| DECISIONS (next free IDs) | (a) Slot order: waiting, due-soon, install, missed-log; a lower line never appears mid-view. (b) Permanent *Fix my number* text row on Home, always except *No income*. (c) Settings home is *Money*, not *Your hisaab* (pending study A). (d) *Used* is discovered from Settings only, with a ladder and no Home banner. (e) Three parts on the Spends line, *Used* off it |

## 9. Open questions (answered by 08 §8 unless marked)

1. **Settings group:** end of *Money* (X29), pending tree test T8; a tie keeps *Money*.
2. **Foot row look:** a text row (X30). Decided.
3. **Got-side fix on the Spends line:** left to Every entry and the export (O2).
4. **Install line in over states:** waits (O14).
5. **Saved-yesterday note and the missed-log line:** do both; the note does not silence the line (O15).
6. **Chips:** still open for the build (P13): confirm whether a Savings chip exists today in Every entry; system categories get none.
7. **Used discovery ladder:** rung 2 is not pre-approved (O21).

## Source scope
`docs/features/fix-my-number/01-ux-flow.md`, `02-accounting-and-edge-cases.md`, `docs/features/yearly-costs/01-ux-flow.md`, `docs/features/habits/08-missed-log-line.md`, case study 33 ("Design-product review", "Owner answers"), SPEC §2 glossary, BR-8, FR-HO-1 to 5, FR-SE-1, FR-SE-4, FR-SP-4a, FR-SP-6, UI_DESIGN §4 and §5.2, DECISIONS D21, D54, D131, D132, `lib/home/presentation/pages/home_page.dart` (build order of note and slot), `lib/spends/presentation/pages/entries_page.dart` (chips), `lib/l10n/app_en.arb` (Settings group keys). No code was changed.
