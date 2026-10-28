# 04. Floating dock and pinned top bar (Home, Spends)

## Job of the screen
Home and Spends scroll between a pinned top bar (wordmark or title, Settings or the cycle switcher) and the floating bottom dock (Home · Add · Spends). Add is the app's main act. The question: what sits behind the dock while content scrolls, and how the top bar should look once content is under it.

## What was wrong
- The dock sat in an opaque `bg` strip, so cards were cut off by a hard line above it.
- A fully transparent strip (tried) let cards and buttons show beside and below the white pill, slicing text ("See Food entries") and competing with Add. Taps near the pill could land on half-hidden content, and focus could park rows behind the dock.
- A fade from the bottom edge to the dock's middle (tried) still showed card corners beside the pill, and the white pill merged with white cards above its middle.
- The frosted top bar (80% `bg`, 24σ blur) smeared the marigold Ask AI well into a blob by the status bar (`fade2.png`, `optD.png`), and blurred amounts passed under it.

## Research
- **Apple, iOS 26 scroll edge effect:** scroll views get an automatic effect "between scrolling content and stationary controls". `hard` is "a linear, nearly opaque boundary"; `soft` is "a subtle, blurred boundary" that is translucent where the bar overlaps the list and "gets progressively more opaque from the top to the bottom" ([ScrollEdgeEffectStyle](https://developer.apple.com/tutorials/data/documentation/swiftui/scrolledgeeffectstyle.md)).
- **Apple, where the effect comes from:** the blur behind a tab bar is the scroll view's edge effect, set up by `UITabBarController`; a standalone custom bar gets none and must use `UIScrollEdgeElementContainerInteraction` ([Apple forum 791643](https://developer.apple.com/forums/thread/791643), [795643](https://developer.apple.com/forums/thread/795643)). Custom bars that render their own blur don't merge cleanly with the system one ([803378](https://developer.apple.com/forums/thread/803378)).
- **Apple, when to go hard:** with lots of custom buttons at an edge, a hard edge avoids clutter; content "cut[s] off sharply rather than blur and dim" ([Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-adjust-the-scroll-edge-effect-for-scrollview-and-list)).
- **Apple, the tab bar itself:** iOS 26 tab bars float and are Liquid Glass, with the selected tab as a glass capsule ([STRV](https://www.strv.com/blog/how-to-apply-liquid-glass-to-your-app), [Play docs](https://docs.createwithplay.com/en/articles/liquid-glass)). The HIG tab-bar page and the `soft`/`hard` symbol pages render in JavaScript and couldn't be read; the claims above come from the markdown doc and the linked posts.
- **Telegram for Android (redesign, February 2026):** it dropped the side menu for a floating bottom bar (Chats, Contacts, Settings, Profile) in a Liquid Glass style, with rounded cards and blurred translucent backgrounds that react to scrolling ([Droid Life](https://www.droid-life.com/2026/02/10/telegram-on-android-gets-massive-redesign/), [GSMArena](https://m.gsmarena.com/telegram_interface_redesign_android_ios-amp-71505.php), [AMOverview](https://www.amoverview.com/telegram-android-gets-major-liquid-glass-ui-revamp-with-ios-style-navigation/), [leak thread](https://x.com/yabhishekhd/status/2019958263341846779)). Telegram says the interface was rebuilt for efficiency and points users to Settings › Power Saving for performance. Not found: whether content runs under the bar, any fade at its edge, or a switch for the blur (one outlet's "refraction slider" is unconfirmed). Not checked on a device.
- **OneKey (React Native, Android bottom tabs):** a floating capsule over live blur, a translucent tint, and a 24dp gradient covering the bottom strip including the gap below the capsule. On by default only on Android 16 (API 36) and up; older versions keep a plain bar. The blur samples at quarter resolution to stay cheap ([PR #160](https://github.com/OneKeyHQ/app-modules/pull/160)).
- **Material 3 Expressive:** Google has floating *toolbars* (contextual actions) but, as of May 2025, no floating *navigation* bar; the navigation bar is docked, and Google advises against showing a toolbar and a navigation bar together ([9to5Google](https://9to5google.com/2025/05/18/material-3-expressive-toolbars/)). Floating toolbars can scroll off-screen, but stop reacting to scroll while TalkBack is on ([Compose `FloatingToolbarScrollBehavior`](https://developer.android.com/reference/kotlin/androidx/compose/material3/FloatingToolbarScrollBehavior)).
- **What the floating-bar apps share:** a glass pill (blur and tint) and content visible through it, plus a gradient or soft edge where content meets the bottom. Without glass, only the gradient part carries over, which is what D82 keeps.
- **Independent UX and UI reviews (2026-10-28)**, given the screenshots and this spec but not each other's view: both ranked the fade-above-solid dock first and transparent last; both said to fade the same colour's alpha, never to `Colors.transparent` (a grey smear in dark mode). For the top bar, both said to drop the blur: on `#EEECE6` vs `#FFFEFB` (about 3% luminance apart) it reads as smudge, not material, it leaks marigold, and it costs GPU on low-end phones.

## Patterns compared
| Pattern | Add salience | Noise | Mis-taps | Fit |
|---|---|---|---|---|
| A. Opaque strip (before) | Good | None | None | Hard cut mid-card |
| B. Transparent, content under the dock | Weak | High | Yes | Drop |
| C. Fade from the bottom edge to the dock's middle | Fair | Some | Yes, if the fade blocks taps | Drop |
| D. 32dp eased fade above the dock, solid `bg` behind it (built) | Best | None | None | Apple's `soft` shape, without glass |
| E. Frosted dock or strip | Weak | Blotchy | — | Glass needs a glass pill; ours is opaque white |

## Why not copy Apple or Telegram exactly
Apple runs content under the bar because the bar is glass: you see the content through it, and the soft edge keeps the controls legible. Our pill is opaque `surface` with a hairline, so content behind it is never seen, only its slivers around the edges. D keeps Apple's progressive fade at the boundary and drops the part that only works with glass. Telegram and OneKey make the same choice on Android, glass pill plus blur, and OneKey limits it to Android 16+ for cost. The same argument applies to the top bar: Apple's blur works over photos and varied content, not over near-white cards on warm grey.

## Recommendation
- **Dock:** D, built (D82). The list's bottom 32dp fades into `bg` on a smoothstep ramp (alpha 0, .16, .5, .84, 1). Taps pass through, high contrast drops the fade, and the last card rests above it.
- **Top bar:** keep it pinned; replace the glass with an opaque `bg` bar and a hairline that fades in on scroll (D84), as the Material 3 small top app bar does. A 16dp fade under the bar (UI review) was rejected: no Android app we checked does it, and it is mainly iOS 26's glass-bar effect.

## Risks
- Without glass, the app reads less "iOS 26". Acceptable for this audience; the spec already limits glass to navigation.
- The fade takes 32dp of viewport. Check the visible height at 2× text on a 320dp phone and in landscape.
