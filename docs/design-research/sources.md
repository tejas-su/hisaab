# Research sources

Where to look for UX/UI evidence, what each source is good for, and its limits. Prefer sources at the top; inspiration sites show what something looks like but rarely why.

| Source | Good for | Limits |
|---|---|---|
| [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) | Rules with reasons: lists, segmented controls, layout, motion. The `.md` URLs (for example `…/lists-and-tables.md`) fetch cleanly | iOS-first, so map it to Android and Material |
| [Material Design 3](https://m3.material.io/) and [Android developers](https://developer.android.com/develop/ui/compose/components) | Android conventions: chips, radio rows, bottom sheets. Google Pay follows these | m3.material.io pages often don't fetch, so use the Android developer docs |
| [Nielsen Norman Group](https://www.nngroup.com/) | Research-backed rules on forms, dropdowns, radio buttons and checkboxes | Web-first; little on mobile cards |
| [Mobbin](https://mobbin.com/) | Real app screens and flows (Monzo, Revolut, Rocket Money, Duolingo), and a glossary of component variants | Needs a login, and pages return 403 to fetch tools. Search results give screen titles only, so open them in a browser |
| [Dribbble](https://dribbble.com/) | Visual ideas and styling; company profiles such as [CRED](https://dribbble.com/cred-design) | Concept shots, often not shipped or tested. Use for look, not for UX evidence |
| [Behance](https://www.behance.net/) | Longer write-ups of a redesign's process, such as the [slice revamp](https://behance.net/gallery/167349583/Mobile-App-Visual-Revamp-Slice) | Mostly brand and illustration, rarely screen-level UX |
| [Pinterest](https://www.pinterest.com/) | Mood boards; search terms such as "Multiple Choice Quiz Ui Design" | Board pages only, mostly 2016–2021 pins. Not evidence |
| [screensdesign.com](https://screensdesign.com/) | Recorded onboarding flows (Duolingo) | Captions are thin, so watch the recordings |
| [UI Patterns](https://ui-patterns.com/), [AI UX Playground](https://aiuxplayground.com/) | AI patterns: prompt starters, suggested prompts, with named product examples | Pattern libraries, not research |
| [Fluent 2](https://fluent2.microsoft.design/typography) | Microsoft's type ramp with Regular / Strong / Stronger per size, and colour de-emphasis | Fetches cleanly |
| [IBM Carbon](https://carbondesignsystem.com/elements/typography/overview/) | Type sets (productive vs expressive), the weight-vs-size balance, token tables | Fetches cleanly |
| [Atlassian Design](https://atlassian.design/foundations/typography) | Heading and body tokens; "hierarchy with heading styles" | Web-first |
| [GitHub Primer](https://primer.style/foundations/typography) | Weight tokens, line length | The page is thin; tokens are on a separate page |
| [Shopify Polaris](https://polaris-react.shopify.com/design/typography) | Type tokens | The fetch failed (connection closed); retry in a browser |
| [Lazyweb research](https://www.lazyweb.com/research/) | Counts across many apps (for example single- vs multi-select) | Small samples; treat ratios as directional |
| [uxdesign.cc](https://uxdesign.cc/), Medium case studies | Critiques and teardowns (Duolingo, Jupiter) | Opinion pieces; some pages return 403 to fetch tools |
| [Vercel Geist](https://vercel.com/geist/introduction) | A grey scale where each step has a job; append `.md` to any page for clean markdown | No dark values, governance or contrast on the doc pages. `design.md` is agent-facing brand rules |
| [Vercel Web Interface Guidelines](https://vercel.com/design/guidelines) | Focus, interaction-contrast and motion checklists | Web (CSS) terms; map them to Flutter |
| [Carbon migration FAQ and guide](https://carbondesignsystem.com/migrating/faq/) | Token deprecation and rename practice | Mapping tables are on GitHub, not on the site |
| [Radix Colors docs](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale) | A 12-step scale with a use for each step; pairing greys with accents; aliasing | Fetches cleanly; web-first, no governance |
| [Primer primitives repo](https://github.com/primer/primitives) | Theme list, contrast test config, token-removal CI | Raw GitHub files fetch cleanly; primer.style pages truncate |
| [Atlassian elevation](https://atlassian.design/foundations/elevation), [colour](https://atlassian.design/foundations/color) | Elevation levels, dark surfaces, focus vs selection | The colour page sometimes returns empty; retry |
| [Flutter API: ColorScheme](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.html), [MediaQueryData](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html) | Real fallback behaviour of Material roles; which OS settings reach Flutter, from which API level | The implementation line is often the only place a default is stated |
| [`@groww-tech/mint-css` on unpkg](https://app.unpkg.com/@groww-tech/mint-css@0.4.0/files/dist/fragments/allVariables.css) | Groww's actual token names and hex values | The only public MINT artefact; no docs or rationale; npmjs.com returns 403 |
| [Razorpay Blade repo](https://github.com/razorpay/blade) | INR `Amount` decisions, per-mode tokens | The Storybook site needs JavaScript; read the raw files |

## Indian fintech
slice, Google Pay, CRED, Jupiter and Fi have little public screen-level material. Use Mobbin in a browser, or install the app and record the screens, before citing how they do something.
