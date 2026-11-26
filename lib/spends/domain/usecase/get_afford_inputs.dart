import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/afford_context.dart';

/// Reads what *Can I afford it?* needs from the user's money, once, when the answer opens (SPEC BR-24).
final class GetAffordInputs implements UseCase<AffordContext, String> {
  const GetAffordInputs({
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

  /// Loads the next cycle's room and days, the usual day's spend, and the saving named [params]
  /// (the item's name, may be empty).
  ///
  /// Returns [Right] with the context, or [Left] with `DatabaseFailure` when a read fails.
  @override
  TaskEither<Failure, AffordContext> call(String params) =>
      _settings.read().flatMap(
        (BudgetSettings settings) => _recurring.activeRules().flatMap(
          (List<RecurringRule> rules) => _ledger.savingTotals().flatMap(
            (SavingTotals totals) => _withHistory(
              _Book(
                rules: rules,
                totals: totals,
                today: _clock.today(),
                cycles: _cyclesAround(_clock.today(), settings, rules),
                name: params,
              ),
            ),
          ),
        ),
      );

  TaskEither<Failure, AffordContext> _withHistory(_Book book) => _ledger
      .entriesBetween(book.cycles.previous.start, book.cycles.previous.end)
      .flatMap(
        (List<Entry> previous) => _ledger.firstLoggedOn().map(
          (Option<CalendarDate> firstLogged) =>
              _contextOf(book, previous, firstLogged),
        ),
      );

  /// The finished cycle before the current one and the full cycle after it.
  _Cycles _cyclesAround(
    CalendarDate today,
    BudgetSettings settings,
    List<RecurringRule> rules,
  ) {
    final PayRule rule = PayRuleSchedule.payRuleOf(_incomeRule(rules));
    PayCycle cycleOf(CalendarDate day) => _periods.cycleFor(
      today: day,
      rule: rule,
      monthStart: settings.monthStart,
      switches: settings.paySwitches,
    );
    final PayCycle current = cycleOf(today);
    return (
      previous: cycleOf(current.start.addDays(-1)),
      next: cycleOf(current.end.addDays(1)),
    );
  }

  static AffordContext _contextOf(
    _Book book,
    List<Entry> previous,
    Option<CalendarDate> firstLogged,
  ) {
    final Option<RecurringRule> existing = _savingNamed(book.name, book.rules);
    final bool tracked = firstLogged
        .filter((CalendarDate d) => !d.isAfter(book.cycles.previous.start))
        .isSome();
    return AffordContext(
      room: _room(book, previous, existing),
      days: book.cycles.next.lengthInDays,
      usual: tracked
          ? _usual(previous, book.cycles.previous)
          : const Option<Money>.none(),
      nextCycle: book.cycles.next,
      existingSaving: existing,
      existingSetAside: existing.match(
        () => Money.zero,
        (RecurringRule saving) => _setAside(saving, book.totals),
      ),
    );
  }

  // why: counted by dates inside the next cycle, never "monthly", so weekly and 28 to 31-day
  // cycles agree (BR-24). Card bills are left out: their buys were counted when made (D123).
  static Money _room(
    _Book book,
    List<Entry> previous,
    Option<RecurringRule> existing,
  ) {
    final PayCycle next = book.cycles.next;
    final Money income = _incomeRule(book.rules).match(
      () => _sum(previous.where((Entry e) => e.kind == EntryKind.got)),
      (RecurringRule rule) => _dueIn(rule, next),
    );
    final Money bills = book.rules
        .where(
          (RecurringRule r) =>
              r.kind == EntryKind.spent && r.amountMode != AmountMode.card,
        )
        .fold(
          Money.zero,
          (Money total, RecurringRule bill) => total + _dueIn(bill, next),
        );
    final Money savings = book.rules
        .where(
          (RecurringRule r) =>
              r.kind == EntryKind.saved &&
              existing.filter((RecurringRule s) => s.id == r.id).isNone(),
        )
        .fold(
          Money.zero,
          (Money total, RecurringRule saving) =>
              total + _cappedIn(saving, book),
        );
    return income - bills - savings;
  }

  // why: a saving stops at its target (D213, D216), so a reached one takes ₹0 from room and a
  // partly done one only its gap. The walk starts after today, so put-ins still due this cycle
  // fill the gap first, as the engine will post them; only next-cycle dates are kept.
  static Money _cappedIn(RecurringRule saving, _Book book) {
    final PayCycle next = book.cycles.next;
    final List<DatedAmount> due = DueAmounts.datedAfter(
      <RecurringRule>[saving],
      today: book.today,
      cycle: PayCycle(start: book.today, end: next.end),
    );
    return SavingCaps.capped(saving, due, _setAside(saving, book.totals))
        .where((DatedAmount put) => !put.date.isBefore(next.start))
        .fold(Money.zero, (Money total, DatedAmount put) => total + put.amount);
  }

  static Money _dueIn(RecurringRule rule, PayCycle cycle) => _occurrencesIn(
    rule,
    cycle,
  ).fold(Money.zero, (Money total, DatedAmount due) => total + due.amount);

  static List<DatedAmount> _occurrencesIn(RecurringRule rule, PayCycle cycle) =>
      RecurringSchedule.datesFrom(
        rule.schedule,
        RecurringSchedule.firstOnOrAfter(rule.schedule, cycle.start),
        through: cycle.end,
      ).map((CalendarDate date) => (date: date, amount: rule.amount)).toList();

  // why: counted as BR-7's `V_prev`: typed spending only, no rule-posted bills, no *Not logged*.
  static Option<Money> _usual(List<Entry> previous, PayCycle cycle) {
    final Money typed = _sum(
      previous.where(
        (Entry e) =>
            e.kind == EntryKind.spent &&
            e.recurringId == null &&
            !e.isNotLogged,
      ),
    );
    final Money perDay = Money.fromMajor(
      typed.amountMinor ~/ cycle.lengthInDays ~/ Money.fromMajor(1).amountMinor,
    );
    return perDay.isZero
        ? const Option<Money>.none()
        : Option<Money>.of(perDay);
  }

  static Option<RecurringRule> _savingNamed(
    String name,
    List<RecurringRule> rules,
  ) {
    final String wanted = name.trim().toLowerCase();
    return Option<RecurringRule>.fromNullable(
      rules
          .where(
            (RecurringRule r) =>
                r.kind == EntryKind.saved &&
                wanted.isNotEmpty &&
                r.label.trim().toLowerCase() == wanted,
          )
          .firstOrNull,
    );
  }

  static Money _setAside(RecurringRule saving, SavingTotals totals) {
    final ({Money putIn, Money used}) saved =
        totals.bySaving[saving.id] ?? (putIn: Money.zero, used: Money.zero);
    return SetAside.of(saved.putIn, saved.used);
  }

  static Option<RecurringRule> _incomeRule(List<RecurringRule> rules) =>
      Option<RecurringRule>.fromNullable(
        rules.where((RecurringRule r) => r.isIncomeSource).firstOrNull,
      );

  static Money _sum(Iterable<Entry> entries) =>
      entries.fold(Money.zero, (Money total, Entry e) => total + e.amount);
}

/// The finished cycle before the current one and the full cycle after it.
typedef _Cycles = ({PayCycle previous, PayCycle next});

/// What the answer is built from, read once.
final class _Book {
  const _Book({
    required this.rules,
    required this.totals,
    required this.today,
    required this.cycles,
    required this.name,
  });

  final List<RecurringRule> rules;
  final SavingTotals totals;
  final CalendarDate today;
  final _Cycles cycles;
  final String name;
}
