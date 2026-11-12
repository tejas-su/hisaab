import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';

import '../ledger/categories.dart';

/// A category the user made, with a daily habit in the *your usual* tests (mockup 40).
const Category chai = Category(
  id: 13,
  key: 'own_13',
  iconKey: 'chai',
  kind: EntryKind.spent,
  sort: 8,
  customName: 'Chai',
);

/// The built-in Food category, used for the entries that only make a day "active".
final Category food = seedCategories.first;

/// One entry of [rupees] in [category], logged at [createdAt] and dated that day unless [date] is given.
Entry entryAt(
  int id,
  Category category,
  int rupees,
  DateTime createdAt, {
  CalendarDate? date,
  int? recurringId,
  EntryKind kind = EntryKind.spent,
}) =>
    Entry(
      id: id,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: category.id,
      date: date ?? CalendarDate.fromDateTime(createdAt),
      createdAt: createdAt,
      recurringId: recurringId,
    );

/// One entry in [category] on each of [dates], logged that day at [hour]:[minute].
List<Entry> entriesOn(
  Iterable<CalendarDate> dates,
  Category category, {
  int rupees = 20,
  int hour = 10,
  int minute = 5,
  int firstId = 1,
}) =>
    dates.indexed
        .map(
          ((int, CalendarDate) item) => entryAt(
            firstId + item.$1,
            category,
            rupees,
            DateTime(item.$2.year, item.$2.month, item.$2.day, hour, minute),
          ),
        )
        .toList();

/// The dates of [type] in the [days] days before [today], oldest first. Today is never one.
List<CalendarDate> daysBefore(CalendarDate today, DayType type, {int days = 28}) =>
    List<CalendarDate>.generate(days, (int index) => today.addDays(index - days))
        .where((CalendarDate date) => DayType.of(date) == type)
        .toList();

/// One Food entry at 13:00 on each of [dates]. Every amount differs, so Food never has a usual
/// amount and never forms a habit of its own.
List<Entry> foodOn(Iterable<CalendarDate> dates, {int firstId = 1}) => dates.indexed
    .map(
      ((int, CalendarDate) item) => entryAt(
        firstId + item.$1,
        food,
        100 + item.$1,
        DateTime(item.$2.year, item.$2.month, item.$2.day, 13),
      ),
    )
    .toList();

/// Food on 26 dates from 31 days before [today] (25 Sep for 26 Oct 2026): that day, all 20
/// weekdays of the 28 days before [today], and the first 5 weekend days of the 30 days before it.
List<Entry> foodDays(CalendarDate today) => foodOn(<CalendarDate>[
      today.addDays(-31),
      ...daysBefore(today, DayType.weekday),
      ...daysBefore(today, DayType.weekend, days: 30).take(5),
    ]);

/// Food on the 10 oldest days of the 56 (1–10 Sep for 26 Oct 2026): enough for the warm-up, and
/// outside the 28 days rule 3 counts.
List<Entry> warmUpFood(CalendarDate today) =>
    foodOn(List<CalendarDate>.generate(10, (int index) => today.addDays(index - 55)));

/// Mockup 40's worked example for `today = 26 Oct 2026`: [foodDays], plus Chai at 10:05 on the
/// weekdays of the 28 days before [today], skipping the oldest [misses] of them. The oldest
/// [otherAmounts] Chai entries are ₹30, the rest ₹20. Nothing is dated [today].
List<Entry> chaiWeekdays({required CalendarDate today, int misses = 2, int otherAmounts = 1}) {
  final List<CalendarDate> hitDays = daysBefore(today, DayType.weekday).skip(misses).toList();
  return <Entry>[
    ...foodDays(today),
    ...entriesOn(hitDays.take(otherAmounts), chai, rupees: 30, firstId: 101),
    ...entriesOn(hitDays.skip(otherAmounts), chai, firstId: 201),
  ];
}
