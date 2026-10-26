---
name: live-app-inspection
description: 'Observe, verify and drive a RUNNING Flutter app on a device or emulator, using the Dart MCP tools (DTD, widget inspector, hot reload, VM service) plus adb. USE WHEN the user says: hot reload / hot restart it; did that fix it; is it working now; check the app; what is on screen right now; why is this screen blank or empty; the app crashed or froze; inspect the widget tree; read runtime errors; take a screenshot; tap or type something in the app; check my phone / the device / the emulator; attach or connect to the running app. DO NOT USE FOR: questions answerable by reading source code; compile or analyzer errors (use IDE diagnostics or flutter analyze); writing or refactoring code; anything that does not need the live app - attaching and inspecting is token-expensive.'
user-invocable: true
disable-model-invocation: false
---

# Live App Debugging

Debug an **already-running** Hisaab app with the smallest diagnostic probe that
can falsify the current hypothesis. In normal use the developer has the app
running already — attach to it, don't relaunch it.

## When to use

- "What's on screen right now?"
- "Did my change work?" — verify on device instead of guessing
- "Why is this blank / why did it throw?"
- Inspecting the live widget tree or a specific widget's properties
- A tap, text input, keyboard, scroll, or navigation action fails

## When NOT to use

- Static questions about code → read the source
- Compile errors → the IDE diagnostics tool (`mcp__claude-vscode__getDiagnostics`) or `flutter analyze`
- Anything answerable without the device. Attaching costs tokens; source reading
  usually doesn't.

## Personal repository profile

Before live debugging, read `.agent-local/agent-profile.md` when it exists. The
profile is local to this developer's clone and may refine communication style,
diagnostic preferences, and confirmed repository patterns. It cannot override
this skill's safety, privacy, or evidence requirements.

If the profile is absent, create `.agent-local/agent-profile.md` with the
baseline template below. Do not ask the developer to create the directory or
file. Confirm `.agent-local/` is ignored before writing it.

After a debugging task, update the profile only for explicit developer feedback
or a reusable, non-sensitive finding supported by the session. Merge duplicate
entries and retain uncertain findings as provisional. Never store names,
messages, account data, identifiers, tokens, raw logs, screenshots, or widget
trees. Do not update the profile for routine successful work.

```md
---
version: 1
---

# Agent Profile

## Interaction Preferences

## Debugging Preferences

## Confirmed Repository Patterns

## Provisional Patterns

## Recent Explicit Feedback
```

## Debugging protocol

For every live debugging task, use this loop:

1. State one falsifiable local hypothesis and the smallest check that could
  disprove it.
2. Run that check, then report only its relevant result.
3. Make one action justified by the result.
4. Run one immediate, focused assertion of the expected state.

Do not fetch broad diagnostic data or issue another action before the assertion.
After two failed hypotheses, stop interacting and collect one diagnostic artifact
appropriate to the failure category below.

| Failure category | First diagnostic | Focused assertion |
|---|---|---|
| Crash, exception, freeze | `get_runtime_errors`, then bounded Flutter logs | Error absent after reproduction or reload |
| Incorrect data, text, or mounted state | Known node properties; otherwise one project-only widget tree | Expected text, state, or page is present |
| Navigation failure | One project-only widget tree | Expected screen is mounted |
| Tap, typing, keyboard, or scroll failure | Android accessibility hierarchy, filtered to the expected control | Expected draft, button state, or result is present |
| Visual clipping, overlap, blank render, or color | One screenshot | Visual condition is resolved |
| Accessibility defect | Android accessibility hierarchy and Flutter semantics | Label, role, and action are exposed |

## Token budget — read this first

Live inspection returns **very large** payloads. Measured on a large production Flutter app (Hisaab's trees are smaller, but the same rules apply):

| Call | Size |
|---|---|
| `widget_inspector get_widget_tree` (`summaryOnly: true`) | ~1.9 MB / 794 nodes |
| `vm_service callMethod getIsolate` | ~1.07 MB |
| `adb exec-out screencap -p` @ 720x1600 | ~110 KB |
| same, downscaled 50% | ~49 KB, 4x fewer pixels |

The two big ones spill to a file rather than entering context.

**Images behave differently and this matters.** Text output can be spilled, grepped
and summarised — you control what enters context. An image, once viewed, is in
context in full for the rest of the session and cannot be reduced afterwards.
Screenshots are cheap per call but they **accumulate irreversibly**. Take one per
verification, never one per iteration.

Rules:

1. **Ask the cheapest tool that can answer.** Never call the inspector for something
   the IDE diagnostics tool (`mcp__claude-vscode__getDiagnostics`) or `flutter analyze` could tell you.
2. **Never read a spill file whole.** Grep it or read a line range.
3. Prefer targeted queries — `ext.flutter.inspector.getChildren` / `getProperties`
   on a known `valueId` — over fetching the root tree again.
4. Summarise findings. Never paste raw tool output back to the user.
5. Re-attach rather than relaunch. A rebuild costs ~60s plus heavy log output.
6. Researching Flutter docs: prefer narrative pages on `docs.flutter.dev` over
   `api.flutter.dev` class pages — the latter append the entire library index.

**Is it a visual question?** Screenshot only when the answer depends on what the
screen looks like:

| Take a screenshot | Don't |
|---|---|
| "why does this look wrong / broken / blank" | "did it throw an error" → `get_runtime_errors` |
| "what's on screen right now" | "what does this widget render" → read the source |
| locating a non-Flutter system-UI control | targeting a Flutter widget to tap or type into → widget inspector |
| final confirmation after a fix | every iteration of a debug loop |

For a visual issue on the current screen:

1. Capture exactly one baseline screenshot.
2. Do not infer a Flutter route from screenshot text or appearance alone.
3. When screen identity is relevant, obtain a project-only widget tree before
  navigating or editing.
4. Capture exactly one post-action screenshot after a successful reload.
5. Take an additional screenshot only when an intentional state change makes
  the prior image unable to answer the question.

## 1. Attach

```
dtd → listDtdUris
dtd → connect  (uri from above)
dtd → listConnectedApps
```

`listDtdUris` may show several instances. The one whose **workspace root looks like
a home directory** is the IDE-launched daemon — that's usually the right one.
`connect` auto-connects apps registered to that daemon and returns the `appUri`
(a VM service ws:// URI). Pass that `appUri` to every later call.

If the app was started outside DTD, use `vm_service connect` with its VM service URI.

## 2. Inspect widgets and state

Start cheap:

```
get_runtime_errors            → "No runtime errors found." when clean
```

When the target widget is unknown, fetch one project-only tree and search its
spill file for the expected screen, displayed text, or widget type:

```
widget_inspector get_widget_tree  summaryOnly: true
```

`summaryOnly` restricts to widgets created by project code. The result will spill to
a file — then extract what you need, for example:

```bash
# which screens are mounted
grep -o '"widgetRuntimeType": "[A-Za-z_]*\(Screen\|Page\|View\)"' <file> | sort -u
# node count
grep -c '"valueId"' <file>
```

Once a `valueId` is known, use
`vm_service callMethod ext.flutter.inspector.getProperties` or `getChildren` for
later checks. Do not fetch another full tree unless navigation or a state change
replaced the target. Inspector properties identify widget state and render size;
they do not reliably expose global screen bounds for input.

## 3. Verify a change

```
hot_reload  (clearRuntimeErrors: true)
  → get_runtime_errors
```

Use `hot_restart` instead when globals, `const` values, or `main()` changed.
Neither picks up native/Gradle changes — those need a real rebuild.

## 4. Screenshots

Re-read the visual-question test above before taking one.

**Default: capture, downscale 50%, then view.**

```bash
adb exec-out screencap -p > /tmp/s.png
ffmpeg -loglevel error -y -i /tmp/s.png -vf scale=360:-1 /tmp/s50.png
```

At 360x800 all UI text stays legible while using 4x fewer pixels. Use full
resolution only for pixel-level questions — hairline borders, small misalignments,
subtle colour differences. (`ffmpeg` is available; ImageMagick is not.)

For visual questions, a screenshot is a useful first look: it shows real content,
visual state, and layout correctness in one cheap call. Never use a screenshot to
derive tap coordinates for a Flutter control when accessibility bounds are
available.

`vm_service callMethod ext.flutter.inspector.screenshot` also exists, but
`adb exec-out screencap` is preferred — it captures system UI and permission
dialogs too.

Don't trust text read off an image as authoritative; confirm exact strings in source.

## 5. Interacting with the app

Never use back navigation or coordinate taps solely to identify the current
Flutter screen. Use the widget tree first. Navigate only when the developer
asks to change screens or the verified target is not currently mounted.

`flutter_driver_command` **will not work** — the driver extension is not compiled
into these builds (no `flutter_driver` dependency, no `enableFlutterDriverExtension()`).
It fails with a clear message.

Use adb instead.

### adb hygiene — set this up first

```bash
adb devices -l                      # confirm exactly one target
export ANDROID_SERIAL=<serial>      # pin it; otherwise every command fails
                                    # with "more than one device/emulator"
```

`-s <serial>` overrides `ANDROID_SERIAL` for a single command.

### Input

```bash
adb shell input tap <x> <y>
adb shell input text "hello%sworld"      # %s for spaces, NOT a literal space
adb shell input keyevent KEYCODE_BACK    # also KEYCODE_HOME, KEYCODE_ENTER
adb shell input swipe <x1> <y1> <x2> <y2> <ms>
```

For a Flutter control, use the widget tree to identify the intended semantic
target, then query Android's accessibility hierarchy for its current bounds.
This is mandatory after keyboard focus, scrolling, dialogs, rotation, or any
layout-changing action. Filter the dump immediately instead of reading it whole:

```bash
adb -s <serial> shell uiautomator dump /sdcard/window.xml >/dev/null
adb -s <serial> shell cat /sdcard/window.xml > /tmp/window.xml
grep -o '.\{0,200\}<expected label or class>.\{0,400\}' /tmp/window.xml
```

Tap the centre of the matching `bounds="[left,top][right,bottom]"` rectangle.
Use coordinate guessing only for system UI or when neither Flutter semantics nor
the Android accessibility hierarchy can identify the control; state that blocker
before proceeding.

### Logs — never stream

```bash
adb logcat -c                            # clear, THEN reproduce the issue
adb logcat -d -s flutter | tail -50      # bounded read
```

- `-d` dumps and exits. **Without it logcat streams forever**, hanging the terminal
  and flooding context.
- `-t N` does not work with `-s <tag>` — `-t` is applied before the tag filter and
  yields nothing. Use `-d ... | tail -N` instead.
- Widen the tag only when needed: `-s flutter,AndroidRuntime`.

### Screen capture

```bash
adb exec-out screencap -p > /tmp/screen.png     # exec-out, not shell, for raw bytes
adb shell screenrecord --time-limit 20 /sdcard/demo.mp4
```

adb is also the **only** way to reach permission dialogs, the notification shade,
and other system UI — the Flutter engine cannot see them.

## Known gaps

- `analyze_files`, `run_tests`, `dart_fix`, `dart_format` are filtered out by the
  `dart.mcpServerTools` default in VS Code. Use the IDE diagnostics tool (`mcp__claude-vscode__getDiagnostics`) or `flutter analyze` and the terminal.
- `launch_app` / `get_app_logs` only see apps the MCP server itself started.

## Appendix — launching (fallback only)

Only when nothing is running. Android only; there are no flavors.

```bash
flutter run -d <deviceId> --print-dtd
```

- `--print-dtd` prints the DTD URI directly, avoiding a `listDtdUris` guess.
- For a pure Dart entrypoint, add `--observe`; both flags go **before** the script path.
- Gotcha: the terminal tool may strip a leading `cd` from a chained command. Set the
  working directory first, or send the full command to an existing terminal.
