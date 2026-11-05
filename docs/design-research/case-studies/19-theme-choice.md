# Choosing light or dark: one tile, how many taps

## The job
Let someone who wants the app lighter or darker than their phone fix it once, then forget it (SPEC FR-SE-3).

## What's wrong
D130 as first built is one *Light or dark* row that opens a sheet of three choices. That is 2 taps (row, then choice) plus a sheet animation. The owner asked for fewer taps while keeping one tile. The three inline rows before it were 1 tap but took three tiles.

## Research by source
- **NN/g, [Dark Mode: How Users Think about It and Issues to Avoid](https://www.nngroup.com/articles/dark-mode-users-issues/) (2023):**
  - "Mirror the device's operating system dark mode settings by default."
  - Users "think about dark mode at the operating-system level" and "will not look for it in most applications."
  - An in-app switch "is fine." Preferences split about a third light, a third dark and a third both.
  - The article says nothing about where to put the switch or how many options it should have.
- **Gmail on Android ([Google help](https://support.google.com/mail/answer/112508)):** Settings › General › *Theme*, a row that opens a dialog of Light / Dark / System default. That's 2 taps, the common Android pattern. WhatsApp is reported the same way ([groovyPost, 2020](https://www.groovypost.com/howto/enable-dark-theme-whatsapp-android/)); unverified on the current app.
- **iOS Display & Brightness ([AT&T guide](https://www.att.com/device-support/article/wireless/KM1364883/Apple/iPhoneSE)):** Light and Dark sit inline at the top with previews, plus an *Automatic* switch. That's 1 tap. The previews themselves weren't covered by any source I read.
- **Material 3 / Jetpack Compose:** `SingleChoiceSegmentedButtonRow` with Light / Dark / System is the stock Compose example ([react-native-jetpack-compose docs](https://mgcrea.github.io/react-native-jetpack-compose/components/segmented-button)). One app moved its theme picker to an M3 segmented button with a check on the pick ([JournalApp PR #100](https://github.com/danielchalmers/JournalApp/pull/100)). That's 1 tap. The m3.material.io guidelines page didn't render for fetching, so Material's own wording isn't checked.
- **Web toggles:**
  - Lea Verou ([blog](https://lea.verou.me/blog/tags/dark-mode)) argues a two-state "system ↔ opposite" switch beats cycling system → light → dark. Her case is that a cycle hides the current state and the third value.
  - Component libraries ([Umami](https://zen.umami.is/docs/actions-navigation/theme-switcher), [Genesys Spark](https://spark.genesys.com/latest/patterns/themes-and-modes-patterns-y9KM8kJM)) use a segmented control in settings panels "where all options should be visible", and an icon cycle only in dense headers.
- **Our own precedent:** Ask AI already uses a segmented period control ([case study 01](01-ask-ai-choice-screen.md), D67), as does Spent | Got (D47).

## Patterns compared
| Pattern | Taps | All choices visible | Risk |
|---|---|---|---|
| A. Row → sheet/dialog (built, Gmail) | 2 | No | Hides the choices; a second step for a 3-way pick |
| B. One tile with an inline segmented control (M3, Compose, Umami) | 1 | Yes | "Match phone" crowds a ~100dp segment at 2× text (design-ui, design-accessibility) |
| C. Three inline rows (first build, iOS) | 1 | Yes | Three tiles; the owner rejected it |
| D. Tap the tile to cycle | 1 | No | Hidden state, and it passes through an unwanted look (Verou) |
| E. Two-state switch "Dark" + system default | 1 | Partly | Can't force Light on a dark phone, and loses "Match phone" after one flip |

## Recommendation
**B, one tile with an inline segmented control.** The tile reads *Light or dark* with three segments under it: phone glyph + *Match phone*, sun + *Light*, moon + *Dark*. The pick is a raised `control` pill with a check (D47, D100).
- It takes 1 tap, keeps all three choices visible and needs no sheet. It matches the stock Material 3 / Compose pattern and our own Ask AI and Spent | Got controls.
- **2× text:** when the three segments can't fit their labels on one line, they stack into a vertical list inside the same tile. The choices stay the same and only the layout changes. This answers the clipping risk instead of shortening "Match phone".
- NN/g says most people never open this setting, so speed matters less than clarity. B still wins: it is no slower than A, and it shows the state.

## Outcome
Approved, built, then changed by the owner (D130).
- **First build: B, a worded segmented control.** Tests found two problems:
  - The glyph had to sit above the word, and a label had to wrap. Even then, a 360dp phone was close to stacking.
  - Unpicked words had to stay `ink`, because a short word like "Dark" in `ink2` anti-aliases to about 3.2:1 on `sunk`.
  - design-ui also measured the light-theme pick pill at only 1.3:1 against its track.
- **Final: a compact icon toggle,** the owner's choice over preview cards, a radio list and a restyled switch. The row is *Light or dark* with the current look's name under it, and three 48dp icon buttons at its end; the pick fills `ink`.
  - It stays 1 tap.
  - It needs no stacking at 2× on a 320dp phone.
  - The pick reads clearly in both themes.
  - Words show only for the current look; TalkBack reads every button by name.

## Risks
- The segmented row is the only control of its kind on the Settings page. Its edges must share the row gutter.
- The stacking width needs a test at `TestWindows.smallPhone` and 2×.
