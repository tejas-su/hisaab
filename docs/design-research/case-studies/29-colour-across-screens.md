# 29. Colour across screens: LCD, AMOLED, Vivid modes, Night Light and daylight

Case studies 08, 09, 19 and 28 and `docs/design/colour-proposal.md` settle how hisaab's colours are built. None of them asks how those colours *arrive* on a phone. The proposal's §11 listed an on-device check "on a low-end LCD in daylight" and case study 28 says it was never done. This study does the desk half of that check, with arithmetic, and turns the rest into a test protocol.

## Question
How do colours vary across screen types (LCD, AMOLED, "vivid" modes, warm filters, sunlight, low brightness), and which of hisaab's tokens are fragile on them? What can be generalised, and is per-panel fine-tuning possible on Android?

## Method
Desk research on 2026-11-11, plus my own arithmetic. No device, no user. I had no shell, so every ratio, luminance or gain below that I worked out is marked *(calc)*. They use the WCAG 2 formula, `(L1 + F) / (L2 + F)`, where `F` is the flare constant ([WCAG 2.2, Understanding 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html): `0.05` is "based on Typical Viewing Flare"). My numbers reproduce hisaab's published 1.17, 1.30, 1.53 and 6.14 at `F = 0.05`, so I trust them to about 0.01. Items marked **seen** come from a page I read. Items marked **inferred** are my reading. Items marked **background** are from general knowledge that I did not source, and the report says so.

Search-summary sources are flagged each time, because the fetch tool returned only part of several pages (see Sources and access).

### The one model used for outdoors and dim rooms
A screen's light adds to light reflected off its glass. Treat the reflected light as a constant `F`, a fraction of the display's white luminance. Then any pair of luminances `L1 > L2` shows as `(L1 + F) / (L2 + F)`. The Wikipedia entry on [display contrast](https://en.wikipedia.org/wiki/Display_contrast) says it in words ("ambient light is reflected from the display surface, adding to the luminance of the dark state") and gives a TV example falling from 1,000,000:1 to about 350:1 at 100 lx. DisplayMate defines a phone's high-ambient score as maximum brightness divided by reflectance and calls reflectance "the most important parameter for a mobile display" ([DisplayMate, via search summary](https://www.displaymate.com/Mobile_Brightness_ShootOut_2.htm)).

For `F` I use three cases. They are **assumptions**, not measurements:
- `F = 0.05`: the WCAG constant, a normal room.
- `F = 0.3`: for example 480 nits of white and about 145 nits reflected (about 9,000 lx on a 5% reflective glass, *(calc)*, Lambertian).
- `F = 1.0`: reflected light equal to the screen's white, as in bright shade on a 10% reflective screen at about 15,000 lx *(calc)*.

The measured data points I found: the moto g45 reached about 482 nits "under direct sunlight with Auto Brightness on" and about 220 nits indoors at maximum, and its reviewer had to shade it to read messages ([Digit](https://www.digit.in/reviews/mobile-phones/motorola-g45-5g-review-bringing-5g-to-the-masses-in-style.html)). DisplayMate's measured reflectance ranged from 4.4% to 14.8% on the phones it tested then (same source). So `F = 0.3` to `1.0` are plausible for a budget LCD outdoors in shade, and direct sun is worse than my worst case.

## Sources and access
| Source | Read? | Notes |
|---|---|---|
| [Android: wide colour gamut](https://developer.android.com/training/wide-color-gamut) | Yes | Official: Android 8.0+, `colorMode` opt-in, and what happens on a display that is not colour managed |
| [Flutter issue 153517](https://github.com/flutter/flutter/issues/153517) | Yes | Flutter engineer on Impeller colour spaces. Closed as not planned |
| [Flutter: `Paint.enableDithering` breaking change](https://docs.flutter.dev/release/breaking-changes/paint-enableDithering) and issues [#134250](https://github.com/flutter/flutter/issues/134250), [#132860](https://github.com/flutter/flutter/issues/132860) | Search summary only | I did not open the page; the summary says gradients are dithered by default, web excepted |
| [Flutter `MediaQueryData.invertColors`](https://api.flutter.dev/flutter/widgets/MediaQueryData/invertColors.html) | Yes | "Currently only updated on iOS" |
| [Apple HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color.md) | Yes | Fetches cleanly; sunlight and device-testing advice, P3 vs sRGB |
| [APCA in a Nutshell](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell) | Yes | Says nothing on ambient light or black level. Only its scope ("self-illuminated RGB computer displays") and Lc 15 and 30 floors |
| [WCAG 2.2 Understanding 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) | Yes | sRGB assumption, the 0.05 flare constant, thin fonts render fainter than their colour |
| Wikipedia: [Display contrast](https://en.wikipedia.org/wiki/Display_contrast), [LCD](https://en.wikipedia.org/wiki/Liquid-crystal_display) (first 100k of 206k characters), [OLED](https://en.wikipedia.org/wiki/OLED) (first 100k of 256k), [PenTile](https://en.wikipedia.org/wiki/PenTile_matrix_family), [IPS panel](https://en.wikipedia.org/wiki/IPS_panel) | Yes | Background only. The LCD page has no TN/IPS/VA contrast numbers, no 6-bit or IPS-glow text. The IPS page covers neither. The Burn-in page is about component testing, not displays. [Mini-LED](https://en.wikipedia.org/wiki/Mini-LED) and [DC dimming](https://en.wikipedia.org/wiki/DC_dimming) returned **404** |
| [DisplayMate](https://www.displaymate.com/Mobile_Brightness_ShootOut_2.htm), [smart phone shoot-out](https://www.displaymate.com/smart_phone_shootout.htm) | Search summary | Reflectance and CR for high ambient light. The pages themselves were not opened |
| [Digit: Moto G45 review](https://www.digit.in/reviews/mobile-phones/motorola-g45-5g-review-bringing-5g-to-the-masses-in-style.html) | Yes | Panel type, measured nits, sunlight verdict |
| [GSMArena Moto G45](https://m.gsmarena.com/motorola_moto_g45-13267.php) | Search summary | The page itself returns 402 (`tollbit.gsmarena.com`). Spec figures via search: 6.5" IPS LCD, 1600 x 720, about 269 ppi, 120 Hz, Gorilla Glass 3 |
| [Samsung Members: Vivid or Natural](https://r1.community.samsung.com/t5/galaxy-s/vivid-or-natural/td-p/13053597), [GSMArena S24 vividness slider](https://m.gsmarena.com/newscomm-61597p2.php) | Search summary | User comments, not lab data. Samsung's own page (`ushl.samsung.com`) did not resolve |
| [Pixel Help: Night Light](https://support.google.com/pixelphone/answer/7169926), [SamMobile on night modes](https://www.sammobile.com/news/how-do-phone-night-mode-features-work/) | Search summary | Names and settings; mechanism is consumer-level. AOSP internals not read |
| [Material: dark theme (m2)](https://m2.material.io/design/color/dark-theme.html) | Search summary | The fetch returned the title only. `#121212`, 15.8:1 and 87% white come from the summary |
| [GSMArena: OnePlus 8 Pro display reports](https://www.gsmarena.com/users_report_multiple_display_issues_on_the_oneplus_8_pro-news-42856.php), [XDA green tint](https://xdaforums.com/t/green-tint-on-oled.4289057/), [Samsung Members smear](https://r2.community.samsung.com/t5/Galaxy-A/black-smearing-in-lowlight/td-p/5529720), [Lowestonweb](https://lowestonweb.com/why-do-some-users-report-black-crush-on-oled-smartphones/), [blackbackground.net](https://blackbackground.net/pure-vs-near-black) | Search summary | User reports and blogs. GSMArena's page returns 402. Anecdotal; treat as low confidence |
| [Mobolist: PWM vs DC dimming](https://www.mobolist.net/en/blog/pwm-dimming-vs-dc-dimming-which-is-better-for-your-eye-health-complete-guide), [Notebookcheck analysis](https://www.notebookcheck.net/Analysis-DC-Dimming-vs-PWM-Can-you-dim-AMOLED-displays-without-the-flickering.423121.0.html) | Summary only | Notebookcheck's text was not retrieved. The sources disagree on the direction of the low-brightness shift (cooler/greener or warmer/redder) |
| [Barco: ambient light compensation](https://www.barco.com/en/support/knowledge-base/3872-what-is-ambient-light-compensation-and-why-is-it-so-important), [Handprint](https://www.handprint.com/HP/WCL/color4.html) | Search summary | The Weber fraction of about 1–2% and the 17% to 5.5% worked example. The AVIXA/InfoComm PDF redirected away |
| [Hardforum 6-bit FRC](https://hardforum.com/threads/6-bit-frc-vs-true-8-bit.2002923/), [hardwaretest.org](https://hardwaretest.org/color-gradient-test/) | Search summary | Forum opinion and a test page. Nothing phone-specific |
| Budget-phone lists ([Alibaba Q&A](https://electronics.alibaba.com/question/best-phones-under-%E2%82%B915,000-in-india-(2026)), [Poco M7 Pro](https://en.wikipedia.org/wiki/Poco_M7_Pro_5G)), [Display Daily 2026](https://displaydaily.com/the-smartphone-panel-market-faces-a-reality-check-in-2026/), [BusinessToday on Counterpoint](https://www.businesstoday.in/technology/news/story/samsung-leads-indias-smartphone-market-again-but-phones-under-rs20000-face-a-47-slump-563299-2026-10-23) | Search summary | Blog-grade spec lists. **No share of AMOLED against LCD in India was found**, and Counterpoint's piece does not cover display type |

Not found at all: a source on Xiaomi, Realme or Moto "Saturated/Natural" mode gamuts; a source on LTPO's colour behaviour; one on mini-LED in phones; AOSP's Night Light matrix; any measured white-point spread for budget phones.

## Findings

### A. What the panel types do to colour
1. **LCD blacks are lifted and its contrast is about 1000:1 in the generic case.** The LCD article cites a "1000:1 contrast ratio of the LCD panel" for the panel before dynamic backlight tricks ([Wikipedia: LCD](https://en.wikipedia.org/wiki/Liquid-crystal_display)). OLED "can turn off individual pixels showing true black" ([Wikipedia: OLED](https://en.wikipedia.org/wiki/OLED)). **Seen.** The practical consequence is only in the dark: DisplayMate says OLED's contrast advantage is "visually insignificant except under dark ambient lighting" when brightness is set properly ([DisplayMate, summary](https://www.displaymate.com/Mobile_Brightness_ShootOut_2.htm)).
2. **Reflectance, not panel type, decides daylight.** Measured reflectance runs 4.4% to 14.8%, and an LCD (iPhone 5, 4.5%) matched an OLED on the high-ambient score while another LCD sat at 15 to 19 (DisplayMate summary). **Seen**, from a summary of old phones. Applied to hisaab: no panel type is "safe outdoors"; the moto g45 is a plain case (IPS, about 220 nits indoors maximum, 482 nits in sun, "poor on bright days", Digit).
3. **Off-axis shifts differ by technology.** TN has "visible gamma shift"; VA shows "color and especially contrast shift"; IPS is the wide-angle choice ([Wikipedia: LCD](https://en.wikipedia.org/wiki/Liquid-crystal_display), first 100k characters). Nothing I could read covers OLED's off-axis colour shift or IPS glow. **Background (unsourced):** OLED panels shift towards blue or green off-axis, and IPS panels glow on black from an angle. Neither matters for flat, light surfaces held in the hand, so I did not look further.
4. **AMOLED panels often use a PenTile (RGBG) layout, which can look grainy on saturated red or blue edges.** The page says text on RGBG "can appear grainy... with blurred text on some saturated colors and backgrounds" and that the effect is mainly at red or blue boundaries ([Wikipedia: PenTile](https://en.wikipedia.org/wiki/PenTile_matrix_family)). The article calls its own resolution claims disputed. **Inferred:** hisaab's warm-neutral edges are near-neutral and marigold is red-green, so this is a small risk. It bears on 1dp hairlines and the etch, which are thin low-contrast lines.
5. **Blue OLED material ages fastest**, so static bright UI can shift colour balance with time ([Wikipedia: OLED](https://en.wikipedia.org/wiki/OLED): blue degraded 12% against 7–8% for red and green after 1,000 hours in a 2008 report). The OLED page I read says burn-in is a risk "compared to LCDs"; I found no phone-specific data on a persistent dock. **Inferred:** a light page averages out, and hisaab's static pieces (the dock, the top bar) are near the page colour, so the risk is low.
6. **Banding is mostly an 8-bit and low-bit problem, and Flutter already dithers gradients.** Sources agree a 6-bit panel has 64 native levels, shows banding on shadow gradients, and that FRC "may appear as slight noise" instead ([hardwaretest.org](https://hardwaretest.org/color-gradient-test/), [Hardforum](https://hardforum.com/threads/6-bit-frc-vs-true-8-bit.2002923/), summaries; forum-grade). Flutter now dithers all gradients by default on Skia and Impeller, but not on web ([Flutter breaking-change page, summary](https://docs.flutter.dev/release/breaking-changes/paint-enableDithering)). The dither is one 8-bit step, so it hides 8-bit banding and cannot hide a 6-bit panel's coarse steps. **Inferred.** I found no data on how many Indian budget phones are 6-bit.

### B. Gamut, "vivid" modes and Android colour management
7. **Flutter on Android draws in plain sRGB.** A Flutter engineer: "The dart:ui Color class is absolutely positively sRGB right now," and with Impeller "iOS uses extended sRGB by default... on Android and others regular sRGB is used" ([Flutter #153517](https://github.com/flutter/flutter/issues/153517)). Wide gamut needs the `android:colorMode="wideColorGamut"` opt-in on the activity, which "has no effect" on a device that cannot do it ([Android docs](https://developer.android.com/training/wide-color-gamut)). I found nothing showing Flutter sets it. **Seen**, with the caveat that I could not check hisaab's manifest. (Not opened; the owner should confirm no `colorMode` is set.)
8. **On a display that is not colour managed, Android stretches app colours to the panel's gamut.** The docs: "A display might be wide color gamut capable but not color-managed... the system remaps the colors drawn by the app to the display's gamut" ([Android docs](https://developer.android.com/training/wide-color-gamut)), and this was true of every Android before 8.0. **Seen.** User comments say Samsung's Vivid is DCI-P3 with saturated colours, Natural is sRGB, and that Vivid "saturates everything past sRGB" ([Samsung Members](https://r1.community.samsung.com/t5/galaxy-s/vivid-or-natural/td-p/13053597), forum-grade). Samsung later added a "Vividness" slider after complaints that Vivid looked bland ([GSMArena, summary](https://m.gsmarena.com/newscomm-61597p2.php)). I found **no** source for Xiaomi, Realme or Moto modes. **Inferred:** a stretched mode applies to hisaab's sRGB values on some phones, by user choice or default.
9. **I computed what a P3 stretch does to hisaab's colours, assuming it treats sRGB codes as Display P3 codes** *(calc)*, using the standard P3 and sRGB matrices from memory.
   - Marigold `#FFB020`: linear sRGB-equivalent about (1.13, 0.41, -0.04) against (1.00, 0.43, 0.014). More saturated and a little more orange-red (green falls 6%); luminance rises about 1% (0.524 to 0.531). So contrast against `bg` and against `ink` barely moves, and the ink-edge rule still holds. Hue shift is the only real change.
   - `bg` `#F1EBE4`: red rises 1.2 points of linear and blue falls 0.7 points. The red-to-blue ratio goes from 1.134 to about 1.16 (+3%), so a warm tint becomes about 15 to 20% more chromatic in R-minus-B terms. The tint does not vanish; it gets slightly stronger.
10. **Apple's HIG says the same thing in its own terms.** sRGB "produces accurate colors on most displays"; P3 colours "appear fine on sRGB displays" but gradients can clip and near-identical P3 colours can be hard to tell apart ([Apple HIG](https://developer.apple.com/design/human-interface-guidelines/color.md)). That supports staying in sRGB. It is iOS-first, so only the principle transfers.
11. **WCAG and APCA both assume a normal sRGB screen and say little about glare.** WCAG: "Almost all systems used today to view web content assume sRGB" and the 0.05 flare constant is a "typical" value ([WCAG Understanding](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)). APCA is "specifically optimized for... self-illuminated RGB computer displays" and treats Lc 15 as "invisible" and Lc 30 as the absolute minimum for spot text ([APCA](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell)). Neither tells us what a ratio becomes at `F = 0.3`.

### C. Night Light, Extra Dim, inversion and brightness
12. **Night Light is a software colour shift, not a filter.** It "dims the blue channel and boosts red and yellow", moving colour temperature from about 6500K to 3000–4500K, and it has an intensity slider and a schedule ([SamMobile](https://www.sammobile.com/news/how-do-phone-night-mode-features-work/), [Pixel Help](https://support.google.com/pixelphone/answer/7169926), both consumer-level). Samsung calls it Eye Comfort Shield; Xiaomi, OnePlus, Oppo and Vivo use "Eye Comfort" (same SamMobile summary). **Seen**, mechanism only.
13. **Extra Dim lowers brightness below the normal minimum, and colour inversion and correction are system-wide** ([Droid Life](https://www.droid-life.com/2021/04/24/android-12-extra-dim-awesome-feature/), summary; the setting needs API 31). An app **cannot detect inversion on Android**: Flutter's `invertColors` is "currently only updated on iOS" ([Flutter API](https://api.flutter.dev/flutter/widgets/MediaQueryData/invertColors.html)). *(calc)* Inversion turns marigold `#FFB020` into `#004FDF`, a blue, and the light theme into a dark-looking one. hisaab's meaning does not rest on hue, so this is safe by construction (CLAUDE.md: "state is shown by fill, outline, hatch and words").

### D. OLED near-black and low brightness
14. **Material chose `#121212` rather than black, and hisaab's dark page is the same luminance.** Material: dark grey surfaces show elevation and depth better, reduce eye strain compared with black, and should reach 15.8:1 against white text so even raised surfaces pass 4.5:1 ([Material, summary](https://m2.material.io/design/color/dark-theme.html)). *(calc)* `#121212` has relative luminance 0.0060 and hisaab's `#131210` has 0.0061: the same step in luminance. hisaab's `ink` `#F2F1EC` is 16.6:1 on it, above Material's 15.8:1. **Seen**, and it is a point in hisaab's favour.
15. **Near-black crush, "black smear" and a tint at the lowest brightness are widely reported, but only by users and blogs.** Reports: GSMArena describes near-black quantisation moving from black to dark greys; "less bit depth is allocated at low brightness" is a user's guess; green tint at minimum brightness that goes away at higher brightness ([XDA](https://xdaforums.com/t/green-tint-on-oled.4289057/), [Samsung Members](https://r2.community.samsung.com/t5/Galaxy-A/black-smearing-in-lowlight/td-p/5529720), [Lowestonweb](https://lowestonweb.com/why-do-some-users-report-black-crush-on-oled-smartphones/), all summaries). A blog says `#121212`-class greys avoid smear in motion ([blackbackground.net](https://blackbackground.net/pure-vs-near-black)); that is one blog's claim. **Low confidence on cause, and no source gives a code value below which a panel crushes.** PWM versus DC dimming explains some of it: low-voltage OLED drive can bring colour shift and banding in dark gradients, though sources disagree on the shift's direction ([Mobolist](https://www.mobolist.net/en/blog/pwm-dimming-vs-dc-dimming-which-is-better-for-your-eye-health-complete-guide), summary).

### E. Layers and text under glare and low contrast
16. **Glare compresses ratios, but flat-field steps stay far above a visibility threshold.** The Weber fraction (smallest visible step as a share of background) is about 1–2% in normal viewing, and larger at very low luminance ([Handprint](https://www.handprint.com/HP/WCL/color4.html), [Barco](https://www.barco.com/en/support/knowledge-base/3872-what-is-ambient-light-compensation-and-why-is-it-so-important), summaries). Barco's own example: a step of 0.30 to 0.35 cd/m² is 17% with no ambient light and 5.5% with it. I used 2% as the yardstick. *(calc)* Table 1 shows hisaab's light layers keep at least about 7% at `F = 1.0`, so they stay visible; the dark layers do not.

**Table 1. Contrast ratio *(calc)* and step (ΔL/L) of each pair at three flare levels.** Relative luminances *(calc)*: light `surface` 0.992, `bg` 0.839, `sunk` 0.753, `hairline` 0.631, `ink2` 0.095, `ink` 0.008, `signal` 0.524; dark `bg` 0.00606, `surface` 0.0139, `sunk` 0.0248, `hairline` 0.0377, `ink2` 0.360, `ink` 0.879.

| Pair | F 0.05 (design) | F 0.3 | F 1.0 | ΔL/L at F 1.0 |
|---|---|---|---|---|
| Light: page to card (`surface` on `bg`) | 1.17 | 1.13 | 1.08 | 8.3% |
| Light: card to `sunk` | 1.30 | 1.23 | 1.14 | 13% |
| Light: `hairline` / idle block on card (floor 1.5) | 1.53 | 1.39 | 1.22 | 22% |
| Light: `hairline` vs `sunk` (press floor 1.15) | 1.18 | 1.13 | 1.07 | 7.4% |
| Light: `ink2` on `bg` | 6.15 | 2.9 | 1.68 | n/a |
| Light: `ink` on `bg` | 15.3 | 3.7 | 1.82 | n/a |
| Light: `signal` on `bg` | 1.55 | 1.38 | 1.21 | n/a |
| Light: `ink` on `signal` (Add key label) | 9.9 | 2.7 | 1.51 | n/a |
| Dark: `bg` to `surface` | 1.14 | 1.03 | 1.01 | 0.8% |
| Dark: `surface` to `sunk` | 1.17 | 1.03 | 1.01 | 1.1% |
| Dark: `sunk` to `hairline` | 1.17 | 1.04 | 1.01 | 1.3% |
| Dark: `ink` on `bg` | 16.6 | 3.9 | 1.87 | n/a |
| Dark: `ink2` on `bg` | 7.3 | 2.2 | 1.35 | n/a |

Reading: in glare **every text pair falls below 4.5:1, even `ink` on the page**, so colour cannot fix outdoor legibility: `ink` is already near the darkest and the lightest available. Only size, weight and the OS's brightness boost help. **Light layers survive** at 7% or more even at `F = 1.0`, three to four times the 2% yardstick. **Dark layers do not**: at `F = 0.3` they are 2.5–4%, at the edge of visibility, and at `F = 1.0` about 1%. **Inferred:** dark theme is for rooms and evenings, so this matters less, and nothing in the palette can restore it.

17. **Thin, low-contrast marks lose more than flat fields.** WCAG notes thin fonts "may render much fainter than their defined color" ([WCAG Understanding](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)). On the moto g45, 269 ppi means about 1.7 px per dp (*calc*, ppi / 160). A 1dp line of 1.17:1 (the hero etch) covers about 68% of one pixel on average, so its step falls from 15% to about 10% *(calc)* before glare. It is still above 2%. **Inferred:** the etch is visible but faint on a 720p LCD and could read as grain or dust instead of a pattern. It carries no meaning (D106), so the cost is only decorative.

### F. The tint is smaller than the panels' white point
18. **A white point shift of 1000K changes the warm tint more than candidates A, B and C differ from one another.** *(calc)* I took approximate chromaticities from memory for 5500K (x 0.332, y 0.341), D65 (0.3127, 0.3290) and 7500K (0.299, 0.315), converted each to linear sRGB gains (red, green, blue), and multiplied `bg`:

| Panel white | Gains (R, G, B) | `bg` A `#F1EBE4` | `bg` B `#EEECE7` | `bg` C `#F3EBE1` |
|---|---|---|---|---|
| Neutral D65 | (1.00, 1.00, 1.00) | R/B 1.134 | 1.070 | 1.190 |
| Warm 5500K | (1.14, 0.97, 0.86) | 1.50 | 1.42 | 1.58 |
| Cool 7500K | (0.93, 1.01, 1.14) | 0.92 | 0.87 | 0.97 |

   R/B above 1 means warm; below 1 means the page is bluish. The spread across panels (a factor of 1.63 in the gain ratio) is about 4 to 5 times the spread from B to C (1.11), measured in logs. On the cool panel **all three candidates read bluish-white**; on the warm one all read orange-cream. **The assumption that cheap panels spread 5500–7500K is mine and unsourced** (I found no measured white-point data); but D108's chroma 0.011 is so small that even a few hundred kelvin of error is the same order of magnitude *(calc)*.
19. **Night Light has the same effect, only stronger and on purpose.** At 3000–4500K it dims blue ([SamMobile](https://www.sammobile.com/news/how-do-phone-night-mode-features-work/)), so by the table above every neutral turns yellow-orange. Neutrals lose blue; marigold has almost none to lose (`#FFB020` blue is 32 of 255), so marigold shifts the least and the page moves *toward* it. **Inferred:** hue contrast between page and marigold shrinks, and luminance, the ink edge and the label keep the meaning.
20. **A hypothesis worth five minutes on the owner's phone.** The moto g45 is the test phone (D134) and the owner says the light page looks "unpainted". If its white point is cool, a warm tint of 0.011 could be cancelled by the panel, which would make the complaint a panel effect and not a palette effect. **Inferred only; I have no measurement.** The check is in the protocol (step 1).

### G. The Indian low-end market
21. **The owner's test phone is a budget IPS LCD, and AMOLED is common only a little above it.** The moto g45 is a 6.5" IPS LCD, HD+, 120 Hz, Gorilla Glass 3, ₹10,999 (4/128) at launch, with no HDR (Digit, [search summary of GSMArena](https://m.gsmarena.com/motorola_moto_g45-13267.php)). Reviewers' recurring complaint is the LCD ("look elsewhere if you want an AMOLED"). Blog lists of ₹15,000 phones show both: AMOLEDs at 1,200–2,100 nits peak (Redmi Note 14 5G, Poco M7 Pro, Realme 14, Infinix Note 50X) and LCDs at 400–450 nits (the same Alibaba list, Realme Narzo 90x, Poco M7 Plus). The sources contradict each other on the Galaxy M17's panel. **I found no share of AMOLED against LCD in India.** One blog claims the sub-₹15,000 band is "90%+ LCD" without a source, so ignore it. Omdia reportedly has AMOLED ahead of TFT-LCD globally since 2024 ([Display Daily, summary](https://displaydaily.com/the-smartphone-panel-market-faces-a-reality-check-in-2026/)). Counterpoint reports sub-₹20,000 shipments fell 47% in Q3 2026 ([BusinessToday](https://www.businesstoday.in/technology/news/story/samsung-leads-indias-smartphone-market-again-but-phones-under-rs20000-face-a-47-slump-563299-2026-10-23)), so the mix is moving up, but that page says nothing about panels.
22. **So hisaab's tests have an AMOLED hole.** Every near-black and Vivid finding above applies to phones the owner may not have. This is the biggest gap.

### H. What the platforms say
23. **Apple:** test "under a variety of lighting conditions" because "in bright surroundings, colors look darker and more muted. In dark environments, colors appear bright and saturated"; test on different devices; supply an increased-contrast variant for each custom colour ([Apple HIG](https://developer.apple.com/design/human-interface-guidelines/color.md)). That is the same protocol this study proposes. **Material:** a dark grey base and 15.8:1 text (finding 14). **Fluent:** I did not retrieve any Fluent guidance on displays; none is claimed.

## Fragile tokens: risk table
Risk is for hisaab's *meaning and use*, not for looks. **Seen** = a source; **calc** = my arithmetic from Table 1; **inferred** = my reading.

| Token or pair | LCD, normal | LCD, outdoors (F 0.3–1) | AMOLED / Vivid | Night Light | Low brightness | Risk | Margin or fix |
|---|---|---|---|---|---|---|---|
| Page to card 1.17 | Fine | 1.13 to 1.08, ΔL/L 8–13% (calc) | Same luminance (calc); Vivid changes chroma only | Same ratio | Fine | **Low** | Keep. Don't go below about 1.10 (peer floor, case 28) |
| Card to `sunk` 1.30 | Fine | 1.23 to 1.14 | Same | Same | Fine | **Low** | Keep |
| Press floor 1.15 (`hairline` vs `sunk`) | Fine | 1.13 to 1.07, 7–13% | Same | Same | Fine | **Low-medium** | Keep the floor in tests; make sure a press also has a second cue (the existing haptic and the label), not colour alone |
| Idle blocks 1.5 (`blockIdle` = `hairline`) | Fine | 1.39 to 1.22, ΔL/L 22%+ | Same | Same | Fine | **Low** | Keep. Today's block has marigold plus the ink edge |
| Etch under 1.2:1 and grain | Visible, faint; 1.7 px/dp on 720p | About 9% step, then glare | PenTile may speckle it (inferred) | Same | Fine | **Low** (decorative) | Keep it decorative; never put a number or hatch meaning on it. Check it doesn't read as dirt on the moto g45 |
| Warm tint, chroma 0.011 | Changes with panel white point by far more than the tint itself (calc) | Same | Vivid adds about 15–20% chroma (calc) | Overwhelmed by the filter | Not affected | **High for look, none for meaning** | Do not tune per panel. Judge A/B/C on at least one cool LCD, one warm and one AMOLED, plus Night Light |
| Marigold `#FFB020` | Fine, never bare | 1.38 to 1.21 on `bg` (calc) | Vivid: more orange, luminance +1% (calc); ink edge holds | Moves least; page moves toward it | Fine | **Low** (colour), **medium** for the label on it in sun | `ink` on marigold falls to 2.7:1 at F 0.3 (calc); keep the Add key's text large and heavy, and shape and position carry the meaning |
| Dark `#131210` | Black lift helps, not hurts | Dark layers 1.03 to 1.01 (calc) | Same luminance as Material's `#121212` (calc); smear and crush reports are anecdotal | Mild | Codes 16–19 sit where some panels quantise coarsely (inferred) | **Medium** (OLED, min brightness) | Test, don't guess: a near-black ramp on two OLEDs at minimum brightness (protocol step 5). Don't use `#000` anywhere that animates |
| Dark layer steps 1.14 / 1.17 / 1.17 | Fine in a room | At the visibility edge by F 0.3 (calc) | Fine in a dark room | Fine | Fine | **Medium in daylight only** | Accept; no palette fix exists. Dark theme in sun is a known limit; keep the `hairline` edge on cards |
| Dark `ink` `#F2F1EC` / `ink2` `#A7A199` | 16.6 / 7.3 | 3.9 / 2.2 | Fine | Slightly yellower | Fine | **Low indoors** | Keep; `ink` is not pure white (Material's own reason) |
| `ink2` light, 13sp | 6.15 on `bg` | 2.9 at F 0.3 (calc) | Fine | Fine | Fine | **High in glare, by physics** | Only size and weight can help; keep body captions at 13sp or larger and never put essential info in `ink2` alone |
| `displaySheen`, gradients, the 32dp dock fade (D82) | Dithered by Flutter | Fine | Fine | Fine | 6-bit panels: coarse steps | **Low-medium** | Check on a 6-bit-suspect LCD (protocol step 7); keep fades short and never between two near-equal tints over a long run |
| `danger` `#B42318` hold key (D142) | Fine | Fine | Vivid richer red | Slightly orange | Fine | **Low** | Meaning is a label, so inversion or Vivid can't change it |

## Recommendations

### Generalise: rules that hold on any screen
1. **Stay in sRGB; don't opt into wide colour.** Flutter draws sRGB on Android (finding 7). Wide gamut would help nothing in a one-marigold app and would add memory and GPU cost on low-end phones ([Android docs](https://developer.android.com/training/wide-color-gamut)). *Applies to:* `design-platform`.
2. **Keep meaning off hue and off tint.** hisaab already does (fill, outline, hatch, words). Add the tint: no screen may need the viewer to see that two neutrals differ in warmth. Findings 18–20 show a panel or filter can erase it or triple it.
3. **Set minimum layer steps in terms of glare, not paper ratios.** Table 1 gives a usable rule *(calc)*: a light surface step should keep ΔL/L of about 6% or more at `F = 1.0`, which is three times the 2% yardstick. Today's 1.17, 1.30 and 1.53 pass; 1.17 is 8.3% (the page-to-card step is the closest). The press floor passes with 7.4%, so don't lower it from 1.15. Dark layers cannot meet it, so don't add dark steps that rely on tone alone.
4. **Don't try to rescue outdoor text with colour.** `ink` is already the extreme. Where legibility in daylight matters (the hero amount, the Add key's label), use size and weight, which hisaab's type scale already favours.
5. **Avoid long, shallow gradients between near-equal neutrals.** Flutter dithers, but a 6-bit panel's native step is about 4 codes wide. Prefer short fades or flat fills.
6. **Treat the dark page as a floor.** `#131210` is Material's `#121212` in luminance. Don't go darker, and don't animate from `#000` (principle 29 already covers `clear`).
7. **Add a second cue wherever a ratio under 1.2 is the only cue.** For pressed keys and the etch it is already true. Make it a review question in `design-system`.

### Fine-tune: per-panel tuning
**Not possible and not wise.** Evidence: Android exposes whether a display is wide-gamut (`Display.isWideColorGamut()`), not its panel type, white point, Vivid state or whether Night Light is on ([Android docs](https://developer.android.com/training/wide-color-gamut)); Flutter reports inversion only on iOS ([API](https://api.flutter.dev/flutter/widgets/MediaQueryData/invertColors.html)); and the OS already raises brightness outdoors (482 nits in sun against 220 indoors on the moto g45, Digit). An ambient-light "outdoor mode" would need a sensor package (not in PLAN §11; **ask first**) and would duplicate auto-brightness. Per-panel tuning would also need a test device per panel, which hisaab doesn't have. What *is* tunable is the user's own **increased-contrast token set** proposed in case study 06; whether the Android setting reaches Flutter is an open question below. Otherwise: choose values that survive the spread and test them.

## What it means for candidates A, B and C (case study 28)
- **All three have the same luminances**, so every row of Table 1 is the same for A, B and C. Contrast, glare and dark-mode behaviour do not separate them.
- **They differ only in tint**, and the tint is the least robust thing in the palette (finding 18). On a cool panel all three look bluish-white; C reads closest to neutral-warm (R/B 0.97) and B furthest from it (0.87). On a warm panel or Night Light, all three go orange-cream, with C most (1.58 against 1.50 and 1.42).
- **B is the most likely to read "unpainted" on a cool LCD**, because it was the page the owner already called unpainted (`#EEECE6`, case 28) and it has the least warm to lose. **C is the most likely to read "beige" on warm panels and at night.** **A is in the middle**, where neither failure is worst. This is an **inference** from my gain table, not a test, and it does not argue for A over the others on looks.
- **Before choosing a tint, check whether the moto g45's white point explains the complaint** (protocol step 1). If it is cool, no neutral change fixes the owner's view of their own phone, and the more useful lever is the one case 28 already named (surface mass or the ink hero, D106).
- **Don't evaluate the three on a monitor.** A monitor shows the intended sRGB and hides everything above.

## Test protocol
**Hardware needed** is marked **[hw]**. The rest can be done at the desk.

1. **[hw] White-point check, 5 minutes.** On the moto g45 at 50% brightness, Night Light off, Adaptive colours off if present, open a pure `#FFFFFF` swatch beside a sheet of plain white paper in daylight. Note whether the screen looks bluer, equal or warmer. Repeat on any second phone. Record the model and the colour setting (Natural, Vivid, Saturated).
2. **[hw] Layer and text chart on each device.** One test page (a mockup in `docs/design/mockups/`, to be built by `design-validation`) showing the real `bg`, `surface`, `sunk`, `hairline`, `blockIdle`, an `ink2` caption at 13sp, marigold on `bg` with the ink edge, a 1dp etch sample and the Add key. Pass if all pairs in Table 1's light rows are visible at 40 cm. Record brightness (minimum, 50%, maximum) and any lux reading from a phone app (approximate).
3. **[hw] Glare.** Stand in open shade, then facing a window, at maximum brightness with auto brightness on. Fail if a layer edge or the Add key is not locatable in 2 seconds. Photo each state. Expect the text rows to fail; record which words still read (hero amount, tiles).
4. **[hw] Modes.** Repeat step 2 with: Night Light or Eye Comfort at full intensity; Extra Dim; colour inversion; high-contrast text; the phone's Vivid/Saturated and Natural modes; Dark theme. Pass if every screen is still usable and no meaning rests on hue.
5. **[hw] OLED near-black.** On two AMOLED phones, at minimum and 50% brightness, open a near-black ramp of codes 0 to 40 (steps of 2) and the dark theme's four layers. Record the lowest code distinguishable from 0 and whether the four layers separate. If `#131210` (about code 19) merges with black on any phone, raise the dark floor to the first code that holds on all. Then scroll a list of dark cards and note smear.
6. **[hw] Off-axis.** Tilt each phone about 30 to 45 degrees. Note any tint shift on `bg` and `surface` and whether the hero's etch changes.
7. **[hw] Banding.** View the dock's 32dp fade, the sheen pass and the Day Blocks' fill on a cheap LCD. Note stepping.
8. **Desk simulation.** Apply a per-channel gain (Table above) and a flare `F` to screenshots with a small script: `out = (lin + F) / (1 + F)` in linear light, after the gain; this reproduces Table 1 and is a rough aid only. The sandbox can't run it.
9. **Cheap device matrix.** The moto g45 (IPS, D134); one budget AMOLED at about ₹12–15k (a Redmi Note, Poco M7 Pro, Realme 14, Samsung Galaxy M/A series; borrowing counts); one older LCD phone with a visible cool tint. Add the emulator only for layout, not colour.
10. **People, optional.** Five people, Hindi and English, each shown candidates on their own phone: "which looks cleaner, which looks like paper". Preference only; confidence stays low (case 28).

## Implications for the other agents
`docs/DECISIONS.md` wins until a new row changes it. None of these changes a row.
- **design-system:** add Table 1's `F = 1.0` column to the contrast-pair report beside the WCAG figures, as information only (floors stay as they are). Record that the tint carries no meaning. If the dark floor moves after step 5, that needs a new row against D92.
- **design-platform:** confirm the manifest sets no `colorMode`; document that hisaab is sRGB by design; check whether Flutter on Android reports `highContrast`; no "outdoor mode".
- **design-accessibility:** treat glare as a low-vision condition the palette cannot fix; add colour inversion and Extra Dim to the TalkBack/low-vision test list; confirm nothing relies on hue under inversion (marigold becomes blue).
- **design-validation:** build the chart in step 2 and run the protocol; record results as a follow-up to this study.
- **design-product:** the A/B/C decision should wait for step 1.

## Conflicts to note
- **D134** names the moto g45 as the test phone. It is an LCD, so no AMOLED check exists anywhere in the project.
- **D108** (hue about 75°, chroma 0.003–0.016): findings 18–19 say the warm tint is below panel and filter tolerance. That is not a reason to change D108, because meaning never rests on it, but it is a reason not to promise "warm" on every phone.
- **colour-proposal §11** step 3 (the on-device check) is still undone; this study narrows it but does not complete it.
- **D106** (etch under 1.2:1) holds as a decorative choice (finding 17).

## Open questions
- What is the moto g45's white point and brightness at the owner's usual setting? (hardware, step 1)
- Does the owner's "unpainted" complaint survive on a warm-white or AMOLED phone? (hardware)
- At what code does the dark page merge with black on common budget AMOLEDs at minimum brightness?
- Does the Android high-contrast setting reach Flutter, and does case study 06's increased-contrast token set cover glare? (`design-platform`)
- What are real white points and gamuts for Redmi, Realme, Moto and Infinix defaults (Natural, Standard, Saturated)? I found none.
- What share of Indian budget phones is AMOLED against LCD, and how many LCDs are 6-bit with FRC? Needs Counterpoint, IDC or teardown data.
- Does Android's Night Light use the same gain shape as my approximation? The AOSP source was not read.
- Do the exact P3 stretch numbers (finding 9) hold on a Vivid phone? A photo of a swatch and a colorimeter app would tell.

## Gaps in this research
- No device, no meter, no user: everything on phones is desk or my arithmetic.
- No measured white-point data. Panel gains in finding 18 are my approximations (chromaticities from memory) and the 5500–7500K range is an assumption.
- I did not source: IPS glow, OLED off-axis shift, TN/IPS/VA contrast figures, LTPO's colour behaviour, mini-LED, 6-bit prevalence, or Xiaomi/Realme/Moto mode gamuts.
- Many sources are search summaries, forum posts and blogs (flagged). Material's page and Samsung's own page did not load.
- The flare model assumes a Lambertian, grey reflection and an `F` I chose. Real glass, polarisers and anti-reflective coatings vary (OLED's metallic cathode reflects up to about 80% before a polariser cuts it, [Wikipedia: OLED](https://en.wikipedia.org/wiki/OLED)).
- The 2% Weber yardstick is for large uniform fields; small, thin or textured items need more.

## Verification (2026-11-11)
- The glare figures were re-run by script, adding F to both luminances. They match the hand calculations: `ink`/`bg` 3.69 at F 0.3; `ink2`/`bg` 2.88; `ink`/`signal` 2.68; `surface`/`bg` 1.14 at F 0.3 and 1.084 at F 1.0; `sunk`/`surface` 1.136 at F 1.0; the press (`hairline`/`sunk`) 1.075 at F 1.0; dark `surface`/`bg` 1.03 at F 0.3 and 1.008 at F 1.0. F remains an assumed value, not a measurement.
- `android/app/src/main/AndroidManifest.xml` sets no `colorMode`, so the app renders in sRGB as finding 1 expects.
