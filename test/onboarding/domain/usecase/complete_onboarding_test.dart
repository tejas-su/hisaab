import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/onboarding/domain/entities/onboarding_draft.dart';
import 'package:expense_tracker/onboarding/domain/entities/setup_labels.dart';
import 'package:expense_tracker/onboarding/domain/usecase/complete_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

final CompleteOnboardingParams _params = CompleteOnboardingParams(
  draft: OnboardingDraft(income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
  labels: const SetupLabels(income: 'Salary', bills: <BillKind, String>{}),
);

void main() {
  late FakeCategoryRepository categories;
  late FakeRecurringRepository recurring;
  late FakeAppPreferencesRepository preferences;
  late CompleteOnboarding complete;

  setUp(() {
    categories = FakeCategoryRepository();
    recurring = FakeRecurringRepository();
    preferences = FakeAppPreferencesRepository(draftJson: '{}');
    final FakeClock clock = FakeClock(WorkedExample.now);
    complete = CompleteOnboarding(
      categories: categories,
      recurring: recurring,
      preferences: preferences,
      postDue: PostDueRecurring(recurring: recurring, clock: clock),
      clock: clock,
    );
  });

  group('CompleteOnboarding (FR-ON-5)', () {
    test('writes the setup, marks onboarding done and clears the draft', () async {
      expect(await complete(_params).run(), Either<Failure, Unit>.right(unit));
      expect(recurring.setups.single.rules.single.isIncomeSource, isTrue);
      expect(preferences.done, isTrue);
      expect(preferences.draftJson, isNull);
    });

    test('runs the recurring engine once done', () async {
      recurring.rules = <RecurringRule>[
        RecurringRule(
          id: 7,
          label: 'Milk',
          amount: Money.fromMajor(300),
          kind: EntryKind.spent,
          categoryId: 1,
          schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
          nextDue: const CalendarDate(2026, 10, 23),
        ),
      ];
      await complete(_params).run();
      expect(recurring.postings.single.occurrences, hasLength(1));
    });

    test('still succeeds when the engine fails afterwards; Home retries it', () async {
      final FakeRecurringRepository brokenEngine = FakeRecurringRepository()..failure = DatabaseFailure('locked');
      final FakeClock clock = FakeClock(WorkedExample.now);
      final CompleteOnboarding withBrokenEngine = CompleteOnboarding(
        categories: categories,
        recurring: recurring,
        preferences: preferences,
        postDue: PostDueRecurring(recurring: brokenEngine, clock: clock),
        clock: clock,
      );
      expect(await withBrokenEngine(_params).run(), Either<Failure, Unit>.right(unit));
      expect(preferences.done, isTrue);
    });

    test('does not mark onboarding done when the setup write fails', () async {
      recurring.startFreshFailure = DatabaseFailure('disk full');
      expect((await complete(_params).run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect(preferences.done, isFalse);
    });

    test('returns the failure when marking done fails, so it can be retried', () async {
      preferences.markDoneFailure = DatabaseFailure('locked');
      expect((await complete(_params).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('returns InvalidDataFailure for unfinished answers and writes nothing', () async {
      final Either<Failure, Unit> result = await complete(
        CompleteOnboardingParams(draft: const OnboardingDraft(), labels: _params.labels),
      ).run();
      expect(result.getLeft().toNullable(), isA<InvalidDataFailure>());
      expect(recurring.setups, isEmpty);
    });

    test('returns DatabaseFailure when categories can\'t be read', () async {
      categories.failure = DatabaseFailure('locked');
      expect((await complete(_params).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('params compare by value', () {
      expect(_params, CompleteOnboardingParams(draft: _params.draft, labels: _params.labels));
    });
  });
}
