# 22. Custom spending categories with a custom icon

## Job
Let someone file a spend that none of the 8 fixed *Spent* tiles fits (Food, Travel, Shopping, Bills, Fun, Health, Home, Other; BR-11) under a name of their own, with an icon, **without** slowing the Add flow (Add → digits → Next → tile), moving a tile (D13), or adding colour (D10).

## Where hisaab stands
- **BR-11:** a fixed seed list and order. The user may **rename** a category or **change its icon**, and "Order and count are fixed in v1, so muscle memory survives." **FR-SE-2** (rename, change icon) is specified but not built.
- **D13:** categories, keypad and dock never reorder ("UPI users memorise positions; PhonePe 2025 backlash").
- **A related proposal already exists.** `docs/features/habits/05-tracked-items.md` (status: proposed) answers the same user request (cigarettes, alcohol, partying) with *tracked items*: up to 4 named tiles in a **third grid row**, each living inside a parent category so totals and limits stay correct. It uses the same row and the same cap of 4 as the IA and interaction proposal tested below. Both can't own that row (see *Conflicts*).
- **Proposals to test** (from the coordinator):
  - **IA and interaction:** up to 4 user-made *Spent* categories in a third row after the fixed 8, created from a "+ New category" chip in the Add tray (a name with suggestion chips, an icon auto-picked from the name, an optional 24-icon grid, and *Save* also files the entry), with hide or archive in Settings.
  - **Product lead:** rename and change icon only (FR-SE-2), and wait for evidence.

## Method
Desk and competitive research: help centres, open-source code (Cashew), community forums, App Store reviews, and HCI literature on spatial memory and icons. It's the cheapest method that can change this decision, because the open questions (where creation lives, what happens on delete, what users complain about) are documented in public. What it can't tell us is whether *hisaab's* users want this. Only interviews or a diary study can answer that (see *Open questions*).

**Limits of this pass.** A rate limit cut the first session short, so some apps rest on search summaries rather than opened pages, and every such claim is marked. Realbyte, BudgetBakers, Money Lover and Revolut help pages returned **403**. No Play Store review pages were read directly: WebFetch returns an empty page (`sources.md`), and the App Store pages that did load show only a handful of reviews. Mobbin wasn't used (login). **No screen recordings were made, so grid sizes are known only where code or help text states them.**

## Research by app

### Money Manager (Realbyte)
- **Where:** category management lives in Settings: *More › Configuration › Income / Expenses Category Management*. The entry screen's category picker has a pencil button that opens the same page. Subcategories are off by default and are switched on there ([Realbyte help, enable subcategory](https://help.realbyteapps.com/hc/en-us/articles/360042890154-How-to-enable-sub-category); 403 to the fetch tool, so this is from the search summary).
- **Icon picker, limits, delete:** no public source found. The help pages return 403, and no review describes them.
- **Complaint:** "When you have loads of categories like I do, the current UI can slow down your input … the entry section of things, such as the categories or the calculator gets a bit squished" (@Johntheone, 12 Nov 2025, [App Store](https://apps.apple.com/gb/app/id564730202)). One review, but it describes exactly the cost an uncapped grid puts on the entry screen.

### Wallet (BudgetBakers)
- **Where and what:** the main categories are fixed. The developer replied (4 May 2025) that users "can rename categories and add subcategories", suggested labels as a workaround, and said "the option to create custom colors or add your own icons is not available yet" ([App Store KZ](https://apps.apple.com/kz/app/id1032467659)). The US listing does advertise "Personalised category icons" and "Creating your own income/expense subcategories" ([App Store US](https://apps.apple.com/us/app/id1032467659)). The two conflict. The listing probably describes a premium feature (the search summary says so, but that wasn't verified).
- **Complaints:** "very few icons and very few colour choices" (Daniyar Uzaqbay, 1 May 2025). "I miss the ability to create my own spending categories. Not subcategories, but full-fledged categories" (Vova Say, 11 Jun 2023) ([App Store KZ](https://apps.apple.com/kz/app/id1032467659)).
- **Delete:** the help article ([BudgetBakers support](https://support.budgetbakers.com/hc/en-us/articles/7077082048146)) returned 403. The search summary says that deleting goes through the edit screen, and that a sub-subcategory which can't be deleted needs its records found by filter and recategorised first. Unverified.
- **Read:** this is the nearest live example of the product lead's option (rename only, no new main categories), and it draws "full-fledged categories" requests.

### Monefy
- **Where:** the listing says "add new categories or delete old ones" ([App Store](https://apps.apple.com/app/id1212024409)). No help pages were found on icons, merging or deletion.
- **Complaints** (an aggregator of App Store reviews, undated, [justuseapp](https://justuseapp.com/en/app/1212024409/monefy-money-tracker/reviews)):
  - **The visible slots are capped.** "If you add more than 14 categories, not all the pictures show on the main screen and you can't select which 14 show" (AmiLo222).
  - **Reorder:** "please let me move around the categories and adjust the home categories" (Xjx388).
  - **Icons:** "would be nice if there were additional icons" (Aeixx); "a more variety of more relatable icons" (Cyndeeyah).
  - **Praise:** "it was rather easy to add … custom categories" (Whome907).
- **Read:** a hidden overflow is worse than a cap. Users accept a limited home grid only if *they* control what's on it.

### Spendee
- **Where:** Settings: *More › Categories ›* Expense or Income, then **+**, then name, colour and icon, then save ([Spendee help, create a custom category](https://help.spendee.com/article/227-how-to-create-a-custom-category)). That's about 5 taps plus typing. The old support page also said categories can be added "while adding a new transaction" (search summary of `spendee.com/support`, which now redirects to the help centre, so this is unverified).
- **Icon picker, limits, delete:** none are described. The edit article covers only changing one transaction's category, and notes that Spendee learns after 4 or more identical corrections ([Spendee help, edit a category](https://help.spendee.com/article/212-how-to-edit-category)).

### YNAB
- **Where:** in the Plan's edit mode: *Edit Plan › +* beside the group header, then name and *Save*, about 4 taps plus typing. A new category appears at the top of its group ([YNAB, adding and removing categories](https://support.ynab.com/en_us/adding-removing-and-customizing-categories-a-guide-HJFO5j909.md)).
- **Icons:** none. Users type an emoji into the category **name** with the phone keyboard ([YNAB, emoji in your plan](https://support.ynab.com/en_us/how-to-use-emoji-in-your-plan-SJTNIyQAc.md)).
- **Order:** by drag in a separate *Reorder* mode.
- **Delete:** "It's not possible to leave transactions uncategorized." Deleting a category with activity requires picking a replacement, and **merging is done the same way**: delete the unwanted category and reassign its activity. YNAB **recommends hiding** a category once it has activity, and hidden categories can be unhidden ([same guide](https://support.ynab.com/en_us/adding-removing-and-customizing-categories-a-guide-HJFO5j909.md)).
- **Limits:** none stated.

### Copilot Money
- **Where (two ways):**
  - From the Categories tab: **+**, then start from scratch or from a default, then Regular or Excluded, then emoji, name, budget and colour, then Save.
  - From a transaction: tap its category, then **New**, then choose which transactions to include. The selected transactions take the new category on save ([Copilot help, creating new categories](https://help.copilot.money/en/articles/3763839-creating-new-categories)). **Creating a category also files the transaction**, which is the act the IA proposal's *Save* combines.
- **Icons:** an emoji (or Genmoji on supported iPhones) plus a colour ([quick start](https://help.copilot.money/en/articles/11157550-quick-start-guide)).
- **Delete:** "Any transactions associated with the deleted category get moved into the **Other** category automatically." *Other* can't be deleted ([Copilot help, Other category](https://help.copilot.money/en/articles/9829368-other-category)).

### Monzo
- **Where:** from a payment: "opening a recent payment and tapping the category for that payment." Each category gets "a name, icon and colour", and the user picks the scope: this payment, future payments from this merchant, or all of them ([Monzo help](https://monzo.com/help/monzo-max/advanced-budgeting-custom-categories)). Custom categories have been a paid-tier feature. On cancelling Plus, past transactions revert to defaults (community answer via search summary, [thread](https://community.monzo.com/t/do-i-lose-my-custom-categories-if-i-downgrade-from-perks-to-free/190472); not opened).
- **Delete:** "Existing items will keep their categories and will need to be changed" (tbutz, 20 Sep 2022). iOS users couldn't find delete at all: "looks like a bug" (AshleyP, 5 Jan 2023) ([community](https://community.monzo.com/t/deleting-custom-categories/138535)).
- **Clutter:** "a sea of ones I'm not interested in anymore", trip categories such as "France", so the user asked for **archive** to make assigning "more streamlined" (air1212, 15 Jan 2025, [community](https://community.monzo.com/t/archiving-custom-standard-categories/173731)). A later thread title, "How to unarchive a custom category?", suggests archive now exists (title only).
- **Demand before launch:** a "simple 'create category' button" with an icon chosen "from a list" (sharpbriar, 19 May 2019, [community](https://community.monzo.com/t/custom-categories/67824)).

### Cashew (open source, Flutter, so the closest stack to ours)
- **Where (both ways):**
  - The category selector used while adding a transaction has an **Add** button that opens `AddCategoryPage` ([`selectCategory.dart`](https://raw.githubusercontent.com/jameskokoska/Cashew/main/budget/lib/widgets/selectCategory.dart)). The file doesn't show whether the new category is auto-selected.
  - Categories can also be added from settings.
- **Icon picker** ([`selectCategoryImage.dart`](https://raw.githubusercontent.com/jameskokoska/Cashew/main/budget/lib/widgets/selectCategoryImage.dart)):
  - **Layout:** a flat, centred `Wrap` of 55px circles with no groups. Column count follows the window width.
  - **Size:** about 300–350 icons ([`iconObjects.dart`](https://raw.githubusercontent.com/jameskokoska/Cashew/main/budget/lib/struct/iconObjects.dart); estimated, not counted).
  - **Search:** matches a hand-written **tag list** of about 10 tags per icon. It's **English only**, because the field is hidden in other locales.
  - **Emoji:** an emoji option.
  - **"Suggest Icon":** "Can't find an icon you want? Suggest some and they can be added!"
- **Naming runs the other way round:** picking an icon fills the name field with that icon's `mostLikelyCategoryName` (for example, air hockey gives "Entertainment") if the name is still empty ([`addCategoryPage.dart`](https://raw.githubusercontent.com/jameskokoska/Cashew/main/budget/lib/pages/addCategoryPage.dart)). So Cashew goes **icon → name**. No app was found that goes **name → icon**.
- **Order:** drag to rearrange in the selector when `allowRearrange` is on.
- **Delete destroys entries.** "Deleting a category will delete all transactions in this category. Move transactions to another category to avoid this." **Merge** is offered instead: "This will transfer all transactions to the new category and erase the old category" ([`en.json`](https://raw.githubusercontent.com/jameskokoska/Cashew/main/budget/assets/translations/generated/en.json)).

### Others with evidence
- **BudgetFlow:** deleting a category also deleted its transactions. Users asked for the choice to delete, keep uncategorised or reassign, and it was marked *Completed* in March 2024 ([feature board](https://budgetflow.featurebase.app/p/being-able-to-remove-a-category-without-deleting-all-transactions)).
- **Money Lover:** offers merge from the category's edit screen, and the merge **can't be undone** ([help](https://moneylover.zendesk.com/hc/en-us/articles/33742206448793-Create-edit-delete-and-merge-categories); 403, so this is from the search summary). Its blog post "Merging categories is back" now redirects to the help home.
- **Revolut and PocketGuard:** deleting reassigns past transactions to the previous or original default ([Revolut help](https://help.revolut.com/help/accounts/budget-and-analytics/how-to-create-and-manage-custom-categories-for-transactions/), 403; [PocketGuard](https://pocketguard.com/help/adding-your-own-categories); both from search summaries).
- **Jupiter (India):** categories are fixed, and tags are the workaround: "Since the categories are limited to users, we've introduced tags … You can create as many custom tags as you want" (staff, [community](https://community.jupiter.money/t/able-to-add-custom-categories-to-track-your-spends/40873)).
  - **The requests keep coming:** custom-category threads date from Sep 2021, Dec 2021, Dec 2022, Apr 2023, May 2023 and Feb 2025 ([2025 thread](https://community.jupiter.money/t/enhancing-expense-categorization-multi-category-transactions-custom-categories/54482)).
  - **Why users want them:** without them, spends are "categorised to closest possible match", which makes insights less meaningful (Yagnesh, [tags vs custom category poll](https://community.jupiter.money/t/spend-categorization-tags-vs-custom-category/45805), May–Jul 2023; vote counts not visible).
  - **Tags fail on spelling:** "If any spelling error occur it will become new tag" (same thread, via search summary).
- **axio (formerly Walnut):** release notes list "custom categories, tags" ([APKMirror](https://www.apkmirror.com/apk/axio-digital-pvt-ltd/axio-expense-tracker-bnpl/axio-expense-tracker-bnpl-8-6-0-release/); via search). No screen-level material was found. The Yellow Slice teardown doesn't cover categories ([Yellow Slice](https://www.yellowslice.in/blog/axio-app-review-by-yellow-slice-how-to-make-it-better)).
- **Google Pay and PhonePe:** no public source shows user-made categories in either app.
  - **Google Pay:** its 2026 *Ask Google Pay* answers spending questions with a category pie chart, which is read-only (press, via search: [tech2](https://www.tech2.com/apps/google-pay-gets-a-gemini-powered-chatbot-for-spending-insights-in-india-text-10240689.html)).
  - **PhonePe:** the help pages don't load to fetch (`sources.md`). Its redesign story says the most common actions were kept "exactly where they've always been", because better flows "could feel worse if they break those anchors" ([design.phonepe.com](https://design.phonepe.com/stories/behind-phonepe-redesign); via search summary). That's the basis of D13.
  - **Read:** **Indian UPI users are used to categories being assigned for them, not to making their own.** That's an inference from the absence of a feature, so low confidence.

### Research on positions and icons
- **Spatial memory:** relocating interface items harms performance, because people fall back from spatial memory to visual search. Stable layouts let experienced users go straight to a location ([Scarr, Cockburn, Gutwin & Bunt, CommandMaps, CHI 2012](https://hci.cs.umanitoba.ca/publications/details/improving-command-selection-with-commandmaps); [Scarr, Cockburn & Gutwin 2012 monograph](https://unpaywall.org/10.1561%2F1100000046); both via abstracts and search summaries). **Adding tiles is safe only where it moves no existing tile.**
- **Icons:** "A user's understanding of an icon is based on previous experience". Few icons are universal, and labels should be always visible ([NN/g, Icon usability](https://www.nngroup.com/articles/icon-usability/)). In hisaab the word always carries the meaning, so a slightly-off icon costs little.
- **Icon set size:** the free Hugeicons package has "over 6,000+ stroke-rounded" icons, with no tag or keyword metadata on pub.dev ([pub.dev](https://pub.dev/packages/hugeicons)). Name → icon matching would need our own keyword map, as Cashew wrote one tag list per icon.
- **A complaint about large sets:** "so many icons that look very similar to each other" makes a picker "cluttered" (a feedback board for another app, via search summary, [timesince](https://timesince.userjot.com/board/p/simplify-and-categorize-icons); anecdotal).

## Patterns compared

| App | Create from the add flow? | Taps (from settings) | Icon picker | Count cap | Order | On delete |
|---|---|---|---|---|---|---|
| Money Manager | Pencil in picker opens settings | ~4 + typing (est.) | Not found | None found | Not found | Not found |
| Wallet | No (renames only; no new main categories) | n/a | "Very few icons" | Fixed mains | Fixed | Recategorise first (summary) |
| Monefy | Not found | Not found | Small set; "more icons" asked | 14 shown on main screen; rest hidden | Asked for, not given | Not found |
| Spendee | Yes (summary, unverified) | ~5 + typing | Not described | None stated | Not found | Not found |
| YNAB | No | ~4 + typing | Emoji in the name | None stated | Drag mode | **Must reassign**; hide recommended |
| Copilot | **Yes, and it files the transaction** | ~5 + typing | Emoji / Genmoji + colour | None stated | Not found | **Moves to Other** |
| Monzo | **Yes, from a payment** | n/a | Icon + colour list | None found | Not found | **Entries keep the deleted category**; archive asked for |
| Cashew | **Yes, Add in the selector** | ~3 + typing | ~300+ icons, flat grid, English tag search, emoji, icon → name | None | Drag | **Deletes entries** (warns); merge offered |
| Jupiter | No (tags instead) | n/a | n/a | Fixed | Fixed | n/a |
| GPay / PhonePe | No user categories found | n/a | n/a | Fixed | Fixed | n/a |

### What works
1. **Create at the moment of need.** Copilot, Monzo and Cashew (and Spendee, by the summary) let people create a category from the item being filed. Copilot's flow then files it in the same save. The demand quotes are all about that moment: "closest possible match" (Jupiter) and "not suitable for me" (Monzo).
2. **Hide, don't destroy.** YNAB recommends hiding a category once it has activity, and Monzo users asked for archive because they had too many to pick from.
3. **A fallback that can't be deleted.** Copilot's *Other* catches entries, and hisaab already has *Other*.
4. **Labels carry meaning; icons help.** YNAB has no icons at all and works. NN/g says labels are needed anyway.

### Failures to avoid
1. **Deleting entries with their category** (Cashew; BudgetFlow until users pushed back) and **merges that can't be undone** (Money Lover). Both conflict with D4 (Undo, no confirmation dialogs).
2. **Overflow that hides tiles the user didn't choose to hide** (Monefy's 14), and **an entry grid that cramps as categories grow** (Realbyte).
3. **Orphaned categories:** Monzo keeps entries on a deleted category, then "will need to be changed" by hand.
4. **Too few icons, or icons that don't fit the user's world**, is the most common review complaint (Wallet, Monefy). Hundreds of similar icons is the opposite failure.
5. **Tags as a substitute** (Jupiter): spelling splits tags, and tags don't feed the breakdown people want.
6. **Search that works in one language only** (Cashew). hisaab plans Hindi.

## Testing the two proposals against the evidence

| Question | What the evidence says | Confidence |
|---|---|---|
| **Is there demand beyond rename?** | Yes, persistent across apps: Wallet's "full-fledged categories", Jupiter threads from 2021–2025, and Monzo before its launch. Every source is a self-selected forum or review, though, and none is from hisaab's users. Rename-only (Wallet) draws exactly these requests. | Medium |
| **A cap of 4** | No app publishes a cap. The evidence is on the cost side: Monefy's hidden overflow, Realbyte's cramped entry, Monzo's "sea" of old categories. A cap that **keeps every tile visible** and **adds without moving** fits that evidence and the spatial-memory research. The number 4 comes from one grid row, not from data. | Medium for "cap and never hide"; low for "4" |
| **Create in the add flow, or in Settings?** | The apps users praise create from the item being filed, and Copilot files it in the same save. But a chip in the Add tray is a new control on hisaab's most guarded screen (CLAUDE.md: "Never add a tap or a field"). It adds no tap to the normal path, only an option. Settings-only creation (YNAB, Spendee) works but separates need from act. | Medium for in-flow; a hisaab rule to weigh |
| **Auto-picked icon from the name** | **No precedent found.** Cashew does the reverse (icon → name) and needs about 10 hand-written tags per icon. With the word always shown (NN/g), a wrong guess is cheap and an optional grid fixes it. It needs our own keyword map, in English and Hindi. | Low; needs a blind read |
| **A 24-icon grid** | Small sets draw "more icons" reviews (Wallet, Monefy). Huge sets draw "cluttered" and need search (Cashew, and only in English). 24 is defensible for a 5-year-old bar if the auto-pick usually lands. Expect "more icons" requests. | Low |
| **Hide or archive in Settings, not delete** | Supported: YNAB's recommendation, Monzo's archive request, and the data-loss failures (Cashew, BudgetFlow). It matches D35 (deactivate, Undo, past entries stay linked). | High |
| **Merge** | Only power-user apps offer it, and it's irreversible in some (Money Lover). Not needed if hiding keeps entries intact. | Medium |

**Verdict: the evidence supports the IA and interaction direction more than "wait for evidence", with four changes and in sequence.**
1. **Ship FR-SE-2 first.** It's specified, adds nothing to the Add tray, and lets someone turn *Fun* into *Cigarettes* today. It's the cheapest test of demand: if people rename *Other*, that is the signal.
2. **User-made tiles only append, never move:** a third row of at most 4, shown only once the first exists. An empty slot stays blank, and no seeded tile moves.
3. **Hide, never delete.** A hidden category's entries keep it, and Spends and the history still show its name. Undo, no dialog. No merge in v1.
4. **The icon is auto-picked from the name with an *Other*-style fallback glyph.** The grid is optional, and the auto-pick is checked by a blind read before building.

**The product lead is right that hisaab-specific evidence is missing.** The demand evidence comes from other apps' forums. The open questions below hold the cheap checks.

## Conflicts (for `design-product`; `DECISIONS.md` wins until changed)
- **BR-11** "Order and count are fixed in v1": a third row changes the count. D13's *order* is kept if tiles only append.
- **CLAUDE.md, Entry speed** "Never add a tap or a field": a "+ New category" chip adds a control to the Add tray, though not a tap to the normal path. The owner must rule on it.
- **`docs/features/habits/05-tracked-items.md`** proposes the **same third row and the same cap of 4** for tracked items inside a parent category. Custom categories and tracked items are two answers to one request (cigarettes, alcohol, partying). Pick one model for the row, or the grid grows to 16.
- **D10:** no colour picker. Every app studied pairs icon and colour, and hisaab mustn't.
- **D123:** a hidden card-bill category already exists. User-hidden categories need to stay distinct from system-hidden ones.

## Principles (proposed for `principles.md`; not appended, per this task's brief)
- **A category's entries outlive the category.** Retiring a category hides it; its entries keep their name and count. Never delete entries with a category, and never merge without Undo. *Sources:* Cashew `delete-category-merge-warning`; BudgetFlow board; YNAB "hide" guidance; Copilot *Other*; Money Lover (no undo). *Applies to:* categories, tracked items, bills (D35).
- **What users add goes after what's fixed, in a capped space where everything stays visible.** New tiles append to the end and never shift, hide or reorder existing ones. Cap the count so the grid never scrolls or cramps. *Sources:* Scarr et al. 2012; Monefy's 14-tile overflow; Realbyte's "squished" entry; D13. *Applies to:* the Add grid, the dock, any user-extendable set.
- **Make a thing where it's needed, and finish the job in the same act.** Creating a category from the entry being filed should file that entry too. *Sources:* Copilot's create-from-transaction; Monzo; Cashew's selector Add. *Applies to:* categories, bills, tracked items.
- **The word names it; the icon only helps.** Never require an icon choice: suggest one from the name and let the user change it. A wrong icon beside the right word costs little; a missing word costs a lot. *Sources:* NN/g, Icon usability; YNAB (no icons); Cashew's icon → name pairing. *Applies to:* category creation, bills (icons from the name, case study 16).
- **Rename before you extend.** Let people repurpose a fixed slot before adding new ones; how much renaming happens is the cheapest measure of demand. *Sources:* Wallet (rename-only, and its complaints); BR-11 / FR-SE-2. *Applies to:* categories, any fixed set.

## Open questions
1. **Does anyone need more than 8?** Ask 5 UPI-first users (Mom Test): "Tell me about the last spend you didn't know where to put." Count how often *Other* is used in a 2-week diary across payday. Use on-device counts that the user sees and shares; never telemetry.
2. **Custom category or tracked item?** Run a card sort with 5 users. Is "Cigarettes" its own pile or part of "Fun"? This decides which model owns the third row.
3. **Does the auto-picked icon land?** Do a blind read: show 12 typed names with their auto-picked Hugeicons glyph and ask "what is this for?". Then check the Hindi names.
4. **Is 24 icons enough?** In a 5-user think-aloud, task "make a category for your gym": measure success, time and SEQ, and note any "is there a … icon?".
5. **The chip in the Add tray or the Settings route:** a usability round comparing first-time discovery of both, on a low-end Android at 1.5× text.
6. **Not read and worth a browser session:** Realbyte, BudgetBakers, Money Lover and Revolut help (403); Play Store reviews for Money Manager, Monefy and axio; Mobbin flows for Spendee and Monefy's icon pickers.
