# Play store screenshots

The listing screenshots are in `out/`. They are ready to upload as 24-bit PNGs with no alpha.

| Play slot | Files | Size |
|---|---|---|
| Phone | `phone-1.png` … `phone-8.png` | 1080 × 1920 (9:16) |
| 7-inch tablet | `tablet7-1.png` … `tablet7-5.png` | 1920 × 1080 (16:9) |
| 10-inch tablet | `tablet10-1.png` … `tablet10-6.png` | 2560 × 1440 (16:9) |

Upload them in number order. Frame 1 sells the core idea, and the top-right dot rail advances one step per frame.

| # | Headline | Screen |
|---|---|---|
| p1 / s1 / t1 | Know what you can spend today. | Home: the hero with a loupe, the bite bar, the days rail and bills set aside |
| p2 / s2 / t2 | One honest number. | Infographic: the BR-4 maths as the app's bill slip (₹45,000 − ₹27,150 − ₹1,200 ÷ 9 days − ₹420 = ₹1,430) |
| p3 / t3 | Add a spend in 3 taps. | Add: the keypad with the effect line, then the category tiles |
| p4 | See where it went. | Spends: the pace chart and categories |
| p5 / s3 / t5 | Ask any AI about your money. | Ask AI: the questions, the preview and the handoff |
| p6 / s4 / t4 | Light by day. Dark by night. | Home in both looks |
| p7 | Set your bills once. | The bill slip |
| p8 / s5 / t6 | Your money stays on your phone. | Privacy: no sign-up, no ads, offline, your backup |

## How they're made

1. **Real screens.** `shots/` holds captures of the real app running `tool/store/demo_main.dart`. That entry point boots the app on the in-memory test fakes, seeded with the SPEC worked example (today Mon 26 Oct 2026, hero ₹1,430) plus a month of spends spread across categories. It never opens the database, so it is safe to install over a debug build. The tablet captures came from a phone with its display overridden: `adb shell wm size 1600x2560` (10-inch) or `1200x1920` (7-inch), `wm density 320`, and rotation 1. System UI demo mode was on, and the status bar is cropped off.
2. **Frames.** `frames.html` draws each frame from the `FRAMES` table: the ink or paper field, the hero's guilloché etch, the headline with a marigold highlight, the shot cards, and the callouts. Open `frames.html#p3` in a browser to see one frame.
3. **Render.** `sh docs/design/store/render.sh [p1 t3 …]` runs Edge headless at the exact size, then flattens each file to RGB with PIL.

## Rules kept

- Marigold appears only on *today / act* marks, and always with an ink edge on paper.
- No red, no green, no category colours. The fonts are Anek Latin and Mukta from `assets/fonts/`.
- Every amount comes from the SPEC worked example as the app computes it.
- No "best", "#1" or "free" claims, and no badges.
- "Works offline / doesn't ask for internet" holds because the release manifest has no `INTERNET` permission. Re-check that before each release (RELEASE.md).

## Known gap

The 7-inch set has no Add frame. At 960 × 600 dp the Add tray's keypad overlapped the amount in the build these were shot from. That is fixed in the working tree (`TestWindows.landscape600`). Re-shoot `tablet7` with an Add frame once the fix is committed.
