# Platform review: Fix my number, Used and the missed-log line (Android, adaptive)

> **Status: signed off 2026-11-13 (`08-design-qa-and-signoff.md` §8; this review wins over `04` on layout, back and tabletop, X5, X6, X9, X10, X46).** Not in SPEC, PLAN, UI_DESIGN or DECISIONS yet, and no code was changed; SPEC wins once written. Owner: `design-platform`. Covers `01` to `05` of this folder, `docs/features/yearly-costs/01-ux-flow.md`, `docs/features/habits/08-missed-log-line.md` and mockups 41, 42, 43.
>
> **How it was checked.** Code was read (`lib/app/routes.dart`, `lib/settings/presentation/pages/bill_sheet.dart`, `bill_amount_sheet.dart`, `add_entry_tray.dart`, `lib/core/layout/`, `lib/core/widgets/adaptive_split.dart`, `app_shell.dart`, the snackbar host, `home_bloc.dart`, and the `ModalBottomSheetRoute`, `ModalBarrier` source in `material_ui` 1.11). A **throwaway widget test** (since deleted) opened the existing bill sheet's *Amount* question at the `TestWindows` sizes and measured it; numbers marked "measured" come from it. Numbers marked "estimate" are mine and need a real test with the new widgets. Nothing was run on a device, so foldable behaviour is from the framework source, not seen.

## 1. How the bill-sheet route lays out today

`BillSheet.route` is a `ModalBottomSheetRoute` shared by the bill sheet, *Bill amount* (FR-HO-8), *Put in extra*, *Money coming in* and the reminder asks. `AddEntryTray.show` builds the same kind of route with the same settings.

| Setting | Value | Effect |
|---|---|---|
| `isScrollControlled` | true | Sheet may be as tall as the window (minus the top inset) |
| `useSafeArea` | true | Wraps in `SafeArea(bottom: false)`: top, left, right insets only. **No bottom inset** |
| `constraints` | max 560dp wide (unbounded in tabletop) | Centred, bottom-anchored. 560dp is `AdaptiveSplit.readableWidth` |
| `anchorPoint` | `Offset(0, windowHeight)` in tabletop, else null | Picks the sub-screen (see below) |
| `showDragHandle` | true, false in tabletop | The handle takes **48dp** (measured: content starts at y=48 in every window) |
| Body | `SingleChildScrollView` around the whole question, **keypad included** | Nothing is pinned; the amount scrolls away with the rest |

Folds: `DisplayFeatureSubScreen` (framework, in `buildPage`) confines the sheet to one side of a fold. With `anchorPoint` null and left-to-right text it takes the left or top sub-screen. So the sheet never straddles a fold, but nothing in the sheet knows which side it got.

| Window | What happens today |
|---|---|
| Compact, tall (412×915) | Full width, bottom-anchored, does not scroll for the *Amount* question |
| 320×568 | **Measured:** content is 578dp in a 520dp viewport (max scroll 58). At scroll 0 the *Save* key is at y 546 to 606, **below the 568dp window**. At 1.5× text: max scroll 171 |
| 412×400 (E18) | **Measured:** viewport 352, content 578, max scroll 226. Keypad top at y 286, so 114dp of it shows; *Save* is at 546. To reach the keys' lower rows the amount scrolls off screen |
| Phone landscape 915×412 (expanded width, compact height) | Sheet is 560 wide, centred over both panes. **Measured:** viewport 364, max scroll 206. The Add tray goes side by side here; the bill-sheet route does not |
| Medium (673×841) | 560 wide, centred, 570 tall, no scroll (measured) |
| Expanded two-pane, no fold (1280×800, 841×701) | The window is two panes (Home 360 to 480dp wide, then Spends) but the sheet is not pane-aware: **centred, 560 wide, over both** (1280: x 360 to 920; Home pane is 0 to 480, so it covers the right 120dp of Home). Same as the Add tray. Measured at 1280×800: 570 tall, no scroll |
| Book (vertical fold, window 600dp or more) | Sheet in the **left sub-screen**, which is Home's pane. Never crosses the fold. Not measured (needs a fold) |
| Tabletop (horizontal half-open fold) | `anchorPoint` puts it in the **lower** half, no handle, **unbounded width**, so the keypad's `Expanded` keys stretch across the half (about 660dp, keys 210dp wide). One scrolling column in a 421dp half (content 578): the amount scrolls away. Not measured |
| Posture or size changes while the sheet is open | `tabletop`, `constraints` and `showDragHandle` are read **once** when the route is built. Open flat, then half-fold: `anchorPoint` is still null, so the sheet goes to the **upper** half. The Add tray has the same flaw (D29) |

**Existing defects the three features inherit** (none caused by them):

1. **No bottom inset.** Measured with a 48dp bottom padding at 412×915: *Save* ends at y 895 of 915, the 20dp gutter and nothing else. A 3-button bar (48dp) overlaps the lower 28dp of the key; the gesture pill (about 24dp) overlaps 4dp. `AddEntryTray` is fine because `AdaptiveSplit` has a `SafeArea`; the bill-sheet body has none.
2. **Keypad scrolls with the body** (above). Mockups 41 and 42 found the same thing at 320×568 and 1.5×; it is true at 1× too, and for the screen that exists today.
3. **The drag handle is 48dp, not 16 to 20.** Mockup 42's "about 534dp" Used budget used 16dp for the handle; with 48 the existing *Amount* question already does not fit 568dp (measured, above). Mockup 41 used "handle area 20". Both mockups under-count by 28 to 32dp.

## 2. Does the Fix my number sheet fit it?

Sheet content needed (estimate, from the measured 578dp *Amount* question: 238dp above the keypad, 248 keypad, 12 gap, 60 key, 20 bottom): Fix my number swaps the slip for a two-line title, the amount and a 3-line slot, about 212dp above the keypad, so **about 552dp of content plus the 48dp handle = about 600dp**. The *Used* question adds a 3-line slot and the *All of it* chip row to a slip-sized header: **about 690dp**. At 1.5× text, add roughly 130 to 170dp (measured +113 on the existing question).

| Window (height available after the 48dp handle) | Fix sheet (~552) | *Used* (~640) | Verdict |
|---|---|---|---|
| 412×915 phone, 673×841, 1280×800, 841×701 | fits | fits | OK, no scroll |
| 320×568 (about 520) | short by about 30 | short by about 120 | **Breaks.** *Fix it* is below the window at scroll 0; scrolled, the amount is off screen |
| 320×568 at 1.5× | short by about 190 | short by about 280 | **Breaks badly** |
| 412×400 split-screen (352) | short by about 200 | short by about 290 | **Breaks.** Mockups 41 and 42 are right |
| 915×412 landscape (364) | short by about 190 | short by about 280 | **Breaks** |
| Tabletop lower half (421, no handle, minus inset) | short by about 130 | short by about 220 | **Breaks** without a side-by-side arrangement |

So the container choice in `04` §1 (a sheet in the bill-sheet route) is sound, but **the route's body cannot host it as it is**: the keypad, the typed amount and the action key must stay on screen at every size, and today none of them is pinned.

## 3. Proposed layout by window class

One rule set for the Fix sheet (keypad step and guard step) and the *Used* question. All of it is **content-driven** (what fits), read through `context.layout` and the sheet's own constraints, never device or raw `MediaQuery` widths. The Add flow is untouched.

**Parts.** `lead` = title row. `figure` = amount well. `slot` = the preview slot (fixed height by its `IndexedStack`, `04` §3). `controls` = keypad and the action key (*Fix it*, *Save*), or the guard's two keys. For *Used*, the *All of it* chip rides beside `figure`.

**Rules.**
1. **`controls` are always pinned**, and so is `figure` unless the scroll region would drop below 96dp (below).
2. **`lead` and `slot` scroll** between them in the space left. The first key typed scrolls the slot into view (`Scrollable.ensureVisible`, 150ms, zero under reduced motion), so the user sees the reason, and the amount stays visible above the keypad. This is the mockup 41 recommendation, adopted.
3. **Keys are 56dp** (`BillAmountQuestion._keyHeight`; `04` §2 and §7 now say 56, X2), **48dp** (`minTouchTarget`) in a short window or side by side. **The action key is 56dp (48 short) but unmeasured:** the sources say 56 (mockup 41), 60 (the probe) and "68 including the gap" (mockup 42). Re-measure it in the build.
4. **Pinned bottom padding = gutter + `MediaQuery.paddingOf(context).bottom`**, so the key clears the gesture bar and a 3-button bar (§6).
5. **Stacked unless it cannot be (X5).** Pinned parts at 56dp keys: about 48 (handle) + 64 (amount) + 248 + 12 + 56 + 20 = **about 448dp** (the action key is 56dp, X2: re-measure it in the build; 56 versus 60 is not argued on paper). At 568dp that leaves about 116dp (less the status bar) for `lead` plus `slot`: enough for the slot at 1×. **Stacked with the pinned amount at every width under about 560dp.** A 320dp window cannot hold a 220dp keypad pane beside a readable header pane (about 60dp left), so the 96dp "scroll region" rule is **what the slot scrolls inside**, not a trigger for panes below 560dp. **Side by side** only for width of 560dp or more with a short height (landscape; 412×400 split-screen is borderline: test it), or in tabletop. Measure, then tune the 96.
6. **Side by side** is `AdaptiveSplit(fullWindow: false, sideBySide: true)`, as the Add tray does. `AdaptiveSplit` scrolls the whole header today, so it needs a way to pin `figure` inside the header pane (a small addition to `AdaptiveSplit`, to be decided with `design-system`). The controls pane is at least 220dp wide (keys about 68dp).
7. **The guard replaces the controls** (`04` §4) in the same pane, vertically centred in it; the keys stay 56dp. The sheet may shorten for the guard (mockup 41 problem 2): shorter is fine, since nothing is pinned to the old height.

| Window class and posture | Arrangement | Notes |
|---|---|---|
| **Compact, tall** (412×915) | Stacked, no scroll | As the phone mockups |
| **Compact, small** (320×568, 1× to 2×) | **Stacked at every width under about 560dp (X5)** with `controls` and `figure` pinned; `lead` and `slot` scroll inside the remaining region. Key labels clamp at 1.5× (O20), so at 2× the keypad is 4×56 + 24 = 248dp | The earlier "side by side at 1.5× and always at 2×" is withdrawn: 320dp cannot hold two readable panes. Test 320×568 at 1×, 1.5× and 2× |
| **Compact, short** (412×400, split-screen 1/2 and 1/3, E18) | Side by side, 48dp keys | Controls 220dp, header the rest (about 150 to 170dp): the slot wraps long and scrolls under a pinned amount. At 1/3 (about 300dp tall) the same, scroll more |
| **Landscape phone** (915×412, expanded width, compact height) | Side by side in the 560dp sheet (280 each) | The sheet stays centred over both panes. Cutouts: the route's `SafeArea` handles left, right, top |
| **Medium** (673×841, flat) | Stacked, 560 wide, centred | No change from the phone |
| **Expanded two-pane, flat** (841×701, 1280×800) | Stacked, 560 wide, centred over both panes, as the Add tray | **Reject mockup 41 §8's amount-and-slot pane beside a keypad pane here.** The height (about 750) holds the 552dp stack; two 280dp panes would wrap the slot more, not less. Side by side only by rule 5 |
| **Book** (vertical fold) | Stacked in the left sub-screen (Home's pane), as the route already does | Sub-screen can be 320 to 420dp wide: test 320. Hinge gap: handled by the sub-screen |
| **Tabletop** (horizontal half-open) | **Whole sheet in the lower half** (D29), side by side: amount and slot left, keypad and key right, no handle needed | **Mockup 41 §8 draws the title, amount and slot in the *upper* half. That cannot be built with a sheet** (a sheet sits in one sub-screen); it would need a full-window page. D29's arrangement leaves Home (the hero that changes) readable above the fold, which is the point. Lower half is 421dp (701×841 case): keypad 4×48+24 = 216, key 58, gaps and padding about 340, so it fits |

**Live changes (E16, E17).** Digits, step and notice live in the bloc and survive. Make the route posture-agnostic so a fold during use does not strand the sheet: pass `anchorPoint: Offset(0, windowHeight)` always (flat: no fold, no effect; book: x=0 is the left sub-screen, as today; tabletop: lower), `constraints` max 560 always (also in tabletop: a 560dp column centred in the lower half is better than stretched keys), and keep the handle (it costs 48 of the 421dp). The widgets read `context.layout` inside `build`, so they re-lay out live. Same fix applies to `AddEntryTray` (D29) if the owner wants it; not part of this change.

**Used question** is the same arrangement, inside the saving's sheet. The swap from slip to keypad (`05` §3) changes the sheet height; the pinned layout makes that a content change, not a window-size problem. Keep the stamp from replaying (`05` §3).

## 4. Back, the guard, saving, scrim and swipe

Verified in source, not assumed:

- `ModalBarrier` (scrim) calls `Navigator.maybePop`: it **respects `PopScope`**.
- `BottomSheet` swipe-down, the drag handle and the handle's TalkBack "dismiss" call `onClosing`, which does `Navigator.pop(context)` (`material_ui` `bottom_sheet.dart` around line 783): it **bypasses `PopScope`** and closes the whole sheet.
- Escape and system back go through `maybePop`, so they respect `PopScope`.
- **`ModalBottomSheetRoute` has no back-gesture preview.** `material_ui` 1.11 `bottom_sheet.dart` has no `handleStartBackGesture` or predictive-back hook; the theme's `PredictiveBackPageTransitionsBuilder` covers page routes only. `enableOnBackInvokedCallback` is on in the manifest, but nothing animates a sheet while the gesture is dragged.

| Exit | Keypad step | Guard step | After *Fix it* or *Yes* pressed, saving |
|---|---|---|---|
| System back, Escape | Closes, nothing saved, digits dropped | Step back to the keypad = *No*: digits kept, S7 notice, focus to ⌫ | **Closes** the sheet; the save still lands |
| Scrim tap | Same as Back | **Same as Back = *No*.** `04` §4 says the scrim closes the sheet here; with `PopScope` holding it, it does not | Closes |
| Swipe down, drag handle | Closes | **Closes the whole sheet**, nothing posted, digits dropped | Closes |

Required for this to be right:

1. `PopScope.canPop = (step is keypad) || saving`. While saving, Back must close, not step back to a keypad under a running write. The guard step is `canPop: false` only while no save runs.
2. **Predictive back stays honest by not promising a preview.** There is nothing to preview or cancel: a started and abandoned back gesture changes nothing and fires no callback. `04` §4 ("predictive back previews the keypad step"), `05` §2 and §7 F6 and UI_DESIGN §10 ("A back swipe scales the tray down") should say instead: **back commits; the sheet then plays its normal exit, or the 150ms crossfade from guard to keypad.** F6 is therefore settled: not possible with this route, and not needed. When Flutter's sheet route gains a preview it will work off the same `canPop`, so rule 1 keeps it correct. Never flip `canPop` mid-gesture (the only flip is the guard entering, a tap).
3. **Back while writing needs the outcome after the write.** `BillSheet.show` reads `bloc.state` once at `route.completed`, so a write that lands later is reported as unchanged and its Undo is lost. `BillAmountSheet.show` already does this right (it waits on `bloc.stream` for a settled state, then closes the bloc: SPEC FR-HO-8 AC-6). **The Fix my number and *Used* `show` methods must copy that pattern, not `BillSheet.show`.** The bloc must not be closed by the sheet's `BlocProvider(create:)` while the write is in flight; use `BlocProvider.value` and close it after the wait, as `BillAmountSheet` does.
4. **Accidental Back loses the digits.** A back swipe starts at the screen edge, and the keypad's outer keys sit 20dp in, so a sliding thumb can trigger it. This matches the Add tray's step 1 and FR-HO-8 AC-1, and a re-type is a few taps, so no dialog (reversibility over confirm). Recorded, not changed. Flag for the owner only if the blind read shows lost digits.
5. Fix `04` §4 and §8: scrim at the guard = Back; swipe and handle = close.

## 5. The F1 hold (confirmed) and what the route must send

**Confirmed from code.** `HomeBloc` holds numbers only between `HomeTrayOpened` and `HomeTrayClosed` (`home_bloc.dart` `_trayOpen`; `_onLoadRequested` defers while it is set). The only sender is `AppRoutes.openAddTray` (`routes.dart` lines 518 and 520). `openBillSheet`, `enterBill` and `BillSheet.show` send nothing. A write reaches Home through `ledger.changes` and `recurring.changes`, which dispatch `HomeLoadRequested` at once, so Home reloads **under the closing sheet and scrim**: the exact bug D91 fixed for Add. **This already applies to FR-HO-8 (`enterBill`) today**, not only to the proposals.

**The route must send, for every door whose sheet is over Home:**

| Door | Over Home? | Hold |
|---|---|---|
| Home foot row, install line (Fix my number) | yes | send |
| Home due-soon row (`onOpenBill`: bill edit, and *Used* on a saving) | yes | send (the *Used* row grows in and the due-soon row changes: both want the hold) |
| Waiting bill (`enterBill`, also the reminder tap) | yes | send (fixes today's FR-HO-8 behaviour) |
| Settings row (Fix my number), Settings > Savings > *Used*, Bills list sheets | **no**: Home is under a full `MaterialPageRoute` | do not send |

**How.** `Opened` before pushing the sheet; `Closed` after `route.completed` (the exit has ended, as `AddEntryTray.show` documents), in a `finally` so a thrown error cannot leave Home frozen (`openAddTray` has no `finally` today). One helper in `routes.dart` wrapping the three Home-door calls. **Do not call it from `bills()` or `settings()`**: those pages are built inside a `MaterialPageRoute`, a child of the `Navigator`, so `context.read<HomeBloc>()` would not find the bloc (this is why `onOpenSettings` captures `home` and `habits` before it pushes).

**Back while writing:** send `Closed` at `route.completed`, not after the write settles. The write then lands with Home in full view and plays its roll, which is right.

**Needed change in `HomeBloc`: a counter, not a flag.** `_trayOpen` is a bool. Two paths overlap two holds: `followLaunch` and `_openReminded` call `Navigator.popUntil` and then open another tray or sheet at once. The exiting sheet's `Closed` arrives after the new one's `Opened`, so the flag clears while a tray is open and Home reloads under the Add tray. Today this only matters for a bill sheet if one wraps; once all sheets hold, it is a real race. Use `_holds++`/`_holds--` (floored at 0) and reload at 0.

**Two-pane: is the hold right?** Yes. The scrim covers both panes, so Home's hero (left pane, top) is on screen behind it with only the lower right of its card under the sheet (1280: x 360 to 480, below the sheet top). The drain or roll after the exit is seen exactly as on a phone; the D91 reason is unchanged. The Spends pane has no hold and teaches nothing, but it probably reloads under the scrim too (`SpendsBloc` takes the ledger). The Add tray already does the same; accept. **Open visual check:** at 1280×800 the Fix sheet is about 650dp tall (top at about y=150), so it overlaps the hero's lower right. If the hero's figure is covered, anchor the sheet over the secondary pane in the expanded class; otherwise keep it centred like the Add tray (preferred: one placement to learn).

**Tabletop and book:** the hold is right in both: Home is in the upper half (tabletop) or the pane beside the sheet's sub-screen (book).

**Settings door and the snackbar (not in `04`/`05`).** Home's `HisaabSnackbarHost` is under Settings, so a "Fixed. Safe to spend today: ₹963." posted through `HomeBloc` is **not visible** and its 4s timer runs out before the user returns. `SettingsPage` has its own host (line 76), but it has no `HomeBloc` and no Undo path for a ledger entry. `04` §5 step 3 says "the snackbar carries the value" from Settings; that needs either (a) a bloc inside the Settings route that owns the Undo (the existing `IncomeBloc` scope is the nearest), or (b) the closure-captured `HomeBloc` plus a pending Undo that Home shows on return (the D127 pattern, but then the 4s window starts late). Recommend (a). **Blocking for the Settings door, not for the Home door.**

## 6. Edge-to-edge, insets, keyboard, cutouts

| Item | Finding | Fix |
|---|---|---|
| Bottom inset | Missing in the bill-sheet body (§1, measured) | Pinned `controls` add `MediaQuery.paddingOf(context).bottom` to the gutter. Via `AdaptiveSplit` this comes free (it has a `SafeArea`). Keep the sheet's background running behind the bar (edge-to-edge) |
| Pinned *Fix it* / *Save* over the gesture bar | See above: 4dp overlap with the 24dp pill, 28dp with a 3-button bar | Test at padding 24 and 48 |
| Keyboard (IME) | The Fix and *Used* sheets have **no text field**, so no IME appears. `BillSheet` still adds `viewInsets.bottom` for the name question; a hardware keyboard adds none | Nothing to add. Do not add a field (a note, say) to either sheet without revisiting this |
| Cutouts | The route's `SafeArea` covers top, left, right; panes use `Pane`'s edge-aware insets (UI_DESIGN §13) | Landscape cutout test at 915×412 |
| Back-gesture edge | See §4 item 4 | None |
| Low-end (Android Go, 2 to 3GB, 720p) | The slot is an `IndexedStack`: every state is laid out each frame (about 9 short texts) | Acceptable. Cross-fade with `FadeTransition`/`AnimatedOpacity` on the two children, not an `Opacity` over the stack |

## 7. The foot row, the missed-log line and the snackbar in two-pane, tabletop and book

How Home sits: single pane, a `Column` of `Expanded(Home)` over the dock. **Two-pane:** Home in the primary pane (360 to 480dp wide) over the marigold Add key, Spends beside it. **Tabletop:** Home in the upper pane, the dock in the lower. **Book:** Home in the left pane. `HomePage` owns one `HisaabSnackbarHost(bottom: 0)`, so the bar's bottom edge is the bottom edge of Home's viewport.

| Item | Single pane | Two-pane | Tabletop | Book |
|---|---|---|---|---|
| Foot row (end of Home's scroll) | Above the dock | Above the Add key, inside Home's pane (the `Pane`'s `SafeArea` consumes the inset, so the list is not padded twice) | Above the fold, end of the upper pane | In Home's pane |
| Snackbar | Rises above the dock, covers the foot row and last Today row for 4s (or until dismissed with TalkBack) | **Sits on the Add key's top edge**, 20dp in from the pane edges: 320 to 440dp wide, so the 2-line copy and a 48dp *Undo* fit. It never covers the Add key | Sits **just above the fold**, inside the upper pane: does not straddle it | In Home's pane |
| Missed-log line (56dp+ row in the nudge slot) | Under the hero | In Home's pane, same width as a 360 to 480dp phone; no change | Upper pane | Left pane |
| Tap on the line | Add tray | Add tray, centred 560 over both panes; the line stays under the scrim (08 §2) | Tray in the lower half (D29), line visible above it | Tray in the left sub-screen |

Notes:
- **The snackbar covering the foot row** (mockup 41 problem 11) is accepted, but with TalkBack on the bar stays until dismissed and keeps covering the last 70dp of Home's list. `TopBarScrollView` pads for the dock fade, not for the bar. Acceptable; if the hallway test hits it, pad the list while a bar is shown.
- **In two-pane the line's door-opened rule (F7).** `08` §1 says a door-opened tray closing is an evaluation point; in two-pane, tabletop and book Home stays on screen around the tray, so "drawn under the scrim, in Home's first frame" is true there too. Adopt `05` F7 as written (the close only removes the line, never adds).
- **"Spends insights wait while it shows" (`08` §3).** In two-pane both panes are on screen at once, so Spends' insight would disappear when the line shows and return when it clears: a window-class-dependent behaviour. `design-ia` to confirm it is wanted; single pane never shows both together.
- **Line states for a mouse or keyboard** (large screens): focus ring and a 1dp hover outline are as listed in `08` §3; Enter and Space activate through `Pressable`.
- **Install line** is one-time and has no door in the middle of a sheet; it follows the line's placement and its once-only "seen" rule.
- **Tab order in two-pane.** There is no `FocusTraversalGroup` in `lib/` (grepped), so Flutter's reading-order policy applies and Tab can alternate between Home and Spends rows by their screen position. Not caused by these features, but the foot row and the line are new tab stops. Wrap each pane of `AppShell._sideBySide` in a `FocusTraversalGroup` (Home first, then Spends).

## 8. Hardware keyboard (answers `04` open question 6)

**The Add tray does not map them. Nothing in `lib/` handles digit keys.** Grep found no `Shortcuts`, `CallbackShortcuts`, `onKeyEvent` or `LogicalKeyboardKey`. The probe on the bill sheet's keypad (the same shared `Keypad`):

| Key | Result |
|---|---|
| Digits 0 to 9 | **Nothing** (amount unchanged) |
| Backspace | **Nothing** |
| Enter, Space | Activate only a key that already has focus (`Pressable` uses `FocusableActionDetector`); no key has focus when the sheet opens |
| Escape | Goes through `maybePop`: **it did step back after a Tab put focus in the sheet**; it was not tested with no focus, so do not rely on it |

So `04` §2's rule ("match the Add tray if it already maps them; otherwise open question 6") resolves to: **leave digits, Backspace and Enter out of Fix my number and *Used*.** Recommended separately, as one change for every keypad page (so the Add tray, bill amount, Fix, *Used*, *Put in extra*, income and onboarding gain it together): a small wrapper in `Keypad` mapping `0`-`9` and numpad to `onKey`, Backspace to `onBackspace` (Shift+Backspace to `onClear`), and Enter to the page's action key when enabled, with the controls region autofocused on open so no Tab is needed. Escape needs no mapping. This is a product choice (the app is phone-first); hardware keyboards matter on tablets, ChromeOS and desktop windowing (the brief for Android 16 large screens), so it is worth doing once, not per feature.

## 9. `TestWindows` cases each new screen needs

`TestWindows` lacks a short split-screen window, a book fold and a tabletop; `add_entry_tray_test.dart` holds a private `_tabletopFold`. Add to `test/helpers/pump_app.dart`: `splitScreen = Size(412, 400)` (E18), `splitThird = Size(412, 300)`, `foldableBook` (673×841 with a vertical `DisplayFeature` at x 336 and a variant with a 40dp hinge gap), `foldableTabletop` (701×841, the half-open fold at y 420 moved out of the Add tray test). Assertions, not only "no exception" (the bill-sheet test checks only `takeException`):

| Screen | Windows | Assert |
|---|---|---|
| **Fix sheet, keypad step** | phone; phoneLandscape; smallPhone at 1×, 1.5×, 2×; splitScreen; splitThird; foldableUnfolded; foldableLandscape; tablet; book (fold, hinge gap); tabletop | No overflow. Sheet rect inside its sub-screen and clear of the fold rect. After typing, `figure` and *Fix it* are inside the window above the bottom inset, and `figure.bottom <= keypad.top`. First key scrolls the slot into view. Keys 48dp minimum. Padding bottom 24 and 48: `Fix it.bottom + inset <= window.height` |
| **Fix sheet, guard step** | smallPhone 1.5×; splitScreen; phone; tabletop | Both keys 56dp and fully visible; Back (`maybePop`) returns to the keypad with digits; scrim tap = Back; swipe closes; Back while saving closes |
| **Used question** | same set as the Fix sheet | Same, plus *All of it* chip fits beside the amount at 320 and 1.5× (mockup 42 says it wraps below six digits); stamp does not replay |
| **Rotation, fold, resize while open** | phone to phoneLandscape; flat to tabletop; flat to book | Digits, step, notice survive; the sheet re-seats in the lower half or left sub-screen (needs the posture-agnostic route, §3) |
| **Home foot row, install line, missed-log line** | phone; smallPhone 1.5×; foldableLandscape and tablet (two-pane); tabletop; book | Visible at scroll end above the Add key or dock; line min 56dp; row never behind the snackbar's own target (*Undo* reachable); nothing under the fold; the two-pane snackbar width is the pane's minus 40 |
| **Snackbar** | tablet; tabletop | Bottom edge on the Add key's top (two-pane) or the fold line's top (tabletop); never overlaps the Add key |
| **Hold** (`HomeBloc`) | n/a | A fake `HomeBloc`: sheet open sends `Opened`, exit end sends `Closed`, a `finally` on error; a ledger change in between does not reload Home until `Closed`; two overlapping holds keep Home held until both close |
| **Settings door** | phone | The snackbar appears on `SettingsPage`'s host and its Undo works |
| **a11y** | each of the above | `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` (`test/a11y_test.dart`); the live slot has one child in semantics |
| **Dark theme** | phone, tablet | The guard keys and *All of it* chip contrast |

## 10. Findings by severity

**Blocking before build**

1. **The bill-sheet body cannot host a keypad question** at 320×568, 412×400, landscape or tabletop: the keypad scrolls, so the typed amount (and *Fix it*) go off screen. The pinned-controls layout (§3) is a precondition, and it touches the shared `BillSheet.route` body, so *Put in extra* and *Money coming in* change with it.
2. **No hold on the bill-sheet route** (F1, confirmed) and the `HomeBloc` flag must become a counter (§5).
3. **Back while writing loses the Undo** if the new `show` copies `BillSheet.show`; copy `BillAmountSheet.show` (§4 item 3).
4. **The Settings door's snackbar and Undo have nowhere to live** (§5).
5. **No bottom inset** on the bill-sheet body: *Fix it* and *Save* overlap the system nav bar (measured). Existing, but these features pin the key right there.

**Corrections to the docs, listed not made**

| Doc | Change |
|---|---|
| `04` §4, §8 and `05` §2, F6 | Predictive back cannot preview (no hook in the sheet route); back commits. Scrim at the guard = Back, swipe and handle = close |
| `04` §1, §9, Open Q8 | Tabletop is the lower half with side-by-side (D29), not a split across the fold. Mockup 41 §8's two-pane and tabletop schematics are not buildable as drawn (sheet in one sub-screen only) |
| `04` §2, §7 | Keys in a sheet are 56dp, 48 when short |
| `04` Open Q6 | Answered in §8: no mapping today; leave out |
| Mockups 41, 42 | Handle is 48dp, not 16 to 20; recount the 320×568 budgets. 42 problem 1's "fits at 1×" is false with the real handle |
| UI_DESIGN §10 "A back swipe scales the tray down" | True for pages only; sheets and the Add tray do not preview |
| UI_DESIGN §13 | Add a row: sheets in the bill-sheet route and the Add tray sit in one sub-screen of a fold; in a short window the controls are pinned and the header scrolls; sheet bottoms clear the nav-bar inset |
| SPEC E16 to E18, NFR-8 | Add "a keypad sheet keeps the typed amount and its action key on screen at 320×568 and 412×400" |
| DECISIONS | One row if approved: the pinned-controls rule for keypad sheets and the hold on every Home-door sheet (D91 widened) |

**Verify on a device** (not done): the tabletop and book sheet placement, the hero visibility under a 650dp sheet at 1280×800, real nav-bar heights, a started-then-abandoned back gesture, and the sheet exit time on the moto g45 against NFR-1's 400ms (`05` §5).

## Source scope

`lib/app/routes.dart`, `lib/app/main_screen.dart`, `lib/app/app_shell.dart`, `lib/core/layout/*`, `lib/core/widgets/adaptive_split.dart`, `pane.dart`, `keypad.dart`, `hisaab_snackbar_host.dart`, `lib/settings/presentation/pages/bill_sheet.dart`, `bill_amount_sheet.dart`, `widgets/bill_sheet/bill_amount_question.dart`, `bill_question_frame.dart`, `lib/add_entry/presentation/pages/add_entry_tray.dart`, `widgets/amount_step.dart`, `lib/home/presentation/bloc/home_bloc.dart`, `lib/home/presentation/pages/home_page.dart`, `test/helpers/pump_app.dart`, `test/settings/presentation/pages/bill_sheet_test.dart`, `material_ui` 1.11 `bottom_sheet.dart` and Flutter's `modal_barrier.dart`; UI_DESIGN §10 and §13, SPEC E16 to E18 and NFR-8, DECISIONS D22, D29, D54, D91; the docs and mockups named in the status line. A probe test was written, run and removed; no repo file was changed except this one.
