# 21. The pace chart on a narrow portrait phone

**Question.** The owner says the Spends pace chart "looks cramped in portrait mode". How do strong money and fitness apps, and the data-viz guides, show a cumulative "spent vs steady pace vs forecast" line on a phone 360–411dp wide? Specifically: (1) height or aspect ratio, (2) a y-axis whose top (the month's money) dwarfs early spending, (3) placing direct labels without collisions, (4) gridlines and axis labels, (5) where the legend and dates go.

**Context.** FR-SP-3, UI_DESIGN §5.4, D69 (height = half the card's width, 160–200dp), D77 (verdict words), D133 (gap bracket, forecast line, labels on the plot, dates under it). Code: `lib/spends/presentation/widgets/pace_*.dart`.

**Method.** Two cheap methods, because nothing here needs users yet to show where the problem is:
1. **Measurement of the build** from one screenshot (720×1600 px at 280dpi, about 411×914dp, 1.75 px/dp), on 5 Nov with ₹5,150 spent of ₹55,000.
2. **Desk research**: the HIG, data-viz guides (Datawrapper, the EU Data Visualisation Guide, the UK ONS service manual), perception research on aspect ratio, and public help pages of Copilot, Monzo, Revolut, Emma, YNAB, Linear, Strava, Jupiter and Fi.

What this study can't say: how most competitors' charts actually look. Mobbin needs a login, and no help page found describes axis scaling or label placement in pixels. Those gaps are listed under each question rather than guessed.

## What the screenshot shows

Measured from the screenshot (rounded; ±2dp):

| Thing | Size |
|---|---|
| Card content width | ≈330dp, so the chart is `clamp(330 / 2, 160, 200)` ≈ 165dp tall (D69) |
| Plot (inside the y-labels) | ≈290 × 154dp, about **1.9 : 1** |
| Y-labels column (₹40K, ₹20K, ₹0) | ≈36dp, 11% of the width, outside the plot on the left |
| Today | day 5 of 30, at 17% of the plot's width |
| Spending line and dot | ≈50 × 14dp, in the bottom-left corner |
| Everything that changes with the user's spending (spent line, dot, bracket, forecast line, both labels) | inside the **bottom ≈40dp (26%)** of the plot |
| Top 74% of the plot | only the dotted steady line rising to ₹55,000 and two gridlines |
| "₹8,183 under" and "about ₹49,500 spare" | on the **same baseline**, ≈70dp and ≈115dp wide, about 50dp apart |

**Finding S1 (high confidence, measured).** The plot isn't short; the *data* is small. The y-axis is fixed to the month's money (FR-SP-3), so early in the month the user's line, its two numbers and the forecast are packed into a strip about a quarter of the plot's height. Raising the cap from 200 to 250dp would grow that strip by about 10dp. "Cramped" is the marks and words crowding one corner, not the card.

**Finding S2 (high confidence, from the code).** The two labels avoid the plot's edges but not each other. `PaceChartPainter._clamped` keeps each label inside the plot; nothing checks the gap label against the forecast label. On a 360dp phone the plot is about 240dp wide (card ≈320dp, content ≈280dp, y-labels ≈36dp). At day 5 the gap label ends near 120dp and the right-aligned spare label starts near 125dp, so about 5dp separates them. A few days later, while spending stays under the forecast, the two overlap. The forecast label goes above its line and the gap label is centred on the bracket, so both land in the same low band whenever spending is far under steady pace, which is the common early-month case.

**Finding S3 (medium).** There are three rows of words under the plot: dates, a three-item key, and the verdict. Together with the title row and the two in-plot labels, that's seven text elements for one chart. The chart reads as dense even where the plot has space.

## Q1. Height and aspect ratio

| Source | What it says |
|---|---|
| Cleveland, via [Heer & Agrawala, *Multi-Scale Banking to 45 Degrees* (2006)](https://idl.uw.edu/papers/banking) | Choose the aspect ratio so line segments average 45°, to make slope differences easiest to see. Different trends want different ratios: their CO₂ example uses 1.17 for the long rise and 7.87 for the seasons |
| [Talbot, Gerth & Hanrahan, *An Empirical Model of Slope Ratio Comparisons* (InfoVis 2012)](https://www.tableau.com/research/publications/empirical-model-slope-ratio-comparisons) | Errors in comparing slopes are **not** generally smallest at 45°. Visible baselines help. (Only the abstract was read; the PDF returned 403) |
| [EU Data Visualisation Guide, *Line chart aspect ratios*](https://data.europa.eu/apps/data-visualisation-guide/line-chart-aspect-ratios) | "A wide layout … will flatten trends"; "narrow and high designs exaggerate trends". A follow-up found "people performed better with lower average slopes", so 45° is "a good starting rule", with deviation allowed "when there are good arguments" |
| [Gregor Aisch, *Doing the line charts right* (2012)](https://www.vis4.net/blog/doing-the-line-charts-right/) | Slopes depend on the aspect ratio. Banking can produce portrait-shaped charts, so "why not let the optimal chart ratio define your layout?" |
| [Datawrapper, responsive height (2024)](https://www.datawrapper.de/blog/responsive-height-control) | Two modes: a fixed height, or a fixed aspect ratio. You set the height of the **plot**, so notes and keys don't take the data's room. No number is recommended for mobile |
| [EU guide, *Scaling charts*](https://data.europa.eu/apps/data-visualisation-guide/scaling-charts) | Smaller versions keep their proportions but carry less data, fewer axis labels and fewer annotations. When width runs out, rotate to tall |
| Copilot, Monzo, Revolut, Emma, YNAB, Strava, Jupiter, Fi | No public page gives a chart height or ratio. Not verified |

**Answer.** No source sets a phone height, and none was found showing a money app's chart taller than about 200dp or near square; that last point is unverified, not a negative finding. The research gives a rule instead of a number: pick the ratio by the slope you need people to read. Hisaab's key slope is the user's line against the steady line *near today*. At 1.9:1 with the axis to ₹55,000, that slope is decided in 14dp of height. A square plot would only double it. Banking the *whole* month (the steady line, which is already easy to read) is the wrong target. That's multi-scale banking's point: the trend you care about chooses the ratio.

## Q2. A y-axis whose top dwarfs early spending

| Source | What it says |
|---|---|
| [Apple HIG, Charts › Axes](https://developer.apple.com/design/human-interface-guidelines/charts.md) | "Use a fixed or dynamic axis range depending on the meaning of your chart." Fixed when the bounds mean something (battery 0–100%); dynamic "when the possible data values can vary widely and you want the marks to fill the available plot area" (Health's Steps). If marks or axes change, "help people notice important changes" |
| [Copilot help, Dashboard graph](https://help.copilot.money/en/articles/6045480-dashboard-tab) | Solid line for spending, dotted line for "the ideal spending rate", and the *Free to Spend* figure at the top of the graph. Large early-month bills "can cause the spending rate to spike", so recurring bills are left off the graph. Axis scaling isn't described |
| [Copilot help, Optional budgeting](https://help.copilot.money/en/articles/6282850-optional-budgeting) | The comparison number sits on the charted line; the totals are text above the chart |
| [Datawrapper, *What to consider when creating line charts*](https://www.datawrapper.de/academy/what-to-consider-when-creating-line-charts) | Line charts "don't need to start from zero", but values near zero should keep the zero baseline |
| UI_DESIGN §5.4 (existing Hisaab reasoning) | A fixed axis avoids Apple Card's rescaling problem |

**Answer.** Every source agrees the choice depends on meaning, and Hisaab's top (`I − K`) does mean something. So a fixed axis is defensible, and Copilot appears to draw the full-month ideal line too. Its help doesn't say how it scales, so that remains unverified. Copilot treats early-month bill spikes by taking scheduled bills *off* the graph. Hisaab instead steps the steady line by bills (D129), which is more honest but keeps the axis tall.

No source documents an app that switches scale partway through the month. If Hisaab ever did, the HIG asks for the change to be noticed (animated *and* stated). The cheaper ways to give the user's line room keep the fixed axis: free the plot of words (Q3) and free its left edge (Q4).

## Q3. Direct labels without collisions

| Source | What it says |
|---|---|
| [Datawrapper, responsive annotations (2020)](https://www.datawrapper.de/blog/better-more-responsive-annotations-in-Datawrapper-data-visualizations/) | "On small screens, annotations get numbered and move below the chart"; a chosen few can stay inside. "Overlapping or cropped annotations are annoying" |
| [EU guide, *Responsive text annotations*](https://data.europa.eu/apps/data-visualisation-guide/responsive-text-annotations) | Annotations often need more room than small screens give; important ones can't be dropped, so they go below the chart, linked by numbers |
| [Datawrapper, mobile-first (2016)](https://www.datawrapper.de/blog/datawrapper-becomes-mobile-first-charting-tool) | On mobile, "line charts switch from direct labeling to legend-based labeling" |
| [*Designing Annotations in Visualization: Considerations from Visualization Practitioners and Educators* (arXiv 2604.07691; authors not checked)](https://arxiv.org/pdf/2604.07691) | Practitioners cut text on small displays; with no room to label marks they use short notes or keyed captions under the plot (from a search summary; the PDF wasn't read) |
| [Apple HIG, Charts › Descriptive content](https://developer.apple.com/design/human-interface-guidelines/charts.md) | "Summarize the main message of your chart"; Weather puts the next hour's rain in a title and subtitle above its chart |
| Copilot (above) | The headline number (*Free to Spend*) sits above the graph, not on it |
| [Linear, Cycle graph](https://linear.app/docs/cycle-graph.md) | A dotted target line with the rule "at or above the target line, you are on track" in words; label placement isn't described |

**Answer.** On a narrow phone, the consistent move is to take numbers **out of the plot**: into a summary line above it (HIG Weather, Copilot) or a key below it (Datawrapper, EU guide). At most one short mark stays inside, at the point that matters. None of the sources keeps two free-floating numeric labels in one plot on a phone. Hisaab's "₹8,183 under" and "about ₹49,500 spare" are exactly the case these guides move out.

## Q4. Gridlines and axis labels

| Source | What it says |
|---|---|
| [ONS service manual, *Axes and gridlines*](https://service-manual.ons.gov.uk/data-visualisation/guidance/axes-and-gridlines) | "In most cases, use three to six gridlines for a mobile view", at "sensible, round-number, intervals", each labelled |
| [Apple HIG, Charts](https://developer.apple.com/design/human-interface-guidelines/charts.md) | "Prefer familiar sequences" (0, 5, 10). Too many gridlines overwhelm and too few hide values. "In a compact environment, maximize the width of the plot area": keep vertical-axis labels short, put units in the title, and consider moving the y-axis to the trailing side so its labels don't stick out past the leading edge |
| [Datawrapper, *Why many charts don't include axis labels*](https://www.datawrapper.de/academy/why-datawrapper-does-not-include-axis-labels-for-many-charts) | Labels outside the plot "take away valuable space – especially on narrow mobile phones"; the unit can ride on the first tick |
| [Gestalt (Pinterest) guidelines](https://deploy-preview-4017--gestalt.netlify.app/foundations/data_visualization/charts_and_graphs/general_guidelines), via search summary | At most 3 horizontal labels at ≤576px wide, 5 on desktop (the page now returns 404, so this isn't verified) |

**Answer.** Hisaab's three labelled lines (₹0 / ₹20K / ₹40K) are at the low end of ONS's 3–6, with a familiar sequence, so the count is fine. Their *placement* costs width: a 36dp column outside the plot is 11–15% of a 240–290dp plot. The guides prefer short labels inside the plot (sitting on their gridline) or on the trailing side.

## Q5. Legend and dates

| Source | What it says |
|---|---|
| [Datawrapper (2016)](https://www.datawrapper.de/blog/datawrapper-becomes-mobile-first-charting-tool) | On mobile, a legend replaces direct line labels |
| [ONS line chart guidance](https://ons-design.notion.site/Line-chart-3bf06c1414f34f0eaf68af1095bc7c11), via search summary | Label lines directly, except on mobile or when lines end at the same point (the Notion page rendered empty) |
| [Apple HIG, Charts › Best practices](https://developer.apple.com/design/human-interface-guidelines/charts.md) | Align the chart's leading edge with the screen's other views |
| [EU guide, *Scaling charts*](https://data.europa.eu/apps/data-visualisation-guide/scaling-charts) | Fewer axis labels on small versions |

**Answer.** Hisaab already matches this: a key for the three line styles, and dates under the plot with only start, *Today* and end (3 labels, within Gestalt's limit). D133's "dates under the plot" fits every source. Two choices are still open. One is whether the key could double as the place for the numbers: "— You ₹5,150 · ··· Steady ₹13,333 · – – At this pace about ₹49,500 spare". The other is whether the verdict line could carry the gap, though D133 rejected that wording.

## Implications for Hisaab (for `design-product`)

These are options with evidence, not decisions. D69, D133 and FR-SP-3 stand until a new row changes them.

1. **Fix the footprint before the frame** (S1). Height alone won't fix "cramped": 165 → 200dp gives the user's corner about 3dp more. Changing the cap without anything else isn't worth reopening D69.
2. **Move the two numbers out of the plot** (Q3, S2), into one line under the key or above the plot, for example "₹8,183 under steady pace · about ₹49,500 spare at this pace". Keep only the bracket and the today dot inside. This removes the collision at every width, frees the low band, and matches TalkBack's sentences. *Conflicts with D133* ("labels on the plot") and UI_DESIGN §5.4's in-plot marks.
3. **Free the left edge** (Q4): y-labels inside the plot above their gridlines (or trailing), giving about 36dp (≈12–15%) more width to the days near today. *Touches* FR-SP-3's axis labels (placement only, not values) and `PaceChartPainter.plotLeft`, which the date row aligns to.
4. **Only then reconsider height** (Q1): with words out, a plot nearer 4:3 on phones in portrait (≈0.75 × width, ≈210–250dp) is within the guidance, and "Where it went" had about 80dp spare in this screenshot. *Conflicts with D69's 200 cap*; check against a 360×640 window and a 1.5× text scale before proposing.
5. **Don't rescale the axis to the data** without a stated, animated change (HIG). It reopens UI_DESIGN's "avoiding Apple Card's rescaling problem".
6. If labels stay inside, they need a **mutual-collision rule**: when the forecast label's box meets the gap label's, put the forecast label under its line or drop it to the key. This is the minimum fix for S2 under D133 as written.

## Open questions

- **How do Copilot, Monzo, Revolut and Emma actually scale and label?** Help pages describe lines, not pixels. Next: a Mobbin session in a browser (Copilot "Dashboard", Revolut "Analytics", Emma "Spend over time"), recorded as screenshots in this folder. Cleo, Lunch Money, Apple Card (beyond its weekly bars), CRED, Google Fit and Strava's own cumulative chart weren't found in any public source; [Strava's progress chart](https://support.strava.com/en-us/articles/15401618-progress-summary-chart) is totals, and the cumulative year chart is third-party ([VeloViewer](https://blog.veloviewer.com/?p=2025)).
- **Material 3 has no chart guidance that fetched**: [m2 data visualisation](https://m2.material.io/design/communication/data-visualization.html) returned a title only.
- **Tufte** (data-ink, sparklines) wasn't read first-hand, so nothing here rests on it.
- **Validation.** A 5-user blind read on a 360dp phone, run by `design-validation`, comparing the current chart with options 2+3 and 2+3+4, at day 5 and day 22. Task: "Are you OK this month, and by how much?" Measure success, time and SEQ, with Hindi/English and low-end phones in the mix.
