# Launch splash screen: design spec

Date: 2026-10-26 · Status: built 2026-10-26 (see §8 for what changed on device) · Preview: [`docs/design/mockups/09-splash.html`](../../design/mockups/09-splash.html)

## 1. Intent

- **Outcome:** a native Android launch splash that animates the h• icon, shown before Flutter draws its first frame.
- **Success:**
  - From tap to Home there is one background colour per mode, with no visible icon circle and no flash.
  - The motion tells the Day Blocks story in 800 ms or less.
  - Every frame a cut can land on looks deliberate.
  - The splash never delays Home.
- **Constraints:**
  - It is native, not Flutter. The Android 12+ `SplashScreen` platform API runs the animation; Android 7–11 (API 24–30) gets a static icon.
  - No new dependency. `androidx.core:core-splashscreen` is not needed, because it does not animate below API 31 either.
  - The icon uses the existing tokens and the existing h• geometry (UI_DESIGN §3.6).
- **User decisions:**
  - Concept C★ ("Aaj").
  - Splash background = icon background = Home background, in both modes.
  - Light mode uses off-white with an ink h, not full-screen ink.

## 2. The motion: C★ "Aaj"

**Story:** today and tomorrow arrive as day blocks. Today lands with weight and fills marigold (today lights up). Tomorrow steps back. Today rounds into the dot, the full stop of *hisaab*.

**Canvas:**
- The 108-unit adaptive canvas, with the system mask circle at r = 36 units, centre (54, 54).
- The whole mark is drawn at **scale 0.75 around (54, 54)**, so tomorrow fits inside the mask.
- Block size: 13 × 20 units, corner radius 4. The dot is Ø16.26, centred at x 70.84, sitting on the baseline at y 76.
- Tomorrow sits 16 units right of today, a 3-unit gap.

All times are in ms from the start of the icon animation. Curves are `pathInterpolator` control points.

| ms | What moves | Curve |
|---|---|---|
| 0–100 | Hold while the launcher window grows (system-allowed delay ≤ 166) | — |
| 100–220 | Today fades in (alpha 0→1), so it never pops at the invisible mask edge | linear |
| 100–380 | Row (today + tomorrow) slides in, translateX 26→0, landing with speed | 0.25, 0.5, 0.6, 0.9 |
| 100–200 | Today stretches along its travel: scaleX 1→1.16, scaleY 1→0.92, pivot (70.84, 76) | 0, 0, 0.2, 1 |
| 200–380 | Stretch eases: scaleX →1.06, scaleY →0.97 | linear |
| 240–340 | Tomorrow fades in to alpha 0.6, only once it is fully inside the mask | linear |
| 380–440 | Impact squash: scaleX →0.86, scaleY →1.08 | 0, 0, 0.2, 1 |
| 380–470 | Tomorrow fades out (0.6→0) | linear |
| 380–600 | Tomorrow steps back, translateX 0→34 | 0.4, 0, 1, 1 |
| 380–560 | Today fills marigold from the baseline (clip rises 0→22 units) | 0.2, 0, 0, 1 |
| 440–660 | Today settles to scale 1, 1 | 0.23, 1, 0.32, 1 |
| 520–800 | Today morphs from block 13×20 r4 to circle Ø16.26 (`pathData`) | 0.23, 1, 0.32, 1 |
| 800+ | Last frame = the static h• (at 0.75), held until the app is ready | — |

- **Cut safety:**
  - The splash is dismissed when Flutter draws its first frame (NFR-1 allows up to 1.5 s).
  - After 380 ms, every frame shows the h plus today in place.
  - Before 380 ms, a cut shows a moving block, which looks like a deliberate in-between frame, never a broken glyph.
- **Overshoot:** the squash and stretch break UI_DESIGN §6's "no overshoot" default on purpose. A thrown or landing object carries momentum, which is §6's own exception. Recorded as D44.
- **Animations off** (system animator scale 0): the AVD jumps to its last frame and the exit becomes an immediate `remove()`.

## 3. Colour

The splash background, the icon background and the Home background are the same colour in each mode. `windowSplashScreenIconBackgroundColor` is **not** set, so no circle is drawn.

| Resource | Light | Dark | Token |
|---|---|---|---|
| `splash_bg` | `#F6F5F1` | `#121211` | `bg` |
| `splash_mark` (h) | `#161615` | `#F2F1EC` | `ink` |
| `splash_outline` (today's outline) | `#161615` | `#00000000` | `ink` / none |
| `splash_day` (grey blocks) | `#DAD8D1` | `#3A3A37` | `line` / hero `track` |
| today's fill | `#FFB020` | `#FFB020` | `signal` |

- In light mode, the marigold dot carries a 1-unit ink outline (`strokeWidth` 1). This is the same treatment as the wordmark's dot on Home, because marigold never sits bare on the light background (UI_DESIGN §3.2).
- The launcher icon itself is unchanged (D32): h• on an ink field.

## 4. Android implementation

| File | Change |
|---|---|
| `android/app/src/main/res/values/splash_colors.xml`, `values-night/splash_colors.xml` | New. The five colours above |
| `android/app/src/main/res/drawable-v31/splash_icon.xml` | New AVD: an inline `aapt:attr` vector plus animators (§4.1) |
| `android/app/src/main/res/values-v31/styles.xml`, `values-night-v31/styles.xml` | New `LaunchTheme`: `windowSplashScreenBackground` @color/splash_bg, `windowSplashScreenAnimatedIcon` @drawable/splash_icon, `windowSplashScreenAnimationDuration` 800 (required on API 31–32), `windowSplashScreenBehavior` `icon_preferred` with `tools:targetApi="33"`. `NormalTheme`: `windowBackground` @color/splash_bg |
| `android/app/src/main/res/values/styles.xml`, `values-night/styles.xml` | `NormalTheme` `windowBackground` → @color/splash_bg, so no off-tone flash after the splash or on rotation |
| `android/app/src/main/res/drawable-v21/launch_background.xml` (+ `drawable/`) | API 24–30: `splash_bg` plus a centred static `splash_icon_static.xml` (the final frame) |
| `android/app/src/main/kotlin/com/widgetsandco/hisaab/MainActivity.kt` | Unchanged. The system's default exit fade is used (§8) |

### 4.1 AVD structure

Groups have no alpha in `VectorDrawable`, so fades animate `fillAlpha` and `strokeAlpha` on paths. Two translations are summed by nesting groups.

```
vector 108×108 viewport
└─ group mark      scale 0.75, pivot 54,54
   ├─ path h       stem + shoulder (ic_launcher_foreground pathData), fill splash_mark
   └─ group row    translateX 26→0
      ├─ group tomorrow   translateX 0→34
      │  └─ path tomorrow_block   fill splash_day, fillAlpha 0→0.6→0
      └─ group today      scaleX/scaleY, pivot 70.84,76
         ├─ path today_base     fill splash_day, pathData block→circle, fillAlpha 0→1, →0 at 560 (no grey fringe under the fill)
         ├─ group today_lit
         │  ├─ clip-path fill_clip   pathData: rect rising from y 76 to y 54
         │  └─ path today_fill       fill signal, pathData block→circle, fillAlpha 0→1
         └─ path today_outline  stroke splash_outline, width 1, pathData block→circle, strokeAlpha 0→1
```

- **Morph:** block and circle are both written as a rounded rect, `M L C L C L C L C Z`. The circle is the same rect with radius 8.13 and zero-length lines, so `pathData` animators can interpolate between them.
- **Animators:** one `objectAnimator` per table row, using `startOffset` + `duration` and an inline `pathInterpolator`.

## 5. Verify on device

These must be checked before the full build (the first plan task is a spike):

1. **Icon box size.** The doc gives two numbers: an icon "288×288 dp within a 192 dp circle", and an AVD "432 dp area, 288 dp inner". The spike must confirm that a 108-viewport AVD maps the r = 36 circle onto the visible mask. If not, adjust `android:width/height`.
2. **Grey fringe.** Check that `fillAlpha` and `clip-path` animate in the system-drawn splash and that no grey shows at the edge.
3. **OEM skins.** Watch for skins that show the AVD's first frame without animating it. That frame is an empty background. If any target device does this, fall back to a static icon on that device class.

There are no Dart changes, so no Dart tests change. `flutter analyze` and `flutter test` must stay clean, and `flutter build apk --release` must succeed.

**Hand-check matrix:** screen-record a cold start (`adb shell am force-stop` then launch) on a release build:

| | Light | Dark | Animations off |
|---|---|---|---|
| API 31 or 32 | unchecked | unchecked | unchecked |
| API 33+ (moto g45, API 35) | checked | checked | checked |
| API 24–30 (static) | unchecked | unchecked | — |

## 6. Docs to update in the build

- **UI_DESIGN:**
  - New §3.7 *Launch splash*, covering this spec's §2 and §3, and linking the mockup.
  - §6 gets a line saying the splash uses interpolators, because AVDs have no springs.
  - §10 gets a splash bullet.
- **SPEC:** new **NFR-9**. The splash never delays Home: it is dismissed on Flutter's first frame, its icon animation lasts 800 ms or less, and its colours match Home in each mode.
- **DECISIONS:** D41–D44 (D37–D40 were already taken).
  - D41: splash concept C★, and why it was chosen over A, A+, B and C1–C4.
  - D42: one colour from tap to Home, with an outlined dot in light mode instead of full-screen ink.
  - D43: the mark at 0.75 with one trailing day, because the mask slices a second one.
  - D44: squash overshoot allowed for the splash, and the default exit.

## 7. Out of scope, recorded

- **The in-app look setting (FR-SE-3) is not built yet.** When it is, Settings must call `UiModeManager.setApplicationNightMode()` (API 31+) over a small `MethodChannel`, so the splash follows the app's choice instead of the phone's. Until then, the splash follows the phone, which matches the default "Match phone".
- **Flutter-side handoff:** for example, the dot flying into today's Home block. This is a separate idea.

## 8. As built (device: moto g45, Android 15 / API 35)

- **§5.1 confirmed:** a 288dp vector with a 108 viewport maps the r = 36 circle onto the mask. This phone's mask is a rounded square that contains that circle, so content inside r 36 is safe on every mask shape.
- **The exit is the system default, not a custom listener.**
  - When Flutter's first frame lands, the system freezes the splash for about 250 ms while it hands over, with or without a listener.
  - With a listener, the icon then jumps to its last frame (grey block → dot).
  - Waiting for the remaining animation time only holds a frozen block.
  - The default fade already reads well, because the colours match Home.
- **Seen on this phone:**
  - On a release cold start, the splash freezes about 270 ms into the animation, so users see the arrival (the h and the blocks sliding in) and then the fade into Home.
  - The fill and the dot show on slower starts. The debug build shows the full run to the dot in both modes.
  - Showing the whole story on fast phones would mean holding Flutter's first frame, which NFR-9 rules out.
- **Checked on device:**
  - cold start in light and dark;
  - animations off: the last frame shows, then Home appears instantly;
  - warm start: the splash animates;
  - hot start: no splash;
  - mode change.
- **Unchecked:** API 31–32 and API 24–30. No emulator or system image was available.
