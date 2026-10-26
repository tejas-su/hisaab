# Launch Splash Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** a native Android 12+ animated splash (concept C★ "Aaj"), with the same background colour as Home in light and dark, and a static fallback on API 24–30.

**Architecture:** Android resources only:
- an `AnimatedVectorDrawable` set as `windowSplashScreenAnimatedIcon` in a v31 `LaunchTheme`;
- colour resources with `-night` variants;
- a 200 ms exit animation in `MainActivity`.

There is no Dart code and no new dependency.

**Tech Stack:** Android `SplashScreen` platform API (API 31+), AVD XML, Kotlin `FlutterActivity`.

**Spec:** `docs/superpowers/specs/2026-10-26-splash-screen-design.md`. Preview: `docs/design/mockups/09-splash.html` (`?t=<ms>` freezes a frame).

## Global Constraints

- `minSdk` 24 (Flutter default); `compileSdk` 36. Animation runs on API 31+ only.
- No new Gradle or pub dependency (CLAUDE.md, PLAN §11).
- **Colours:**

  | | Light | Dark |
  |---|---|---|
  | `splash_bg` | `#F6F5F1` | `#121211` |
  | `splash_mark` | `#161615` | `#F2F1EC` |
  | `splash_outline` | `#161615` | `#00000000` |
  | `splash_day` | `#DAD8D1` | `#3A3A37` |

  The fill is `#FFB020` in both modes.
- `windowSplashScreenIconBackgroundColor` is **never** set, so no circle is drawn.
- The icon animation lasts 800 ms. The start delay of 100 ms is under the platform's 166 ms cap.
- The splash never delays Home. No `setKeepOnScreenCondition` and no pre-draw hold beyond what `FlutterActivity` already does.
- The repo is local-only. Commit only when the user asks (CLAUDE.md), so this plan has no commit steps.

## Review Focus

1. **OEM skin draws the AVD's first frame without animating it.** The user would see an empty background. Task 1 checks this on the moto g45 (API 35).
2. **Mask mapping is wrong.** The 72-unit circle may not land on the visible mask, so blocks get sliced. Task 1's debug ring checks it.
3. **Animations turned off.** The splash must show the static h• and close at once. Task 3 checks this.
4. **Warm start** (back out, relaunch while the process is alive): the splash shows and animates again. **Hot start** (Home button, reopen): no splash. Task 3 checks both.
5. **Toggling dark mode** while the app is in the background, then relaunching: the splash must use the new mode's colours. Task 3 checks this.

Hardware note: the only connected device is a moto g45, API 35. API 31–32 and API 24–30 need emulators: `flutter emulators` / `avdmanager`. If none is available, report those cells of the matrix as unchecked; don't claim them.

---

### Task 1: Splash theme wiring + mask check (spike)

**Files:**
- Create: `android/app/src/main/res/values/splash_colors.xml`, `android/app/src/main/res/values-night/splash_colors.xml`
- Create: `android/app/src/main/res/values-v31/styles.xml`, `android/app/src/main/res/values-night-v31/styles.xml`
- Create: `android/app/src/main/res/drawable-v31/splash_icon.xml` (temporary content in this task)

**Interfaces:**
- **Produces:**
  - colour resources `@color/splash_bg`, `@color/splash_mark`, `@color/splash_outline`, `@color/splash_day`, `@color/splash_signal` (`#FFB020` in both files);
  - drawable `@drawable/splash_icon`.
- **Styles:** `LaunchTheme` and `NormalTheme` keep their names and parents from `values/styles.xml` and `values-night/styles.xml`. The manifest references them.

- [ ] **Step 1:** Write the colour files with the values in Global Constraints.
- [ ] **Step 2:** Write the v31 styles. Light parent is `@android:style/Theme.Light.NoTitleBar`; night parent is `@android:style/Theme.Black.NoTitleBar`.
  - `LaunchTheme` items:
    - `android:windowSplashScreenBackground` = `@color/splash_bg`
    - `android:windowSplashScreenAnimatedIcon` = `@drawable/splash_icon`
    - `android:windowSplashScreenAnimationDuration` = `800`
    - `android:windowSplashScreenBehavior` = `icon_preferred`, with `tools:targetApi="33"` and `xmlns:tools` on `<resources>`
  - `NormalTheme`: `android:windowBackground` = `@color/splash_bg`.
- [ ] **Step 3:** Write a temporary `splash_icon.xml` AVD.
  - Vector: `android:width="288dp" android:height="288dp"`, viewport 108×108.
  - Contents:
    - the h `pathData`, copied verbatim from `drawable/ic_launcher_foreground.xml` (both subpaths in one path), filled `@color/splash_mark`, inside a group with `scaleX/scaleY` 0.75 and pivot 54,54;
    - a debug ring path with `strokeColor` `#E5484D` and `strokeWidth` 0.5, drawn as a circle at (54, 54) r 36 and **not** scaled;
    - a 500 ms `translateX` 0→10 animator on the mark group, so you can see whether it animates.
- [ ] **Step 4:** Run `flutter run --release -d ZN4224TKBN`. Then do a cold start: `adb shell am force-stop com.widgetsandco.hisaab && adb shell monkey -p com.widgetsandco.hisaab -c android.intent.category.LAUNCHER 1`. Record with `adb shell screenrecord --time-limit 4 /sdcard/s.mp4` and pull it.

  **Expected:**
  - the red ring is just inside the visible mask edge, so the circle is not clipped and has no large gap;
  - the mark moves;
  - the background is `#F6F5F1` (light) or `#121211` (dark).

  **If the ring is clipped or very small:** change the vector's `android:width/height` (try `432dp`) and note the value that works in the spec's §5.1.

  **If nothing moves:** stop and report. That is Review Focus #1.

### Task 2: The C★ animated icon

**Files:**
- Modify: `android/app/src/main/res/drawable-v31/splash_icon.xml` (replace the Task 1 content; remove the debug ring and the test animator, keep the width that Task 1 confirmed)

**Interfaces:**
- **Consumes:** the colours from Task 1.
- **Produces:** the final `@drawable/splash_icon`.

- [ ] **Step 1: Write the vector tree.** Follow spec §4.1, with these exact names (animator targets):
  - groups: `mark`, `row`, `tomorrow`, `today`, `today_lit`;
  - paths: `h`, `tomorrow_block`, `today_base`, `today_fill`, `today_outline`;
  - clip-path: `fill_clip`.

  Group and path setup:
  - `today` pivot: `70.84,76`.
  - Initial values (the frame-0 state): `row` translateX 26; all `fillAlpha`/`strokeAlpha` 0.
  - `today_outline` uses `strokeWidth` 1 and `fillColor` `#00000000`.
  - `today_base` and `tomorrow_block` fill `@color/splash_day`; `today_fill` fills `@color/splash_signal`.

  Exact path data:

  ```
  TODAY_BLOCK  M68.34,56 L73.34,56 C75.55,56 77.34,57.79 77.34,60 L77.34,72 C77.34,74.21 75.55,76 73.34,76 L68.34,76 C66.13,76 64.34,74.21 64.34,72 L64.34,60 C64.34,57.79 66.13,56 68.34,56 Z
  TODAY_DOT    M70.84,59.74 L70.84,59.74 C75.33,59.74 78.97,63.38 78.97,67.87 L78.97,67.87 C78.97,72.36 75.33,76 70.84,76 L70.84,76 C66.35,76 62.71,72.36 62.71,67.87 L62.71,67.87 C62.71,63.38 66.35,59.74 70.84,59.74 Z
  TOMORROW     M84.34,56 L89.34,56 C91.55,56 93.34,57.79 93.34,60 L93.34,72 C93.34,74.21 91.55,76 89.34,76 L84.34,76 C82.13,76 80.34,74.21 80.34,72 L80.34,60 C80.34,57.79 82.13,56 84.34,56 Z
  CLIP_EMPTY   M40,76 L120,76 L120,76 L40,76 Z
  CLIP_FULL    M40,54 L120,54 L120,76 L40,76 Z
  ```

  The three today paths (`today_base`, `today_fill`, `today_outline`) start as `TODAY_BLOCK`. `fill_clip` starts as `CLIP_EMPTY`.

- [ ] **Step 2: Write the animators.**
  - One `<target>` per name. Each target holds a `<set>` of `objectAnimator`s, one per row below.
  - `pathData` animators use `android:valueType="pathType"`.
  - Interpolators are inline `<pathInterpolator>` elements, in an `aapt:attr`.

  | Target | Property | From→To | startOffset | duration | Interpolator |
  |---|---|---|---|---|---|
  | `row` | translateX | 26→0 | 100 | 280 | 0.25,0.5,0.6,0.9 |
  | `today` | scaleX | 1→1.16 | 100 | 100 | 0,0,0.2,1 |
  | `today` | scaleX | 1.16→1.06 | 200 | 180 | linear |
  | `today` | scaleX | 1.06→0.86 | 380 | 60 | 0,0,0.2,1 |
  | `today` | scaleX | 0.86→1 | 440 | 220 | 0.23,1,0.32,1 |
  | `today` | scaleY | 1→0.92 → 0.97 → 1.08 → 1 | same offsets/durations as scaleX | | same |
  | `today_base` | fillAlpha | 0→1 | 100 | 120 | linear |
  | `today_base` | fillAlpha | 1→0 | 559 | 1 | linear |
  | `today_fill` | fillAlpha | 0→1 | 100 | 120 | linear |
  | `today_outline` | strokeAlpha | 0→1 | 100 | 120 | linear |
  | `fill_clip` | pathData | CLIP_EMPTY→CLIP_FULL | 380 | 180 | 0.2,0,0,1 |
  | `today_base`, `today_fill`, `today_outline` | pathData | TODAY_BLOCK→TODAY_DOT | 520 | 280 | 0.23,1,0.32,1 |
  | `tomorrow_block` | fillAlpha | 0→0.6 | 240 | 100 | linear |
  | `tomorrow_block` | fillAlpha | 0.6→0 | 380 | 90 | linear |
  | `tomorrow` | translateX | 0→34 | 380 | 220 | 0.4,0,1,1 |

  Every animator sets `android:valueFrom` explicitly, because sequential segments share a property.

- [ ] **Step 3: Check it on the device.** Do the Task 1 Step 4 cold start in light and in dark (`adb shell cmd uimode night yes|no`). Pull frames: `ffmpeg -i s.mp4 -vf fps=30 f%03d.png`.

  **Expected**, compared against `docs/design/mockups/09-splash.html?t=160|260|340|420|470|520|650|900`:
  - today fades in and slides; tomorrow appears whole at about 300 ms;
  - squash at about 400 ms, then the marigold rises;
  - tomorrow is gone by about 470 ms; the last frame is the round dot;
  - in light mode the dot has an ink outline; no grey fringe shows around the finished dot;
  - no block is ever visibly sliced.

### Task 3: Exit animation, static fallback, edge cases

**Files:**
- Modify: `android/app/src/main/kotlin/com/widgetsandco/hisaab/MainActivity.kt`
- Modify: `android/app/src/main/res/values/styles.xml`, `android/app/src/main/res/values-night/styles.xml`: set `NormalTheme` `android:windowBackground` to `@color/splash_bg`
- Create: `android/app/src/main/res/drawable/splash_icon_static.xml`. This is the final frame: the h plus `TODAY_DOT` filled with signal, the outline in `@color/splash_outline`, scaled 0.75 around 54,54, width and height 288dp, and no animation.
- Modify: `android/app/src/main/res/drawable/launch_background.xml` **and** `android/app/src/main/res/drawable-v21/launch_background.xml` (v21 is the one actually used, since `minSdk` is 24):
  - a `layer-list` of `@color/splash_bg`;
  - `<item android:drawable="@drawable/splash_icon_static" android:gravity="center" android:width="288dp" android:height="288dp"/>`.

**Interfaces:**
- **Consumes:** `@color/splash_*` from Task 1.

- [ ] **Step 1:** Override `onCreate(savedInstanceState: Bundle?)` in `MainActivity`. Before `super.onCreate`, and only on `Build.VERSION.SDK_INT >= Build.VERSION_CODES.S`, call `splashScreen.setOnExitAnimationListener { view -> … }`:
  - If `!ValueAnimator.areAnimatorsEnabled()`, call `view.remove()`.
  - Otherwise, animate together over 200 ms with `PathInterpolator(0.4f, 0f, 1f, 1f)`:
    - `view` alpha 1→0;
    - `view.iconView` scaleX and scaleY 1→0.96.

    Call `view.remove()` when it ends.
  - Add a one-line `// why:` comment: Flutter has already drawn Home underneath, because `FlutterActivity` holds the first draw until the first Flutter frame.
- [ ] **Step 2:** Run `flutter build apk --release`. **Expected:** `BUILD SUCCESSFUL`, with no new lint errors on the resources.
- [ ] **Step 3: Check on the device.** Run each case and record it:
  - **(a) Cold start, light and dark.** The splash fades into Home with no colour step.
  - **(b) Animations off.** Run `adb shell settings put global animator_duration_scale 0` (also `transition_animation_scale` and `window_animation_scale`). Expect the static h• and an instant switch. Restore all three to `1` afterwards.
  - **(c) Warm start.** Press back to the launcher, then relaunch. The splash animates again.
  - **(d) Hot start.** Press Home, then reopen. There is no splash.
  - **(e) Mode change.** Switch dark mode in system settings while the app is in the background, force-stop the app, then launch. The splash uses the new colours.
- [ ] **Step 4: API 24–30, if an emulator is available.** A cold start shows the static h• centred on `splash_bg` in both modes. Otherwise, report it as unchecked.
- [ ] **Step 5:** Run `flutter analyze && flutter test`. **Expected:** both clean, the same as before the change. No Dart code changed, so the coverage script does not apply.

### Task 4: Docs

**Files:**
- Modify: `docs/UI_DESIGN.md`:
  - add §3.7 *Launch splash*, after §3.6. Summarise spec §2 (story, timing table) and §3 (colours), state that the mark is at 0.75 with one trailing day, and link `docs/design/mockups/09-splash.html`;
  - in §6, add one line: the splash uses `pathInterpolator` curves, not spring tokens, because an AVD has no springs, and its squash overshoot is an exception (D40);
  - in §10, add a bullet: the splash is native, one colour from tap to Home, and static below API 31.
- Modify: `docs/SPEC.md` §6: add the row `NFR-9`. "The launch splash never delays Home: it is dismissed on Flutter's first frame. Its icon animation lasts 800 ms or less. Its background matches Home's in light and dark (UI_DESIGN §3.7)."
- Modify: `docs/DECISIONS.md`: append rows D37–D40 as listed in spec §6. Give the date 2026-10-26, and include the rejected alternatives (A, A+, B, C1–C4; full-screen ink in light mode; a second trailing day; critically damped landing).
- Modify: `docs/superpowers/specs/2026-10-26-splash-screen-design.md`:
  - change the status to "built";
  - record the confirmed icon size from Task 1 in §5.1.

- [ ] **Step 1:** Make the edits above.
- [ ] **Step 2:** Check: `grep -n "NFR-9" docs/SPEC.md && grep -n "D40" docs/DECISIONS.md && grep -n "3.7 Launch splash" docs/UI_DESIGN.md`. **Expected:** one hit each.
