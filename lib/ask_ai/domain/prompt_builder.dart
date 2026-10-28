import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import '../../core/time/pay_rule.dart';
import '../../ledger/ledger.dart';
import 'ask_goal.dart';
import 'entities/prompt_choice.dart';
import 'entities/prompt_input.dart';
import 'entities/prompt_text.dart';
import 'prompt_csv.dart';

/// Turns the ledger into the Ask AI prompt (SPEC BR-15): role, context, the app's own numbers
/// when the period holds today, summary, bills, entries as CSV, then the task.
///
/// The text is English whatever the app language, since it is written for the AI, and it is
/// byte-identical for the same input (DECISIONS D59).
abstract final class PromptBuilder {
  /// The longest text before the oldest entries are grouped by week.
  static const int maxLength = 12000;

  static final MoneyFormatter _money = MoneyFormatter();

  static const String _role =
      'You are a friendly money coach for someone in India. Reply in simple English, under 200 words.\n'
      'Use only the numbers below. Write amounts in ₹ with Indian grouping (₹1,25,000).\n'
      "If there is too little data to judge, say so. Don't name specific stocks, funds, loans or apps.";

  static const List<String> _weekdays = <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// Builds the prompt for [choice] from [input]; [nameOf] gives each category's shown name.
  ///
  /// When the text would pass [maxLength], the oldest weeks are grouped one at a time until it
  /// fits, or until every week is grouped.
  static PromptText build(PromptInput input, PromptChoice choice, {required String Function(Category) nameOf}) {
    final List<PayCycle> cycles = input.cycles.take(choice.period.cycleCount).toList();
    final PayCycle period = PayCycle(start: cycles.last.start, end: cycles.first.end);
    final List<Entry> entries = _entriesIn(input, period);
    final _Names names = _Names(input.categories, nameOf);
    final _Draft draft = _Draft(
      head: <String>[
        _role,
        _context(input, period),
        ..._facts(input),
        _summary(entries, names),
        _bills(input.bills),
        '',
      ].join('\n'),
      entries: entries,
      weeks: _weeks(period),
      names: names,
      choice: choice,
    );
    return Iterable<int>.generate(draft.weeks.length)
        .map(draft.grouping)
        .firstWhere((PromptText prompt) => prompt.text.length <= maxLength, orElse: () => draft.grouping(draft.weeks.length));
  }

  /// The period's entries up to today, oldest first.
  static List<Entry> _entriesIn(PromptInput input, PayCycle period) =>
      input.entries.where((Entry e) => period.contains(e.date) && !e.date.isAfter(input.today)).toList()
        ..sort((Entry a, Entry b) => a.date == b.date ? a.id.compareTo(b.id) : a.date.compareTo(b.date));

  // why: blocks from the period start, not calendar weeks, so the first block never straddles
  // the period's start and every grouped line covers whole days of the period (DECISIONS D64).
  static List<PayCycle> _weeks(PayCycle period) => Iterable<int>.generate((period.lengthInDays + 6) ~/ 7).map((int week) {
    final CalendarDate from = period.start.addDays(week * 7);
    final CalendarDate to = from.addDays(6);
    return PayCycle(start: from, end: to.isAfter(period.end) ? period.end : to);
  }).toList();

  static String _context(PromptInput input, PayCycle period) {
    final String income = input.incomeRule.match(
      () => 'varies',
      (RecurringRule rule) =>
          '${_money.format(rule.amount)}/${_per(rule.schedule.frequency)} (${_payday(input.payRule)})',
    );
    return 'Context: income $income, currency ${Money.zero.currency.code}, period ${period.start.toIso()}..${period.end.toIso()}, '
        'today ${input.today.toIso()}.';
  }

  // why: the AI is told Home's own numbers as fact, so its answer can't contradict the hero
  // (SPEC BR-15). Home shows no hero without income, so neither does the prompt.
  static List<String> _facts(PromptInput input) => input.summary
      .filter((CycleSummary summary) => summary.state is! NoIncome)
      .match(
        () => const <String>[],
        (CycleSummary summary) => <String>[
          'From my app, and correct: ${<String>[
            'safe to spend today ${_money.format(_safeToday(summary))}',
            ..._forecast(summary.forecast),
            if (!input.keepAside.isZero) 'I keep aside ${_money.format(input.keepAside)} a ${_cycleWord(input.payRule)} as savings',
          ].join('; ')}.',
        ],
      );

  // why: as on Home's hero, an overspent day reads ₹0, never a negative amount.
  static Money _safeToday(CycleSummary summary) => switch (summary.state) {
    OverToday() || OverCycle() => Money.zero,
    NoIncome() || SlowDown() || OnTrack() => summary.safeToday.isNegative ? Money.zero : summary.safeToday,
  };

  static List<String> _forecast(RangeForecast forecast) => switch (forecast) {
    LastsTillPayday(:final Money spare) => <String>['at this pace it lasts till payday with about ${_money.format(spare)} spare'],
    RunsOut(:final CalendarDate date) => <String>['at this pace it runs out on ${date.toIso()}'],
    TooEarlyToForecast() => const <String>[],
  };

  static String _cycleWord(PayRule rule) => rule is WeeklyOn ? 'week' : 'month';

  static String _per(Frequency frequency) => switch (frequency) {
    Frequency.weekly => 'week',
    Frequency.biweekly => '2 weeks',
    Frequency.monthly => 'month',
    Frequency.yearly => 'year',
  };

  static String _payday(PayRule rule) => switch (rule) {
    MonthlyOnDay(:final int day) => 'payday ${_ordinal(day)}',
    LastDayOfMonth() => 'payday last day of the month',
    WeeklyOn(:final int weekday) => 'paid every ${_weekdays[weekday - 1]}',
    IrregularIncome() => 'no fixed payday',
  };

  static String _ordinal(int day) {
    final String suffix = day >= 11 && day <= 13
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$day$suffix';
  }

  static String _summary(List<Entry> entries, _Names names) {
    final Map<int, Money> spentBy = entries
        .where((Entry e) => e.kind == EntryKind.spent)
        .fold(
          <int, Money>{},
          (Map<int, Money> totals, Entry e) => <int, Money>{...totals, e.categoryId: (totals[e.categoryId] ?? Money.zero) + e.amount},
        );
    final List<String> rows =
        (spentBy.entries.toList()..sort(
              (MapEntry<int, Money> a, MapEntry<int, Money> b) =>
                  a.value == b.value ? names.of(a.key).sort.compareTo(names.of(b.key).sort) : b.value.compareTo(a.value),
            ))
            .map((MapEntry<int, Money> row) => '${names.nameOf(row.key)} ${_money.digits(row.value)}${_limit(names.of(row.key))}')
            .toList();
    return 'Spent ${_money.format(_sum(entries, EntryKind.spent))}, got ${_money.format(_sum(entries, EntryKind.got))}. '
        'By category: ${rows.isEmpty ? 'none' : rows.join('; ')}.';
  }

  static String _limit(Category category) => category.limit.match(() => '', (Money l) => ' (limit ${_money.digits(l)} a pay cycle)');

  static String _bills(List<RecurringRule> bills) {
    final List<String> rows =
        (bills.toList()
              ..sort((RecurringRule a, RecurringRule b) => a.nextDue == b.nextDue ? a.id.compareTo(b.id) : a.nextDue.compareTo(b.nextDue)))
            .map(
              (RecurringRule bill) => bill.schedule.frequency == Frequency.monthly
                  ? '${bill.label} ${_money.digits(bill.amount)} monthly on day ${bill.schedule.anchor.day}'
                  : '${bill.label} ${_money.digits(bill.amount)} ${bill.schedule.frequency.name}',
            )
            .toList();
    return 'Recurring bills: ${rows.isEmpty ? 'none' : rows.join('; ')}.';
  }

  static String _earlierWeeks(Iterable<PayCycle> weeks, List<Entry> entries) {
    final List<String> rows = weeks.map((PayCycle week) {
      final List<Entry> inWeek = entries.where((Entry e) => week.contains(e.date)).toList();
      return '${week.start.toIso()}..${week.end.toIso()} '
          '${_money.digits(_sum(inWeek, EntryKind.spent))}/${_money.digits(_sum(inWeek, EntryKind.got))}';
    }).toList();
    return 'Earlier weeks (spent/got): ${rows.join('; ')}';
  }

  static String _entrySection(Iterable<Entry> entries, _Names names, {required bool hideNotes}) => <String>[
    'Entries (CSV):',
    hideNotes ? 'date,amount,kind,category' : 'date,amount,kind,category,note',
    ...entries.map(
      (Entry e) => <String>[
        e.date.toIso(),
        '${e.amount.floorMajor}',
        e.kind.name,
        PromptCsv.field(names.nameOf(e.categoryId)),
        if (!hideNotes) PromptCsv.field(e.note ?? ''),
      ].join(','),
    ),
  ].join('\n');

  static String _task(PromptChoice choice) => switch (choice.goal) {
    AskGoal.reviewMonth =>
      'Task: Tell me how this period went. Give: 1) 3 things that stand out, good or bad, with ₹ amounts '
          '2) the one change that would save the most, and how much a month 3) one habit worth keeping.',
    AskGoal.helpMeSave =>
      'Task: Show me where I can save. Give 5 specific cuts, easiest first, each with how much it saves a month, '
          "then the total. Don't cut rent, EMIs, other fixed bills or health.",
    AskGoal.makeBudget =>
      'Task: Suggest a spending limit per category for one pay cycle. Together they must fit my income after fixed '
          'bills and what I keep aside. Show a table: category, limit in ₹, one short reason.',
    AskGoal.onTrack =>
      "Task: Will my money last till payday? Use the numbers from my app as correct; don't recalculate them. "
          'Tell me which 1–2 categories are pushing my pace up and one thing to change this week.',
    AskGoal.ownQuestion => 'My question: ${choice.question.trim()}',
  };

  static Money _sum(Iterable<Entry> entries, EntryKind kind) =>
      entries.where((Entry e) => e.kind == kind).fold(Money.zero, (Money total, Entry e) => total + e.amount);
}

/// Categories by id, with the name each is shown under.
final class _Names {
  _Names(List<Category> categories, this._nameOf) : _byId = <int, Category>{for (final Category c in categories) c.id: c};

  final Map<int, Category> _byId;
  final String Function(Category) _nameOf;

  // why: categories are a fixed seed list that never shrinks (BR-11) and entries reference them
  // by foreign key, so every id an entry carries resolves.
  Category of(int id) => _byId[id]!;

  String nameOf(int id) => _nameOf(of(id));
}

/// One prompt being built: the lines before the CSV, the period's entries and its weeks.
final class _Draft {
  const _Draft({required this.head, required this.entries, required this.weeks, required this.names, required this.choice});

  final String head;
  final List<Entry> entries;
  final List<PayCycle> weeks;
  final _Names names;
  final PromptChoice choice;

  /// The full prompt with the [grouped] oldest weeks summarised instead of listed.
  PromptText grouping(int grouped) {
    final CalendarDate listedFrom = grouped == 0 ? weeks.first.start : weeks[grouped - 1].end.addDays(1);
    final String text = <String>[
      head,
      if (grouped > 0) PromptBuilder._earlierWeeks(weeks.take(grouped), entries),
      PromptBuilder._entrySection(entries.where((Entry e) => !e.date.isBefore(listedFrom)), names, hideNotes: choice.hideNotes),
      '',
      PromptBuilder._task(choice),
    ].join('\n');
    return PromptText(text: text, entryCount: entries.length, groupedWeeks: grouped);
  }
}
