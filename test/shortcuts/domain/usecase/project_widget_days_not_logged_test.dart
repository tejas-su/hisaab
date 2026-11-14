import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/shortcuts/domain/projection/projected_book.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/shortcuts/domain/entities/projected_day.dart';

import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// The widget's snapshot after a fix (SPEC FR-WG-5, FR-FX-5 AC-7): the hero follows the pool, and a
/// fix is never one of today's bites.
void main() {
  late FakeServices services;

  setUp(() => services = FakeServices());

  tearDown(() => services.dispose());

  Future<List<ProjectedDay>> project() async =>
      (await services.projectWidgetDays(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));

  test('the projected settings answer the install line as used up and refuse to write it', () async {
    final ProjectedBook book = ProjectedBook(
      entries: WorkedExample.entries,
      rules: WorkedExample.rules,
      skips: const <BillSkip>[],
      settings: const BudgetSettings(),
      firstLogged: const Option<CalendarDate>.of(CalendarDate(2026, 10, 4)),
    );

    expect(await book.budget.installLineSeen().run(), const Right<Failure, bool>(true));
    expect(() => book.budget.markInstallLineSeen(), throwsUnsupportedError);
  });

  group('ProjectWidgetDays after a Not logged fix', () {
    test("a Spent fix lowers every projected day's hero as the pool falls, with none of its bites", () async {
      final List<ProjectedDay> before = await project();
      services.ledger.entries.add(notLogged(4200, WorkedExample.today));

      final List<ProjectedDay> after = await project();

      expect(after.first.summary.safeToday, Money.fromMajor(963));
      expect(after.first.spends.any((Entry e) => e.isNotLogged), isFalse);
      expect(after.first.spends, before.first.spends);
      for (final (int index, ProjectedDay day) in after.indexed) {
        expect(day.spends.any((Entry e) => e.isNotLogged), isFalse);
        // why: a day after payday is in the next cycle, where this cycle's fix is not in the pool.
        final bool sameCycle = day.summary.cycle == after.first.summary.cycle;
        expect(day.summary.todayShare < before[index].summary.todayShare, sameCycle, reason: 'day $index');
      }
    });

    test('a Got fix raises them', () async {
      final List<ProjectedDay> before = await project();
      services.ledger.entries.add(notLogged(1000, WorkedExample.today, got: true));

      final List<ProjectedDay> after = await project();

      expect(after.first.summary.safeToday, Money.fromMajor(1541));
      expect(after.first.summary.todayShare > before.first.summary.todayShare, isTrue);
    });
  });
}
