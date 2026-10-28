# Ask AI Architecture Overview

**Status:** built in M5. Device check pending: confirm the prompt pastes cleanly into ChatGPT on a phone before M5 is ticked in PLAN §12.

## 1. Purpose
Ask AI turns the user's money data into a ready-to-paste prompt for ChatGPT or any other AI. The app never calls an AI itself. It prepares text, shows exactly what will be sent, and hands it off only when the user taps.

## 2. Entry point
- The Ask AI card at the top of `SpendsPage` opens `AskAiPage` for the cycle Spends shows (FR-SP-2, DECISIONS D60). The card shows only when that cycle has spends (D61).
- `AppRoutes.askAi` in `lib/app/routes.dart` builds the `AskAiBloc` and adds `AskAiLoadRequested`.

## 3. Data flow
1. `AskAiLoadRequested` runs `GetPromptInput(cycle)`. It loads the shown cycle and the two before it, the active rules, the categories, the keep-aside, and the entries up to today, into one `PromptInput`. When the shown cycle holds today it also runs Home's `GetCycleSummary`, so the prompt's facts line states the hero's own numbers (D79).
2. The bloc builds the prompt with `PromptBuilder.build(input, choice, nameOf:)` and emits `AskAiReady`. A pick of *Will my money last till payday?* falls back to the default goal when `PromptInput.offersOnTrack` is false (a past cycle, or income with no payday) (D72).
3. `AskAiGoalChosen`, `AskAiPeriodChosen`, `AskAiNotesHidden` and `AskAiQuestionChanged` change the `PromptChoice` and rebuild the prompt without reading again (FR-AI-2).
4. An action button adds an `AskAiHandoffEvent` (`droppable()`), which is ignored while `choice.canSend` is false:
   - `AskAiChatGptPressed`: `AiHandoff.copy`, then `AiHandoff.open` with `ChatGptLink.prefilled(text)`, or `ChatGptLink.home` when the encoded text is over 2,000 characters. In that case `AskAiReady.needsPaste` is true and `AskAiActions` already shows the paste caption above the buttons (D74).
   - `AskAiOtherAiPressed` (*Other apps*): `AiHandoff.share`.
   - `AskAiCopyPressed`: `AiHandoff.copy`.
5. After *Copy only*, or when nothing could open the link, the bloc raises `AskAiReady.toasts`, and the page's `BlocConsumer` shows "Copied. In the chat, long-press and tap Paste." (D62, D74).

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `AskAiPage` | `lib/ask_ai/presentation/pages/ask_ai_page.dart` | Fixed header, scrolling cards, and pinned actions, in one pane, two panes or across a tabletop fold (D67) |
| `AskAiHeader`, `AskAiControls`, `GoalRow`, `GoalWell`, `GoalCheck`, `OwnQuestionRow`, `PeriodSwitch` | `lib/ask_ai/presentation/widgets/` | Back and title; the choices card as Today-list rows with a check on the pick; the always-visible own-question row, whose placeholder becomes an example while focused (D73); the period segments named with `CycleLabel.of` and `CycleLabel.rangeOf` from Spends (D76) |
| `AskAiPreviewCard`, `PromptPreview`, `AskAiActions` | `lib/ask_ai/presentation/widgets/` | One card with "What the AI will see · n entries", the privacy caption, the first 4 lines or the full text, and *Leave out my notes* below a hairline; the three pinned actions, with the paste caption above them when needed (D74, D75) |
| `AskAiBloc`, `AskAiEvent`, `AskAiState` | `lib/ask_ai/presentation/bloc/` | Holds the choice, rebuilds the prompt, runs the hand-off |
| `GetPromptInput` | `lib/ask_ai/domain/usecase/get_prompt_input.dart` | Loads the three cycles' data once |
| `PromptBuilder`, `PromptCsv` | `lib/ask_ai/domain/` | Pure, deterministic BR-15 text with RFC 4180 CSV; groups the oldest 7-day blocks to stay ≤ 12,000 characters (D59, D64) |
| `AskGoal`, `AskPeriod`, `PromptChoice`, `PromptInput`, `PromptText` | `lib/ask_ai/domain/` | Goals, periods, the user's choice, the loaded data, and the result |
| `ChatGptLink` | `lib/ask_ai/domain/chat_gpt_link.dart` | The `?q=` link when the encoded text fits in 2,000 characters |
| `AiHandoff` / `SystemAiHandoff` | `domain/ai_handoff.dart` / `data/system_ai_handoff.dart` | Copy (clipboard), open (`url_launcher`), share (`share_plus`) (D63) |
| `registerAskAiServices` | `lib/ask_ai/di/ask_ai_module.dart` | Registers `GetPromptInput` and `AiHandoff` |

## 5. State variants
| State | UI |
|---|---|
| `AskAiLoading` | Header only |
| `AskAiReady` | Full screen. A blank own question disables the three actions (D65) |
| `AskAiFailed` | "Couldn't load your money." and Try again |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure`, `InvalidDataFailure` | A ledger read failed, which gives `AskAiFailed` |

`AiHandoff.open` returns false instead of failing when nothing can open the link. The text is already copied, so the toast shows.

## 7. External dependencies
- **Ledger:** repositories, read only, through `ledger.dart`.
- **Core:** `MoneyFormatter` (`en_IN`), `PeriodCalculator`, `Clock`, `Haptics`, `Pane`, `HisaabChip`, `SignalKey`.
- **Packages:** `share_plus` and `url_launcher` (M5). The manifest adds an https `VIEW` query for API 30+. No INTERNET permission is added (NFR-2).

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-AI-1 to FR-AI-4, BR-15, NFR-2, NFR-3.
- Visuals: `docs/UI_DESIGN.md` §5.4 (card) and §5.5 (screen).
- Decisions: `docs/DECISIONS.md` D59–D65.

## 9. Known limitations / TODOs
- The ChatGPT `?q=` prefill is an undocumented URL behaviour. The copy fallback stays the primary promise.
- The goal task texts in `PromptBuilder._task` are draft copy and need a product review.
- `SystemAiHandoff.open` and `share` call platform plugins and are not covered by unit tests.
