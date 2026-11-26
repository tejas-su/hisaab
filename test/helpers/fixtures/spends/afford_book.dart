import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';

/// The owner's *Can I afford it?* numbers (SPEC BR-24 worked example, mockup 52) as ledger data:
/// payday on the 4th, today Mon 26 Oct 2026, so the next cycle is 4 Nov to 3 Dec (30 days) and
/// the last finished one 4 Sep to 3 Oct (30 days).
abstract final class AffordBook {
  static final DateTime now = DateTime(2026, 10, 26, 10, 30);

  /// The id of [mac], the saving named like the item.
  static const int macId = 7;

  /// Income on the 4th and one bill of [bills] on the 5th: room = income − bills.
  static List<RecurringRule> rules({int income = 45000, int bills = 13000}) => <RecurringRule>[
        _rule(1, 'Salary', income, EntryKind.got, const CalendarDate(2026, 11, 4), isIncomeSource: true),
        _rule(2, 'Rent', bills, EntryKind.spent, const CalendarDate(2026, 11, 5)),
      ];

  /// An active saving named "Mac", ₹5,000 a month on the 5th, with [target].
  static RecurringRule mac({Option<Money> target = const Option<Money>.none()}) =>
      _rule(macId, 'Mac', 5000, EntryKind.saved, const CalendarDate(2026, 11, 5), target: target);

  /// A finished, fully tracked cycle averaging [usual] a day, logged from 1 Sep.
  static List<Entry> history({int usual = 750}) => <Entry>[
        Entry(
          id: 1,
          amount: Money.fromMajor(usual * 30),
          kind: EntryKind.spent,
          categoryId: 1,
          date: const CalendarDate(2026, 9, 10),
          createdAt: DateTime(2026, 9, 1, 9),
        ),
      ];

  /// [rupees] and [paise] put into [mac] this cycle.
  static Entry putIntoMac(int rupees, {int paise = 0}) => Entry(
        id: 2,
        amount: Money(Money.fromMajor(rupees).amountMinor + paise),
        kind: EntryKind.saved,
        categoryId: 1,
        date: const CalendarDate(2026, 10, 5),
        createdAt: DateTime(2026, 10, 5, 9),
        recurringId: macId,
      );

  static RecurringRule _rule(
    int id,
    String label,
    int rupees,
    EntryKind kind,
    CalendarDate anchor, {
    bool isIncomeSource = false,
    Option<Money> target = const Option<Money>.none(),
  }) =>
      RecurringRule(
        id: id,
        label: label,
        amount: Money.fromMajor(rupees),
        kind: kind,
        categoryId: 1,
        schedule: Schedule(frequency: Frequency.monthly, anchor: anchor),
        nextDue: anchor,
        isIncomeSource: isIncomeSource,
        target: target,
      );
}
