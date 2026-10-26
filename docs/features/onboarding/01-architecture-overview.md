# Onboarding Architecture Overview

**Status:** built in M1.

## 1. Purpose
Three questions (income, when it comes, fixed bills) create everything the ledger needs and land the user on a working Home. No sign-up, permissions or currency picker.

## 2. Entry point
`AppRoot` (`lib/app/app_root.dart`) asks `LaunchBloc` (`LaunchStarted`); when `AppPreferencesRepository.onboardingDone()` is false it shows `AppRoutes.onboarding`, which provides `OnboardingBloc` (`OnboardingStarted` added) and `OnboardingPage`.

## 3. Data flow
```
OnboardingPage → OnboardingBloc (events)
  KeyPressed / BackspacePressed / Cleared / NextPressed   step 1 income, or the open bill's amount (AmountInput)
  PickerOpened / PayRuleChosen                 step 2 (FR-ON-3)
  BillOpened / BillDayChosen / BillRemoved     step 3 (FR-ON-4)
  BackPressed                                  one level back; on step 1 PopScope lets the app close instead
    every answer change → OnboardingDraftRepository.save   JSON in settings.onboarding_draft (FR-ON-6)
  FinishRequested(SetupLabels)                 also "Skip"; droppable
    → CompleteOnboarding
        CategoryRepository.all
        LedgerSetupBuilder.build               pure: rules dated from this cycle's start
        RecurringRepository.startFresh         one transaction; replaces all rules and entries
        AppPreferencesRepository.markOnboardingDone   sets the flag, deletes the draft
        PostDueRecurring                       a failure here is logged, not returned
  → OnboardingDone → LaunchOnboardingFinished → Home with the blocks-assemble entrance
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `OnboardingPage` | `presentation/pages/` | Picks the step widget; `PopScope` back handling |
| `IncomeStep`, `PaydayStep`, `BillsStep`, `BillEditorView` | `presentation/widgets/` | One question each, laid out by `AdaptiveSplit` |
| `DailyPreview` | `presentation/widgets/` | "That's about ₹1,500 a day" plus 30 blocks (÷ 30, preview only) |
| `OnboardingBloc`, `OnboardingEvent`, `OnboardingState` | `presentation/bloc/` | Answers, pickers, bill editor; `OnboardingFinishRequested` is `droppable()` |
| `OnboardingDraft`, `BillDraft`, `BillKind`, `SetupLabels` | `domain/entities/` | The answers and the localised rule names |
| `LedgerSetupBuilder` | `domain/ledger_setup_builder.dart` | Answers → `LedgerSetup` |
| `CompleteOnboarding` | `domain/usecase/` | The finish, safe to retry |
| `OnboardingDraftMapper`, `OnboardingDraftRepositoryImpl` | `data/` | Versioned JSON; an unreadable draft starts over |

## 5. State variants
| State | UI |
|---|---|
| `OnboardingLoading` | Blank page while the draft loads |
| `OnboardingInProgress(draft, picker, billEditor, rejections, saveFailed)` | The current step; the amount shakes on a refused key |
| `OnboardingFinishing` | Bills step with the finish key disabled |
| `OnboardingDone` | Navigates to Home |

## 6. What the setup contains
- **Monthly, last day or weekly pay:** a salary rule with `next_due` = this cycle's start, so the engine posts this cycle's salary at once.
- **Weekly pay:** the monthly answer × 12 ÷ 52, floored (DECISIONS D26).
- **"It changes":** no rule; one *Got* entry for the amount dated the 1st of this month (D27).
- **Bills:** monthly *Spent* rules; Rent goes under Home, the rest under Bills. `next_due` is the first due date on or after the cycle start, so bills already paid this cycle are posted too.

## 7. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | A write failed; the step shows "Couldn't save. Try again." |
| `InvalidDataFailure` | Missing pay rule, zero income, or a seed category missing |

## 8. Design spec
`docs/SPEC.md` FR-ON-1 to FR-ON-6; `docs/UI_DESIGN.md` §5.1, §6, §7, §13.

## 9. Known limitations / TODOs
- Installing mid-cycle counts the whole salary but none of the spending before install, so the first days' share is too high (SPEC Q6).
- Reset (FR-SE-4) must also clear the draft; `markOnboardingDone` already deletes it.
