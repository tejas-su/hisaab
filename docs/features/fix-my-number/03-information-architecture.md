# Information architecture for Fix my number, yearly costs and the missed-log line

> **Status: proposed (2026-11-13).** One IA pass over the three proposals so Home and Settings stay one coherent picture. Nothing here is in SPEC, PLAN, UI_DESIGN or DECISIONS, and no code exists. It builds on `01-ux-flow.md` and `02-accounting-and-edge-cases.md` (this folder), `docs/features/yearly-costs/01-ux-flow.md` and `docs/features/habits/08-missed-log-line.md`, and the binding owner answers in case study 33. Copy is a placeholder for `design-content`, layout for `design-ui`. Where this file and the UX docs differ on placement, this file is the recommendation to confirm.

## 0. The object map

| Object | Is | Lives in | Found a second time by |
|---|---|---|---|
| Entry kinds | *Spent*, *Got*, *Saved* (money put into a saving, D120), and new: *Used* (paid from a saving, touches no number) | Today list, Every entry | Home *See all* > Every entry |
| Not logged | Not a kind. A hidden **category** on an ordinary *Spent* or *Got* entry (as `saved`, `card_paid`) | Same lists | Same; no chip of its own (4.4) |
| Saving | A monthly rule plus a **set-aside balance** (computed) | Settings > Money > Savings | Home due-soon row (before a put-in), Settings |
| Fix my number | An **action**, not a setting; it makes one *Not logged* entry | A page opened from three doors | Home foot row, Settings row, one-time Home line |
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
1. **Higher may preempt, lower may not appear mid-view.** Extend the missed-log rule (08 §1 "evaluation points") to the whole slot. Lower lines (3, 4) are decided at an *evaluation point* only: cold start, resume, a door-opened tray closing. A bill line (1, 2) may arrive at any reload (midnight, the engine posting a bill, Undo of a card bill paid), because the money guarantee outranks calm.
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
1. **It must not look like the nudge slot.** The slot is a `sunk` 56dp row with an icon well; the UX doc's foot row is also sunk 56dp. Same look means "the same kind of thing", so the foot row would read as a nudge that never leaves, and the "one line" slot would look like two. Recommend a **text row** (label and chevron, no `sunk` fill, no icon well, `ink2`), 48dp or more. This differs from the UX doc's W1 sketch.
2. **One line, no second line, no count.** Never "Last fixed 3 days ago".
3. **Hidden** in *No income*, and while Home is loading or failed. **Shown** in over states, with the foot row below the Today list, not near the card.

### 2.2 The label
**"Fix my number"** everywhere (foot row, Settings row, install line's second line, snackbar). The user's own word for the hero is "number" ("your daily number doesn't change", yearly costs S5). The page title is a question, a different job ("How much of this month's money is left?"); a door's label and a page's title may differ. One word for the idea, so no "Match", "Reconcile" or "Fix balance" anywhere (*balance* is also avoided for a saving's pot, which uses *set aside*). Pending the blind read in study 34.

### 2.3 Settings home: *Money*, not *Your hisaab*
**Recommendation: the last row of the *Money* group, after *My month starts on*.** *Your hisaab* (FR-SE-4) is about the data on the phone: Back up, Restore, *Delete everything*. A corrective act on this month's figure beside *Delete everything* reads as a data-repair or destructive tool, and "Your hisaab" is the vaguest group name for someone hunting for a wrong number. *Money* is where the money rules live (Money coming in, Bills, Savings, My month starts on), is the **first** group, and holds an action already (*Put in extra* sits under Savings). Add at the end so no existing row moves. Second line (placeholder): "Say how much of this month's money is left."

Confidence is medium (the UX doc chose *Your hisaab*), so settle it with the tree test in section 6 before building. Hidden in *No income*.

## 3. P2′ *Used*: discovery

**Confirm Settings-only for v1, with no Home element, and add a ladder with a trigger instead of guessing.** Reasoning:
- The cost's date is not stored (owner: no reminder), so no honest Home moment exists to ask. Any "paid your insurance?" line is a guess, and the slot is already four items deep.
- The harm of missing *Used* is bounded: the pot reads high in Settings (informational); the hero is unaffected. The costly path (paying in Add as *Spent*, I-3) is not fixable on the Add path (no tap or field may be added, and matching notes is rejected as guesswork).
- Two existing doors already reach the sheet: the list's "₹4,000 set aside" second line, and Home's due-soon row (FR-HO-3), which opens the saving's sheet monthly in the days before a put-in.

**Zero-cost cues to add now (no new element on Home):**
1. For the three yearly chips only, the setup caption gets a second sentence: "Paid once a year? Put in about a twelfth each month. When you pay it, tap Used some of it." The user is thinking about the cost at that moment. `design-ui` to check it fits above the fixed keypad.
2. The due-soon row for a saving that has something set aside stays as the UX doc says; no new wording.

**The ladder, with a trigger** (no analytics, so the trigger is the hallway test, section 6):
- Rung 1 (now): the above.
- Rung 2, if fewer than 4 of 5 testers reach *Used some of it* unaided: a *Saved* row in the Today list and Every entry becomes tappable and opens that saving's sheet (as the due-soon row does). This breaks FR-HO-4's "a saving has no tap" but adds no new control kind. It reaches the key the day money was put in, which is a weak but honest moment.
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
Rows have a title, a kind word (omitted for ordinary *Spent*), an amount, and in Every entry an explaining second line. No sign, no colour; direction is a word. None is a bite on Today's bar and none is in the header total (the saving precedent, D120).

| Entry | Home Today list | Every entry | Ask AI / CSV |
|---|---|---|---|
| Typed spend | Food · Chai ₹60 | same | kind `spent`, category, note |
| Saved | RD · Saved · ₹1,000 (no tap) | same | kind `saved`, category `savings` |
| **Used** | Insurance · Used · ₹4,000 (no tap, swipe deletes) | second line "Paid from what you set aside" | kind `used`, category `savings`, note = the saving's name; facts clause says it is paid from savings |
| **Not logged, Spent** | Not logged · Spent · ₹4,200 | second line "Added to match your money" | kind `spent`, category `not logged`, note "Not logged"; facts clause says it is money not logged item by item |
| **Not logged, Got** | Not logged · Got · ₹1,000 | same second line | kind `got`, category `not logged` |

Two notes. (a) The direction word is always shown for *Not logged* because colour and sign are unavailable and direction is the whole point. (b) "Insurance · Used" can read as an insurance *claim*; the Every entry second line fixes it, the Today row cannot. This is on the blind-read list; fallback "Paid from savings" as the kind word. Rows without a bite share the 5-row Today list in time order; a fix posted now sits on top. Accepted.

### 4.3 Spends: "Spent · Saved" with up to four parts (FR-SP-4a)
**Four is not too many, because they are conditional, fixed in order, and almost never co-occur; the container is what must change.** A four-part cycle needs a yearly-cost saver who has paid from it **and** used Fix my number in the same cycle.
- **Order fixed:** *Spent* · *Saved* · *Used* · *Not logged*. Spent and Saved never move, so the common line is untouched; new parts only append (growth).
- **Present only when non-zero**; a part is never dropped (the owner: Not logged visible). Each part is unbreakable; the line wraps **between** parts at narrow widths or 1.5x text. TalkBack reads one sentence.
- **Not logged on this line is the Spent side only** ("Not logged ₹4,200"). A *Got* fix is money in; Spends' line shows no *Got* total for any entry, so it is not added here. It is visible in Every entry and the export (this meets "visible in Spends"). Owner to confirm (open question 3).
- Why not a second row of different meaning: the four parts have no honest split (Used moves no number, Saved moves the number, Not logged moves the pool), so any grouping invents a taxonomy. Wrapping is simpler.

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

**Fix my number page:** primary the amount and the question; secondary the preview (one fixed-height slot); on demand the large-higher second question.

**Spends:** primary the cycle and *Ask AI* card as today; secondary the Spent/Saved line (+ up to two parts); on demand Every entry with the new row kinds.

**Settings:** *Money* group gains the row at its end; *Savings* list rows gain a second line "₹4,000 set aside" and the footer a second line; the saving's sheet gains a balance line and *Used some of it* (outlined, mid-sheet, far from *Delete saving*).

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
  chart, Spent·Saved line                 chart, Spent·Saved [+ Used] [+ Not logged]
  Where it went                           Where it went (unchanged: new kinds excluded)
  See all > Every entry                   See all > Every entry; rows + Used, + Not logged; chips unchanged
Settings                                Settings
  Money: Money coming in, Bills,          Money: Money coming in, Bills, Savings,
    Savings, My month starts on             My month starts on, + Fix my number
    Savings sheet: amount, day, name        Savings sheet: + balance, + Used some of it (question inside the sheet)
    Savings list: rows, footer              Savings list: + "set aside" second line, + footer line 2
  Look, Categories, Your hisaab,          Look, Categories, Your hisaab (unchanged), Shortcuts
    Shortcuts
                                        + Fix my number page: modal route from Home foot row,
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
| SPEC FR-SP-4a | Up to four parts, fixed order, conditional, wraps between parts; *Not logged* is the Spent side only |
| SPEC FR-SP-6 | System categories get no chip |
| SPEC FR-SE-1 | *Fix my number* row at the end of *Money* |
| SPEC §2 glossary | *Used*, *set aside*, *Not logged*, "Fix my number" ("number" = the hero) |
| DECISIONS (next free IDs) | (a) Slot order: waiting, due-soon, install, missed-log; a lower line never appears mid-view. (b) Permanent *Fix my number* text row on Home, always except *No income*. (c) Settings home is *Money*, not *Your hisaab* (pending study A). (d) *Used* is discovered from Settings only, with a ladder and no Home banner. (e) Up to four parts on the Spends line |

## 9. Open questions

1. **Settings group:** *Money* (recommended) or *Your hisaab* (UX doc). Settle with study A.
2. **Foot row look:** a text row (recommended) or the UX doc's sunk row. `design-ui` to decide; the IA constraint is that it must not resemble the nudge slot.
3. **Got-side fix on the Spends line:** left to Every entry (recommended) or a fifth part? Owner to confirm that this meets "visible in Spends".
4. **Install line in over states:** waits (recommended, one next step) or shows?
5. **Saved-yesterday note and the missed-log line:** do both (recommended) or "one note a day"?
6. **Chips:** confirm whether a Savings chip exists today in Every entry.
7. **Used discovery ladder:** is rung 2 (a tappable *Saved* row) acceptable if the hallway test fails?

## Source scope
`docs/features/fix-my-number/01-ux-flow.md`, `02-accounting-and-edge-cases.md`, `docs/features/yearly-costs/01-ux-flow.md`, `docs/features/habits/08-missed-log-line.md`, case study 33 ("Design-product review", "Owner answers"), SPEC §2 glossary, BR-8, FR-HO-1 to 5, FR-SE-1, FR-SE-4, FR-SP-4a, FR-SP-6, UI_DESIGN §4 and §5.2, DECISIONS D21, D54, D131, D132, `lib/home/presentation/pages/home_page.dart` (build order of note and slot), `lib/spends/presentation/pages/entries_page.dart` (chips), `lib/l10n/app_en.arb` (Settings group keys). No code was changed.
