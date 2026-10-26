# Onboarding Architecture Overview

**Status:** planned (milestone M1), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
Onboarding asks three questions (income, when it comes, fixed bills), then creates everything the ledger needs. It lands the user on a working Home in under 60 s. There is no sign-up, no permission prompt and no currency picker.

## 2. Entry point
- `lib/app/routes.dart` shows `OnboardingPage` at launch when `AppPreferences.onboardingDone` is false (FR-ON-1).
- It reopens at the saved step if the user left midway (FR-ON-6).

## 3. Data flow
```
OnboardingPage
  → OnboardingCubit.enterDigit / backspace / next              step 1 (income), via AmountInput (core/money)
  → OnboardingCubit.choosePayRule(PayRule)                     step 2 (FR-ON-3)
  → OnboardingCubit.addBill / skipBills                        step 3 (FR-ON-4)
     each change → SaveOnboardingDraft → AppPreferencesRepository.saveDraft     (FR-ON-6)
  → OnboardingCubit.finish
    → CompleteOnboarding(draft)                                lib/onboarding/domain/usecase/
        one transaction: seed categories, income rule, bill rules, onboardingDone = true
      → PostDueRecurring(today)                                see recurring-engine
  → state OnboardingDone → BlocListener navigates to Home (blocks-assemble motion, success haptic)
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `OnboardingPage` | `lib/onboarding/presentation/pages/` | Hosts the three steps and the progress dots; listens for `OnboardingDone` |
| `IncomeStep`, `PayRuleStep`, `BillsStep` | presentation/widgets | One question each, one giant input, Skip on bills |
| `DailyPreview` | presentation/widgets | "That's about ₹1,500 a day" plus the appearing day blocks (FR-ON-2) |
| `OnboardingCubit` | presentation/cubit | Owns the draft and the current step; guards `isClosed` and double `finish` |
| `OnboardingDraft` | `lib/onboarding/domain/entities/` | Income `Money`, `PayRule?`, bill drafts; serialisable for resume |
| `CompleteOnboarding` | domain/usecase | Writes seed data and rules atomically, then runs the engine |
| `SaveOnboardingDraft` | domain/usecase | Persists the draft after every step |
| `AppPreferencesRepository` | `lib/settings/domain/repository/` (via `settings.dart`, DECISIONS D20) | `onboardingDone`, draft |
| `PayRule` | `lib/core/time/pay_rule.dart` | Sealed: `MonthlyOnDay(d)`, `LastDayOfMonth`, `Weekly(weekday)`, `Irregular` |
| `AmountInput` | `lib/core/money/amount_input.dart` | Pure keypad rules shared with Add (FR-AD-2) |

## 5. State variants
| State | UI |
|---|---|
| `OnboardingInProgress(step, draft)` | The current step with its input; Next enabled per step rules |
| `OnboardingFinishing` | Inputs disabled; Next shows progress |
| `OnboardingDone` | Navigate to Home |
| `OnboardingFailed(failure, draft)` | Stays on step 3 with "Couldn't save. Try again."; nothing is lost |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | The seed or rules transaction failed; it rolls back as a whole |
| `InvalidAmountFailure` | Income is 0 (normally prevented by the disabled Next) |

## 7. External dependencies
- **Ledger:** `CategoryRepository` (seed), `RecurringRepository`, `PostDueRecurring`.
- **Core:** `AmountInput`, `MoneyFormatter`, `PayRule`, `Keypad`, `SignalKey`, `DayBlocks` widgets, `Haptics`, motion tokens.

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-ON-1 to FR-ON-6.
- Visuals and motion:
  - `docs/UI_DESIGN.md` §5.1 (steps).
  - §6 (`calm` spring for blocks assembling).
  - §7 (success haptic).
  - §3.4 (amount type).

## 9. Known limitations / TODOs
- The step 1 preview divides by 30 for display only (FR-ON-2). The real share comes from BR-4 after finishing.
- *It changes* (irregular) creates no income rule. Home then asks for a *Got* entry (E10).
- Reset from Settings returns here (FR-SE-4). Confirm that the draft is cleared at the same time.
