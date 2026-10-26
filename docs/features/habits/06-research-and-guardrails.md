# Habits: research and guardrails

Summary of the research done on 2026-10-26 on how large fintech and consumer apps drive engagement, and where Hisaab draws the line.

## What works, and the Hisaab version

| Mechanism | Seen at | Hisaab version |
|---|---|---|
| Streaks and loss aversion (pull takes over around day 7) | Duolingo | A logging streak, never a spending streak; designed in the separate gamification session |
| Forgiveness (streak freeze) | Duolingo | A no-spend day counts as logged |
| A personal story with personality | Year in Monzo | A cycle story at payday (later) |
| Variable reward | Google Pay scratch cards | Surprise facts in Spends insights, not random cash |
| A well-timed reminder | Duolingo, trackers | The missed-log question, timed to the user's own habit, in-app only |

Evidence that the goal is aligned with the user: in real app data, persistent tracking was associated with lower discretionary spending and higher budget attainment (Zhang, 2023, via secondary summary). Real-time spend feedback helped most for people with low self-control (Lund self-scanner field experiment).

## The line

- **Legal:** India's CCPA *Guidelines for Prevention and Regulation of Dark Patterns, 2023* make 13 patterns unfair trade practices for every platform serving Indian users, free or paid. Most relevant here: false urgency, confirm shaming, nagging, interface interference, forced action. Not selling data is no exemption. (Full list not verified against the official annexure.)
- **Retention research:** a study of Duolingo found its mechanics drive daily activity but build dependence on the app rather than self-sustaining habits.
- **Regulatory precedent:** Robinhood's confetti and "biggest mover" pushes drew scrutiny and were retired.
- **Hisaab rule:** use loss aversion and reward on *the act of logging*, never on spending. Never make ignoring or leaving cost the user anything. The only persuasion allowed is toward spending less and saving.

## Guardrails (testable)

- At most one suggestion per screen and one Home note a day.
- No push notifications from this feature.
- No guilt or urgency words; banned words per UI_DESIGN §8 and `04-ux-and-copy.md`.
- Dismissal always quiets the suggestion (FSM 2).
- Everything stays on the device (NFR-2, NFR-3).

## Sources

- CCPA guidelines: [Mondaq](https://mondaq.com/india/consumer-trading-unfair-trading/1398262/ccpa-issues-guidelines-for-prevention-and-regulation-of-dark-patterns-2023-effective-30-november-2023), [Deloitte](https://www2.deloitte.com/content/dam/Deloitte/in/Documents/tax/in-tax-gbt-the-guidelines-for-prevention-and-regulation-of-dark-patterns-noexp.pdf), [KS&K](https://ksandk.com/newsletter/safeguarding-consumer-rights-dark-patterns-guidelines-2023/)
- Duolingo: [streak psychology](https://www.justanotherpm.com/blog/the-psychology-behind-duolingos-streak-feature), [case study](https://trophy.so/blog/duolingo-gamification-case-study), [IJMAT habit study](https://www.wr-publishing.org/index.php/ijmat/article/view/908), [reminders](https://www.digia.tech/post/duolingo-habit-forming-reminders-retention-architecture/)
- Monzo: [Writing Year in Monzo 2024](https://monzo.com/blog/writing-year-in-monzo-2024), [How we wrote 5 million Years in Monzo](https://monzo.com/blog/how-we-wrote-5-million-years-in-monzo)
- Google Pay: [ORF on cashback](https://www.orfonline.org/expert-speak/the-weaponisation-of-cashbacks-on-upi-by-google-pay-57099), [UPI gamification paper](https://www.eelet.org.uk/index.php/journal/article/download/2561/2303/2827)
- Robinhood: [Yale Law Journal Forum](https://yalelawjournal.org/pdf/F7.TierneyLangvardtFinalDraftWEB_d25wkead.pdf), [Fast Company](https://www.fastcompany.com/90619112/robinhood-gamification-dark-side)
- Tracking and spending: [freenance summary](https://freenance.io/guides/why-track-expenses-scientific-arguments), [Lund field experiment](https://www.lusem.lu.se/erik-wengstrom/publication/11b93dd4-79e2-4673-9a07-969166cf0a65)
