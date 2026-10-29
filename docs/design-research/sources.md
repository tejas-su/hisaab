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
| [Refactoring UI: building your colour palette](https://refactoringui.com:443/previews/building-your-color-palette) | How many greys and shades a system needs; dark grey, not black | Only the preview chapter is free |
| [`better-colors` skill](https://skills.sh/jakubkrehel/skills/better-colors) | Ramp rules, step jobs, measured contrast; installed in `.claude/skills/better-colors/` | Written for CSS: keep the rules, not the `oklch()` notation advice |
| [Flutter `inverseSurface`](https://api.flutter.dev/flutter/material/ColorScheme/inverseSurface.html) | Material's inverse roles for snackbars and tooltips | m3.material.io spec pages render empty when fetched |
| Fintech colour psychology ([Progress](https://www.progress.com/blogs/how-choose-right-colors-fintech), [Windmill](https://windmill.digital/insights/psychology-of-color-in-financial-app-design)) | What practitioners claim | No primary studies; quoted statistics untraceable (case study 08) |
| [Razorpay Blade repo](https://github.com/razorpay/blade) | INR `Amount` decisions, per-mode tokens | The Storybook site needs JavaScript; read the raw files |
| [Apple HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding.md) | How much brand colour, and where it goes (the content layer, not controls) | `.md` fetches cleanly; refined September 2026 |
| [wise.design](https://wise.design/foundations/colour) | Wise's colour foundations | Needs JavaScript: the fetch returns the heading only, and `.md` returns 404. The [oppadu gallery](https://www.oppadu.com/tools/design-systems-site/brand/wise.html) reconstructs the tokens, but it is third-party and unverified |
| Third-party "design system" files (open-design.ai, aiskill.market, webdesignhot, styles.refero.design, blakecrosley.com) | A quick guess at a brand's hex values | Reverse-engineered or AI-written; they disagree with each other. Never cite them as the app's real values |
| [Monzo help](https://monzo.com/help/budgeting-overdrafts-savings/advanced-budgeting-custom-categories) and [community](https://community.monzo.com/) | Feature facts (custom categories with a colour); user reactions | Help pages are short; the community is user reports, not usage data |
| [YNAB support](https://support.ynab.com/en_us/colors-and-icons-in-your-plan-HJQv_XHko.md) | What each status colour and icon means | Append `.md` to the article URL for clean text |
| [Copilot Money help](https://help.copilot.money/en/articles/11157550-quick-start-guide) | Feature facts (category colour, emoji, Genmoji) | No design rationale |
| [V&A collections](https://collections.vam.ac.uk/item/O1360553) | Authoritative physical descriptions of design objects (the Braun ET66) | One record per object |
| [Datawrapper Academy](https://www.datawrapper.de/academy/what-to-consider-when-choosing-colors-for-data-visualization), [Innovaccer data-viz colour](https://design.innovaccer.com/data-visualizations/color/usage/), [Datadog widget colours](https://docs.datadoghq.com/dashboards/guide/widget_colors/) | How many categorical colours people can tell apart; categorical vs semantic palettes | Practitioner guidance, not studies. Adobe Spectrum's data-viz page returned only the landing page |
| [jfly Colour Universal Design (Okabe & Ito)](https://jfly.uni-koeln.de/color/) | Colour-blind-safe palettes; "do not convey information in color only" | Old page; the safe set includes orange, yellow and vermillion, which clash with Hisaab's marigold and no-red rules |
| [NN/g: Dark mode vs light mode](https://www.nngroup.com/articles/dark-mode/) | Polarity research (Piepenbrock 2013, Dobres 2017) with citations | Summarises lab studies; little on large numerals |
| [MicroSave briefing notes](https://www.microsave.net/wp-content/uploads/2017/05/Mobile_Wallet_Design_for_Oral_Users.pdf), [NextBillion](https://nextbillion.net/designing-a-mobile-wallet-for-nonliterate-people-a-beginners-guide/) | Indian field research on oral and low-literacy users of mobile money | The fetch tool returns PDFs as binary; open the saved file with Read. Qualitative, small samples |
| Journals: PMC, Frontiers | Lab studies (for example, colour-coded icon search) | PMC returns a browser check; Frontiers redirects to `public-pages-files-2025.frontiersin.org` and gives the abstract only |

## Indian fintech
slice, Google Pay, CRED, Jupiter and Fi have little public screen-level material. Use Mobbin in a browser, or install the app and record the screens, before citing how they do something.

What is public, and what it covers (case study 09):

| Source | Covers | Limits |
|---|---|---|
| [Jupiter community](https://community.jupiter.money/t/jupiter-2-0-redesign-introducing-a-new-experience/51018) | Staff posts on redesigns (2.0's warm beige and accents), user reactions | `life.jupiter.money` (the design blog) returns 403 |
| [PhonePe design blog](https://www.phonepe.com/blog/design/lighting-up-the-night-presenting-the-dark-theme-of-phonepe/), [design.phonepe.com](https://design.phonepe.com/stories/behind-phonepe-redesign) | The dark-theme rationale (a brand-tinted dark mode); the 2025 redesign story | Blog pages exceed 100k characters: fetch again with `offset: 100000` to reach the article body |
| [Fi guides](https://fi.money/guides/tech-speak-at-Fi/designed-sealed-and-delivered) | Design intent in Fi's own words | No palette or tokens |
| CRED ([Dribbble](https://dribbble.com/cred-design), [UX Planet review](https://uxplanet.org/thoughts-on-creds-ui-revamp-apr-2022-6d2b4dcfcfc6)) | NeoPOP look | No official NeoPOP documentation found; UX Planet returns 403 |
| Payment-card design (Apple Card: [iDrop News](https://www.idropnews.com/news/mineralogist-finds-apple-cards-atomic-makeup-isnt-100-titanium/116221), [creditcards.com](https://creditcards.com/card-advice/apple-card-colors); [OneCard](https://www.getonecard.app/blog/onecard-metal-credit-card/); Monzo coral on [uxdesign.cc](https://uxdesign.cc/is-hot-coral-a-feature-or-a-liability-a-closer-look-at-the-colour-of-your-bank-card-fbd2f987d359)) | How cards stand out through material, finish and one owned colour; vertical cards ([BNN Bloomberg](https://www.bnnbloomberg.ca/credit-cards-are-turning-vertical-with-tap-to-pay-taking-off-1.1562427)) | Press and explainers; Apple publishes no Wallet colour mapping. Many "Apple Card weight" pages are SEO spam |
| Card effects ([ProAndroidDev holographic foil](https://proandroiddev.com/how-a-holographic-foil-effect-works-in-jetpack-compose-9535d621c055), [holographic_card_flutter](https://pub.dev/documentation/holographic_card_flutter/latest/), [grainy gradients](https://instantgradient.com/blog/grainy-gradients)) | Sheen, tilt and grain techniques | Technique only; no evidence on effect. Sensor tilt needs `sensors_plus` |
