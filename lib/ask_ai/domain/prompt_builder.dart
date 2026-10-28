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

/// Turns the ledger into the Ask AI prompt (SPEC BR-15): role, context, summary, bills,
/// entries as CSV, then the task.
///
/// The text is English whatever the app language, since it is written for the AI, and it is
/// byte-identical for the same input (DECISIONS D59).
abstract final class PromptBuilder {
  /// The longest text before the oldest entries are grouped by week.
  static const int maxLength = 12000;

  static final MoneyFormatter _money = MoneyFormatter();

  static const String _role = 'You are a friendly money coach. Be specific, use my numbers, no jargon.';

  static const List<String> _weekdays = <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// Builds the prompt for [choice] from [input]; [nameOf] gives each category's shown name.
  static PromptText build(PromptInput input, PromptChoice choice, {required String Function(Category) nameOf}) {
    final List<PayCycle> cycles = input.cycles.take(choice.period.cycleCount).toList();
    final CalendarDate start = cycles.last.start;
    final CalendarDate end = cycles.first.end;
    final List<Entry> entries =
        input.entries.where((Entry e) => !e.date.isBefore(start) && !e.date.isAfter(end) && !e.date.isAfter(input.today)).toList()
          ..sort((Entry a, Entry b) => a.date == b.date ? a.id.compareTo(b.id) : a.date.compareTo(b.date));
    final Map<int, Category> categories = <int, Category>{for (final Category c in input.categories) c.id: c};
    String name(Entry entry) => nameOf(categories[entry.categoryId]!);
    final String head = <String>[
      _role,
      _context(input, start, end),
      _summary(entries, categories, nameOf),
      _bills(input.bills),
      '',
    ].join('\n');
    final String task = _task(choice);
    final List<PayCycle> weeks = _weeks(start, end);
    for (int grouped = 0; ; grouped++) {
      final CalendarDate listedFrom = grouped == 0 ? start : weeks[grouped - 1].end.addDays(1);
      final String text = <String>[
        head,
        if (grouped > 0) _earlierWeeks(weeks.take(grouped), entries),
        _entrySection(entries.where((Entry e) => !e.date.isBefore(listedFrom)), name, hideNotes: choice.hideNotes),
        '',
        task,
      ].join('\n');
      if (text.length <= maxLength || grouped == weeks.length) {
        return PromptText(text: text, entryCount: entries.length, groupedWeeks: grouped);
      }
    }
  }

  // why: blocks from the period start, not calendar weeks, so the first block never straddles
  // the period's start and every grouped line covers whole days of the period (DECISIONS D64).
  static List<PayCycle> _weeks(CalendarDate start, CalendarDate end) => <PayCycle>[
    for (CalendarDate from = start; !from.isAfter(end); from = from.addDays(7))
      PayCycle(start: from, end: from.addDays(6).isAfter(end) ? end : from.addDays(6)),
  ];

  static String _earlierWeeks(Iterable<PayCycle> weeks, List<Entry> entries) {
    final List<String> rows = weeks.map((PayCycle week) {
      final List<Entry> inWeek = entries.where((Entry e) => week.contains(e.date)).toList();
      return '${week.start.toIso()}..${week.end.toIso()} '
          '${_money.digits(_sum(inWeek, EntryKind.spent))}/${_money.digits(_sum(inWeek, EntryKind.got))}';
    }).toList();
    return 'Earlier weeks (spent/got): ${rows.join('; ')}';
  }

  static String _context(PromptInput input, CalendarDate start, CalendarDate end) {
    final String income = input.incomeRule.match(
      () => 'varies',
      (RecurringRule rule) =>
          '${_money.format(rule.amount)}/${rule.schedule.frequency == Frequency.weekly ? 'week' : 'month'} (${_payday(input.payRule)})',
    );
    return 'Context: income $income, currency ${Money.zero.currency.code}, period ${start.toIso()}..${end.toIso()}, '
        'today ${input.today.toIso()}.';
  }

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

  static String _summary(List<Entry> entries, Map<int, Category> categories, String Function(Category) nameOf) {
    final Map<int, Money> spentBy = <int, Money>{};
    for (final Entry entry in entries.where((Entry e) => e.kind == EntryKind.spent)) {
      spentBy[entry.categoryId] = (spentBy[entry.categoryId] ?? Money.zero) + entry.amount;
    }
    final List<String> rows =
        (spentBy.entries.toList()..sort(
              (MapEntry<int, Money> a, MapEntry<int, Money> b) =>
                  a.value == b.value ? categories[a.key]!.sort.compareTo(categories[b.key]!.sort) : b.value.compareTo(a.value),
            ))
            .map((MapEntry<int, Money> row) {
              final Category category = categories[row.key]!;
              final String limit = category.limit.match(() => '', (Money l) => ' (limit ${_money.digits(l)} a month)');
              return '${nameOf(category)} ${_money.digits(row.value)}$limit';
            })
            .toList();
    return 'Spent ${_money.format(_sum(entries, EntryKind.spent))}, got ${_money.format(_sum(entries, EntryKind.got))}. '
        'By category: ${rows.isEmpty ? 'none' : rows.join('; ')}.';
  }

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

  static String _entrySection(Iterable<Entry> entries, String Function(Entry) name, {required bool hideNotes}) => <String>[
    'Entries (CSV):',
    hideNotes ? 'date,amount,kind,category' : 'date,amount,kind,category,note',
    for (final Entry e in entries)
      <String>[
        e.date.toIso(),
        '${e.amount.floorMajor}',
        e.kind.name,
        PromptCsv.field(name(e)),
        if (!hideNotes) PromptCsv.field(e.note ?? ''),
      ].join(','),
  ].join('\n');

  static String _task(PromptChoice choice) => switch (choice.goal) {
    AskGoal.reviewMonth => 'Task: Review my month. Give: 1) the 3 biggest problems 2) 3 concrete savings with ₹ amounts 3) a budget per category for next month 4) one habit to change.',
    AskGoal.helpMeSave =>
      'Task: Help me save more. Give 5 specific cuts with ₹ amounts a month, easiest first, and the total I would save.',
    AskGoal.makeBudget => 'Task: Make me a monthly budget per category that fits my income and leaves room to save. Show a table with ₹ amounts and one line on why for each.',
    AskGoal.onTrack => 'Task: Am I on track to last until my next payday? Compare my spending pace with the days left and tell me how much I can spend each day from now.',
    AskGoal.ownQuestion => 'Task: ${choice.question.trim()}',
  };

  static Money _sum(List<Entry> entries, EntryKind kind) =>
      entries.where((Entry e) => e.kind == kind).fold(Money.zero, (Money total, Entry e) => total + e.amount);
}
