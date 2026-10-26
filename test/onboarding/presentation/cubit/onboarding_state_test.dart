import 'package:expense_tracker/ledger/domain/entities/bill_kind.dart';
import 'package:expense_tracker/onboarding/domain/entities/onboarding_draft.dart';
import 'package:expense_tracker/onboarding/domain/entities/setup_labels.dart';
import 'package:expense_tracker/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding states and labels compare by their fields', () {
    expect(const OnboardingLoading().props, isEmpty);
    expect(const OnboardingFinishing(OnboardingDraft()).props, <Object?>[const OnboardingDraft()]);
    expect(
      const SetupLabels(income: 'Salary', bills: <BillKind, String>{}).props,
      <Object?>['Salary', <BillKind, String>{}],
    );
  });
}
