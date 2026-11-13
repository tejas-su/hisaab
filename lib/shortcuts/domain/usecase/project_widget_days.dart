import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/projected_day.dart';
import '../projection/projected_book.dart';

/// Works out what Home will say on every day from today to the end of the cycle after this one,
/// if nothing new is typed (SPEC FR-WG-5, widget spec §5).
///
/// It copies the ledger into a [ProjectedBook], then for each day runs the real recurring engine
/// and the real `GetCycleSummary` on the copy with the clock set to that day. Bills, savings and
/// pay due by then are posted on the copy as the engine would post them when the app opens, so
/// each day's summary is the one Home would show. Nothing is written to the database.
final class ProjectWidgetDays implements UseCase<List<ProjectedDay>, NoParams> {
  const ProjectWidgetDays({
    required this._ledger,
    required this._recurring,
    required this._settings,
    required this._periods,
    required this._clock,
  });

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
  final BudgetSettingsRepository _settings;
  final PeriodCalculator _periods;
  final Clock _clock;

  /// Returns [Right] with one [ProjectedDay] per date, today first; or [Left] with the
  /// `DatabaseFailure` or `InvalidDataFailure` of the first read that failed.
  @override
  TaskEither<Failure, List<ProjectedDay>> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return GetCycleSummary(ledger: _ledger, recurring: _recurring, settings: _settings, periods: _periods, clock: _clock)
        .call(const NoParams())
        .flatMap((CycleSummary now) => _copy(WaitingBills.answersFrom(now.cycle), _lastReadDay(now)))
        .flatMap((ProjectedBook book) => _days(book, today, const <ProjectedDay>[], const Option<CalendarDate>.none()));
  }

  // why: the window ends with the cycle after this one, and no cycle is longer than a pay switch's
  // bridge (under two months); a read to here covers it with room to spare.
  static CalendarDate _lastReadDay(CycleSummary now) => now.cycle.end.addDays(_readAhead);
  static const int _readAhead = 70;

  TaskEither<Failure, ProjectedBook> _copy(CalendarDate from, CalendarDate to) => _settings.read().flatMap(
        (BudgetSettings settings) => _recurring.activeRules().flatMap(
              (List<RecurringRule> rules) => _ledger.entriesBetween(from, to).flatMap(
                    (List<Entry> entries) => _recurring.skipsBetween(from, to).flatMap(
                          (List<BillSkip> skips) => _ledger.firstLoggedOn().map(
                                (Option<CalendarDate> firstLogged) => ProjectedBook(
                                  entries: entries,
                                  rules: rules,
                                  skips: skips,
                                  settings: settings,
                                  firstLogged: firstLogged,
                                ),
                              ),
                        ),
                  ),
            ),
      );

  /// Projects [day] and every day after it, up to [windowEnd] once the next cycle is known.
  TaskEither<Failure, List<ProjectedDay>> _days(
    ProjectedBook book,
    CalendarDate day,
    List<ProjectedDay> done,
    Option<CalendarDate> windowEnd,
  ) {
    if (windowEnd case Some(value: final CalendarDate end) when day.isAfter(end)) {
      return TaskEither<Failure, List<ProjectedDay>>.right(done);
    }
    return _project(book, day).flatMap((ProjectedDay projected) {
      final List<ProjectedDay> all = <ProjectedDay>[...done, projected];
      // why: the first day past today's cycle starts the next one; its end closes the window.
      final bool firstOfNext = done.isNotEmpty && projected.summary.cycle.start != done.first.summary.cycle.start;
      final Option<CalendarDate> end =
          windowEnd.isNone() && firstOfNext ? Option<CalendarDate>.of(projected.summary.cycle.end) : windowEnd;
      return _days(book, day.addDays(1), all, end);
    });
  }

  TaskEither<Failure, ProjectedDay> _project(ProjectedBook book, CalendarDate day) {
    final Clock clock = _DayClock(day);
    book.runningOn = day;
    return PostDueRecurring(recurring: book.recurring, clock: clock)
        .call(const NoParams())
        .flatMap(
          (int _) => GetCycleSummary(
            ledger: book.ledger,
            recurring: book.recurring,
            settings: book.budget,
            periods: _periods,
            clock: clock,
          ).call(const NoParams()),
        )
        .map((CycleSummary summary) => ProjectedDay(summary: summary, spends: book.typedSpendsOn(day)));
  }
}

/// A [Clock] stopped at the start of one day.
final class _DayClock extends Clock {
  const _DayClock(this._day);

  final CalendarDate _day;

  @override
  DateTime now() => DateTime(_day.year, _day.month, _day.day);
}
