# Ask AI Architecture Overview

**Status:** planned (milestone M5), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
Ask AI turns the user's money data into a ready-to-paste prompt for ChatGPT or any other AI. The app never calls an AI itself. It prepares text, shows exactly what will be sent, and hands it off.

## 2. Entry point
- The Ask AI card at the top of `SpendsPage` opens `AskAiPage` for the selected cycle (FR-SP-2).

## 3. Data flow
```
AskAiPage
  → AskAiBloc ← AskAiLoadRequested(cycle)
    → GetPromptInput(cycle, period, hideNotes)           lib/ask_ai/domain/usecase/
       → LedgerRepository / CategoryRepository / RecurringRepository
       → PromptInput (income, pay rule, period dates, category totals, bills, entries)
    → PromptBuilder.build(input, goal, customQuestion)   pure, deterministic (BR-15)
       → PromptText(text, entryCount, summarisedWeeks?)
  → emit AskAiReady (preview)
  → AskAiGoalSelected / AskAiPeriodChanged / AskAiHideNotesChanged / AskAiQuestionChanged → rebuild preview   FR-AI-2
  → AskAiChatGptRequested
       → ClipboardService.copy(text)
       → ChatGptLink.forText(text) → url or plain chatgpt.com      BR-15 (≤ 2,000 encoded chars)
       → ExternalLinkLauncher.open(url)
  → AskAiShareRequested    → ShareService.shareText(text)
  → AskAiCopyRequested     → ClipboardService.copy(text)
  → emit with lastAction → BlocListener shows the toast "Copied. Paste it in the chat."
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `AskAiPage` | `lib/ask_ai/presentation/pages/` | Goal cards, period chips, preview, notes switch, actions |
| `AskAiBloc`, `AskAiEvent` | presentation/bloc | Holds selections; regenerates the preview; runs actions through the seams |
| `GoalCard`, `PromptPreview` | presentation/widgets | Selected card ink-filled with marigold check; collapsible preview |
| `GetPromptInput` | domain/usecase | Gathers the period's data from the ledger |
| `PromptBuilder` | `lib/ask_ai/domain/prompt_builder.dart` | Pure; byte-identical output for the same input; 12,000-char guard with weekly summarising |
| `AskGoal` | domain | Enum: review, save, budget, onTrack, custom |
| `ChatGptLink` | domain | Pure: builds the `?q=` URL or falls back to the bare site |
| `ClipboardService` | domain (interface) / data (`Clipboard.setData`) | Seam for tests |
| `ShareService` | domain (interface) / data (`share_plus`) | Android share sheet |
| `ExternalLinkLauncher` | domain (interface) / data (`url_launcher`) | Opens the browser or ChatGPT app via intent |

## 5. State variants
| State | UI |
|---|---|
| `AskAiLoading` | Preview skeleton |
| `AskAiReady(goal, period, hideNotes, question, prompt, lastAction?)` | Full screen; `lastAction` drives one-shot toasts |
| `AskAiEmpty` | No entries in the period: "Add a few spends first, then ask." |
| `AskAiFailed(failure)` | Retry line |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | Loading the input failed |
| `ClipboardFailure` | The platform clipboard call threw |
| `LaunchFailure` | No app can open the URL. The text is still copied; show the toast only |

## 7. External dependencies
- **Ledger:** repositories (read only).
- **Core:** `MoneyFormatter` (the prompt uses plain `₹` amounts, `en_IN`), `PeriodCalculator`, `Clock`.
- **Packages:** `share_plus`, `url_launcher` (M5); Flutter `services` for the clipboard.

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-AI-1 to FR-AI-4, BR-15, NFR-2 (intent, not app networking), NFR-3.
- Visuals: `docs/UI_DESIGN.md` §5.5. The template text is in PLAN §7.

## 9. Known limitations / TODOs
- The ChatGPT `?q=` prefill is an undocumented URL behaviour. Keep the copy fallback as the primary promise.
- "Last 3 cycles" with a long history can hit the 12,000-char guard. Golden-test the summarised form.
- The goal task texts are copy that needs a review pass before M5 ships.
