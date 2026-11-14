# Mockup 46 · Accessibility review of the Spends graphs proposal

Status: review, pre-spec. Covers mockup 44 (comparison sentence, split bar, rows, 6-month strip) and the parts of mockup 45 (month story) that reuse it. Standard: WCAG 2.2 AA plus Android (48dp targets, TalkBack, 200% text, reduced motion). Docs only; no code or mockup was changed.

Ratios below are computed from the hex tokens (WCAG relative luminance). Real tokens are from `lib/core/design/hisaab_colors.dart` (light background is `F1EDE8`; the mockup uses `F1EBE4`, a negligible difference). Note: **`soft` does not exist in `HisaabColors`**; it is a mockup-only value, so the fix is a new token.

## 1. Contrast, measured

| Pair (non-text, need 3:1) | Light | Dark | Verdict |
|---|---|---|---|
| soft (mockup) vs sunk (the track) | **2.71** | **2.91** | Fail both |
| soft vs surface | 3.52 | 3.41 | Pass |
| soft vs ink (Bills vs Everyday) | 5.11 | 4.26 | Pass |
| ink vs sunk | 13.84 | 12.41 | Pass |
| ink vs surface (outline, hatch, strip bars) | 17.97 | 14.54 | Pass |
| ink2 vs surface (income line, labels) | 7.20 | 6.42 | Pass |
| sunk (the track) vs surface | **1.30** | **1.17** | Fail: the bar's extent is invisible |
| hairline vs surface (strip baseline) | 1.53 | 1.37 | Decorative only, acceptable |
| signal vs surface bare | 1.81 | n/a | Strip's today-dot carries an ink 1.5 edge, so passes (ink vs signal 9.9) |

Story (always dark): sSoft `77706A` vs sSunk `312D29` is 2.80, vs `3A3530` is 2.49 (fail). sSoft vs sBg is 3.53 / 3.21 (pass), sInk vs sSoft is 4.37.

Findings, with severity:

1. **Everyday fill fails 3:1 against the track in both themes** (mockup 44 `.seg.every` vs `.bar`; mockup 45 page 2 `.split`). It bites whenever Everyday touches the empty track, which is every time Saved is ₹0 (see 2). **Major**, WCAG 1.4.11. Fix: new token (section 7).
2. **The track has no visible edge.** Sunk vs surface is 1.3:1 / 1.17:1, so "how much of income is left" has no drawn extent; the user must trust the key. The key's "Still free" swatch (`.sw.free`, sunk on surface) is nearly invisible for the same reason, so it can't be matched to the bar. **Major**, 1.4.11, worse in bright sun. Fix: draw the track with a 1dp `ink2` outline (7.2 / 6.4:1), and the free swatch the same way. The Saved outline is `ink`, so there is no clash.
3. **Bills vs Everyday is distinguished by lightness only** (ink vs soft, 5.1 / 4.3:1 today; 3.8 / 3.5:1 after the fix). It is not hue, so it does not break 1.4.1, but glare erodes lightness first. Mitigation already present: fixed order (Bills, Everyday, Saved, free; never reorders), a 2dp surface gap between segments, a keyed legend with words and amounts. Add one more cue: the 2dp gaps must be kept (they are what splits two adjacent mid-tones), and never merge segments when one is 0 wide. **Minor**.
4. **Saved when `0`:** the mockup applies `min-width: 8px` unconditionally, so a Saved outline would draw for ₹0. A 0 amount must draw nothing and the key row must say "Saved ₹0" (or be omitted). **Major** (false information), 1.3.1.
5. **The ~2% Saved sliver.** ₹1,000 of ₹45,000 is 2.2%: 6.5dp on a 292dp bar (5.8dp at 260). With `min-width: 8` less the 2dp left separator and 2dp outline each side, the interior is about 2dp, so it reads as a dark blob, not an outline box, and is easy to confuse with Bills. **Major**, 1.4.11. Fix: minimum Saved width 12dp (2dp gap + 10dp box with 2dp strokes leaves 6dp of surface inside); the free segment gives up the difference. In Flutter compute widths so they sum to the track exactly; in the mockup `flex:none` plus a min-width can overflow and the clip hides the end of the free segment. Saved is always named with its amount in the hero line and the key, so the sliver is never the only carrier.
6. **Over-income hatch:** ink 2dp stripes on surface 4dp gaps. Stripes are 18:1 against their gaps, and the pattern differs from the solid fills by texture, not lightness, so it passes. At 135 degrees and 2dp it aliases on cheap low-DPI panels; use 3dp stripes and 3dp gaps in the split bar. The tick (2dp `ink`, 4dp overshoot) is fine. **Minor**.
7. **Strip:** bars (ink), hatch, and saved (ink outline on surface) all pass. The Saved cap is `ySpent - ySaved - 2` = **0.12 units**, drawn as a 2dp stroke: it is a line, not a box (1.9dp at 0.9 scale). Treat it as a 2dp cap that never grows; it is only meaningful as "a line on top". Always name Saved in the bar's spoken label. **Minor**.
8. **Selection vs focus clash (strip).** Selection is `.sel` stroke `ink` 1.5 and the keyboard focus ring is the same `.sel` stroke 2. UI_DESIGN principle 24 / D99 says focus never means selection, and a selected control keeps its look and gains the ring. **Major**, 2.4.7 and consistency. Fix: selection = the picked-chip vocabulary (the month label in an `ink` pill with `background` text; 14.5 to 18:1), focus = the 2dp `focus` ring with `focusGap` band around the whole 48dp target.
9. **Lightness alone in the story's day bars** (mockup 45: over-share bars `sInk`, others `sSoft`): the dotted share line is a second cue (over bars cross the line), so it is redundant. Add one count sentence for screen readers (section 3). **Minor**.

## 2. TalkBack, element by element

| Element | Mockup | Should be | Severity |
|---|---|---|---|
| Comparison sentence | Plain text, arrow `aria-hidden` | One text node: "2,100 rupees less than by this day in September". Arrow excluded. Not a live region; it changes only with the month switcher | OK |
| Split bar card | Bar is one `img` with a sentence, key is `aria-hidden` | One merged node for the card body, read **answer first**: "16,430 rupees still free of 45,000. Bills 8,200, everyday 19,370, saved 1,000." (mockup order reads income first and 5 numbers before the answer). Bar and key excluded | Major (order) |
| Month title "Your ₹45,000 this month" | `h3` | `Semantics(header: true)` so the heading rotor works; one per card | Minor |
| Over-income state | Sentence says "more than you earned" | Same, and say what is past: "3,100 rupees more than you earned. 1,000 rupees still went to savings" | OK |
| Category row | One button, full label, `aria-expanded` | One merged node; `Semantics(button: true, expanded: isOpen)`; Flutter announces expanded/collapsed itself, no "tap to expand" text. Label "Food, 9,840 rupees, 36 percent. 1,200 rupees more than September". Icon, track, caret `ExcludeSemantics` | OK once built so |
| Visible "than Sep" vs spoken "September" | Mismatch | Voice Access label-in-name (2.5.3): make the visible and spoken text the same ("Sep" in both, or the full month in both) | Minor |
| Expanded top 3 | Siblings after the button | Each entry one `MergeSemantics` node: "Dinner out, 20 October, 2,400 rupees" (visible "20 Oct", spoken full); "No note" is plain text, not italic (italic hurts dyslexic and low-literacy readers) | Minor |
| "See Food entries" / "See all" | 14px links, ~20dp tall | Real buttons, 48dp tall; label unique ("See Food entries") | **Major** (see 4) |
| Strip group | `role=group` with a label | Keep: "Spent and saved in the last 6 months, against income of 45,000 rupees" | OK |
| Strip bars | `role=button`, label is only "May" | The bar's own label must carry the data: "September. Spent 39,600 rupees, saved 1,000 rupees, 4,400 rupees left over." Current month: "October so far. Spent 27,570..., 8 days to go." Add `selected: true` on the picked one. A TalkBack user then never needs the readout | **Major** (1.1.1, 4.1.2) |
| Readout `aria-live="polite"` | Updates on tap | Do **not** make it a live region if the bars already carry the sentence: TalkBack would say the label, then the same sentence again. Mark the readout `ExcludeSemantics` (it is a visual echo). If any bar ever lacks values in its label, keep `liveRegion` and drop the label values instead; never both | Major (double speech) |
| Today dot in the strip | Signal dot with ink edge | Decorative; the word is "so far" in the label | OK |
| Painted labels "Income ₹45K" and month names | SVG text | Must be real `Text` (scales with `TextScaler`, spoken by the group). "Income ₹45K" at 11 units is 10dp, below the 12sp floor, and a painter will not scale it. Replace with a normal text line under the chart: "Dotted line: your income, ₹45,000" | Major (1.4.4) |
| Story pages (45) | Tap zones are `aria-hidden`, `tabindex=-1`, page is `aria-live` | Real **Back** and **Next** buttons in the semantics tree (48dp+, also reachable by Switch Access and keyboard), position fixed; swipe is a bonus. A full-page `liveRegion` re-reads the whole page on each change: instead move focus to the page title and let TalkBack read from there. The page-4 day bars stay one sentence; add "N days went past the daily share" so the over/under fact is not lost | Major |

The mockup's page list says Back/Next exist for TalkBack, but the drawn story has none. Flag this to the 45 implementer.

## 3. Cognitive load (numbers per card)

| Card | Numbers on screen | Verdict |
|---|---|---|
| 1 Comparison | 1 | Good |
| 2 Split bar | Title income, hero free, "and saved", then 4 key amounts = **7 (2 repeat)**; speech has 5 | Too many. Drop the amounts for Saved and Still free from the key (the hero already states them) and keep Bills and Everyday; or drop the title's ₹45,000 and keep the key. Target 5 visible, 4 spoken after the answer. **Major** |
| 3 Where it went | Headline 2, then per row: amount, % and the new change = 3 x 5 = 15, plus 6 more when a row is open | The new change is the added load. Show the change only on the open row (progressive disclosure, matches the single expanded default), and in speech include it only then. **Major** |
| 4 Strip | Summary "4 of the last 5", readout 3 | Fine |

Other cognitive points:

- **Layout shift:** row 1 opens by default and any tap moves everything below it. Keep that, but animate only with the reduced-motion rule, and never reorder rows (spec already says so).
- **Sentence mismatch:** the strip summary counts "spent less than you earned", but the bars draw spent plus saved against the income line. A month with ₹44,500 spent and ₹1,000 saved is counted as good while its bar crosses the line: the words and the picture disagree. Count on the same measure the bars draw, or say "spent and saved less than you earned". **Major** (3.3 consistency; trust).
- **Copy:** "less than by this day in September" is an awkward construction for low-literacy and Hindi-first readers. Suggest `design-content` try "₹2,100 less than at this point in September". No idioms, no grades; confirmed none present.
- No timers, no auto-advance, nothing needs confirming. Good.

## 4. Touch targets

| Target | Size | Verdict |
|---|---|---|
| Category row | full width x about 58dp | OK |
| "See all", "See X entries" links | about 20dp tall | **Fail Android 48dp** (2.5.8 minimum of 24 only just met). Pad to 48dp |
| Strip bar hit area | `.sel` rect is 40 units wide x 0.9 scale = **36dp**; the slot is 48.7dp at 360 | Fail. Make the whole slot, full chart height, the target |
| Strip slot at 320dp | inner width 252, slot **42dp** | Fail even if the slot is the target |
| Month switcher chevrons (existing) | 40dp in the mockup | Verify the Flutter one is 48dp |

Strip rule: each bar is a 48dp-wide full-height `Semantics` button. Six bars need 288dp of inner width. Show 6 months when the card's inner width is at least 288dp, otherwise show 5 (drop the oldest; 5 x 48 = 240 fits at 320dp). Decide this from `context.layout`, not raw `MediaQuery`. The minimum is 2 finished cycles, so 5 is always allowed.

## 5. Text size (200%) and 320dp

- Strip: draw labels as `Text` in a Row of the 6 (or 5) slot buttons so they scale; at 200% "Sep" at 24sp is about 36dp, inside a 48dp slot. The chart height stays fixed (a graphic); the readout and labels use minimum sizes, never fixed heights (the mockup's readout `min-height` is fine).
- Hero line "₹16,430 still free" 28 to 56sp must wrap; use the Home hero's stepping rule (28 to 22 before wrapping) and let the card grow.
- Category row at 320dp, 200%: after the 36dp icon, 20dp caret and gaps, the name column is about 120dp, so "Shopping" at 30sp just fits and the change text wraps to 2 or 3 lines. Rule: at text scale above 1.3 hide the 36dp icon well (the name is the label) and let the change line take the full width. No fixed row height.
- Split bar: fixed 28dp is acceptable (non-text). The key wraps; its 16dp swatch stays.
- Story (45): `aspect-ratio 360/680` with `overflow:hidden` and a 64px "mega" will clip at 200% ("September" is about 230dp at 1x, so about 460dp at 2x). The page must scroll and the mega step down (64 to 48 to 40) before it wraps; Back/Next stay pinned. **Major** for the story.
- All of the above to be asserted at text scale 2.0 and the `TestWindows` sizes (include a 320dp window).

## 6. Reduced motion

- The caret rotation and row expand must use `HisaabMotion.reduceMotion(context)`: no height spring, a 150ms crossfade or an instant switch. The mockup already drops the caret transition under `prefers-reduced-motion`.
- The strip has no animation; keep it that way (no bars growing in).
- Story pages: the mockup falls back to a 120ms fade; match the 150ms token.

## 7. Must-fix list, in order

1. **Strip bars need the data in their label and a `selected` state; the readout must not be a second live announcement** (section 2). Major.
2. **Strip targets must be 48dp full-slot buttons; show 5 months below 288dp inner width** (section 4). Major.
3. **Everyday fill token must clear 3:1 against the track in both themes** (new token below). Major.
4. **Draw the track with a 1dp `ink2` outline and give the free swatch the same** so the remaining income has a visible extent. Major.
5. **Saved: draw nothing at ₹0; minimum 12dp when above 0; widths must sum to the track.** Major.
6. **Selection is not focus:** picked-chip look for the selected month, `focus` ring for focus. Major.
7. **Links ("See all", "See X entries") are 48dp buttons.** Major.
8. **Paint no text in the chart:** the income label and month names are real `Text`. Major.
9. **Read the split bar answer first** and cut the visible numbers on card 2 to 5, and show the row change only on the open row. Major (cognitive).
10. **Align the strip summary sentence with what the bars measure.** Major (consistency).
11. Story (mockup 45): real Back and Next in the semantics tree; focus to the page title, not a page-wide live region; scroll and step the type at 200%. Major for that feature.
12. Minor: visible and spoken "Sep" vs "September" agree; no italic "No note"; headings via `header: true`; 3dp hatch in the split bar; strip Saved cap named in the label, never relied on visually.

## 8. Token changes the design-system agent must own

No red, green, or hue is needed. One new fill token and two small rules:

| Token | Light | Dark | Measured |
|---|---|---|---|
| `fillSoft` (the Everyday fill; mockup `--soft`, new in `HisaabColors`) | `#787169` | `#858077` | Light: 3.68 vs sunk, 3.76 vs ink, 4.77 vs surface. Dark: 3.58 vs sunk, 3.47 vs ink, 4.19 vs surface (4.77 vs background) |
| Story soft (`sSoft`, used by the story's split bar and day bars, which sit on `1D1B18` / `262320` with sunk `312D29` / `3A3530`) | `#8F887F` in both | | vs sSunk 3.9 / 3.46, vs sInk 3.14, vs sBg 4.9 / 4.5 |

Rules, not colours:

- **Track outline:** `ink2` at 1dp (7.2 / 6.4:1) around any bar track that carries meaning (split bar, story split). The track fill stays `sunk`.
- **Selected chart item:** reuse the picked-chip tokens (`ink` fill, `background` text); the keyboard focus ring stays `focus` plus `focusGap`. Do not add a new selection colour.
- **Hatch geometry:** 3dp stripe and 3dp gap for the split bar; the strip's 2dp/5dp pattern is acceptable at its larger bar size.

The old mockup values (`#8E877F` light, `#77716A` dark) must not ship: they fail the track at 2.71 and 2.91:1.

## 9. Tests to write with the feature

- `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline` and `textContrastGuideline` at `TestWindows` sizes, a 320dp window, and text scale 2.0, for the Spends screen with all four cards.
- Semantics assertions: strip bar labels contain the amounts and `selected` flips on tap; the readout has no semantics; category rows report `expanded`.
- A contrast test in `hisaab_colors_test.dart` pinning `fillSoft` at 3:1 against `sunk`, `ink` and `surface` in both themes.
- Painter test: Saved width is 0 at ₹0, at least 12dp when above 0, and the segments sum to the track width.

Coverage gaps: none to report (docs only, no code changed). A TalkBack run on a device is still pending until a build exists.
