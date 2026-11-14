import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/l10n/gen/app_localizations_en.dart';
import 'package:intl/date_symbol_data_local.dart';

final AppLocalizations _strings = AppLocalizationsEn();

/// A habit whose window is the 60 minutes around [hour], so "around" reads that hour.
UsualHabit _habit({required int hour, DayType dayType = DayType.weekday, bool pooled = false}) => UsualHabit(
      categoryId: 13,
      dayType: dayType,
      pooled: pooled,
      window: TimeWindow(startMinute: (hour * 60 - 30) % 1440, lengthMinutes: 60),
      amount: Money.fromMajor(20),
      hitDays: 18,
      activeDays: 20,
      lastHit: DateTime(2026, 10, 23, 10, 5),
      fading: false,
    );

String _detail(UsualHabit habit, {String amount = '₹20'}) =>
    UsualWords.detail(_strings, habit, amount: amount, locale: 'en_IN');

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  group('UsualWords.detail (FR-SE-2 AC-6, BR-17 "around {time}")', () {
    final List<(String, UsualHabit, String, String)> cases = <(String, UsualHabit, String, String)>[
      ('a weekday habit', _habit(hour: 10), '₹20', '₹20, weekdays around 10 am'),
      ('a weekend habit', _habit(hour: 13, dayType: DayType.weekend), '₹120', '₹120, weekends around 1 pm'),
      ('a pooled habit names no day', _habit(hour: 10, pooled: true), '₹20', '₹20, around 10 am'),
      ('a pooled habit offered on weekends names no day', _habit(hour: 10, dayType: DayType.weekend, pooled: true), '₹20', '₹20, around 10 am'),
      ('midnight is 12 am', _habit(hour: 0), '₹20', '₹20, weekdays around 12 am'),
      ('noon is 12 pm', _habit(hour: 12), '₹20', '₹20, weekdays around 12 pm'),
      ('the last hour of the day', _habit(hour: 23), '₹20', '₹20, weekdays around 11 pm'),
      ('the spoken amount is passed through', _habit(hour: 10), '20 rupees', '20 rupees, weekdays around 10 am'),
    ];
    for (final (String name, UsualHabit habit, String amount, String expected) in cases) {
      test('$name: "$expected"', () => expect(_detail(habit, amount: amount), expected));
    }

    test('a window whose middle is on the half hour rounds up (9:45–11:15 is 11 am)', () {
      final UsualHabit habit = UsualHabit(
        categoryId: 13,
        dayType: DayType.weekday,
        pooled: false,
        window: const TimeWindow(startMinute: 585, lengthMinutes: 90),
        amount: Money.fromMajor(20),
        hitDays: 18,
        activeDays: 20,
        lastHit: DateTime(2026, 10, 23, 10, 5),
        fading: false,
      );
      expect(_detail(habit), '₹20, weekdays around 11 am');
    });

    test('the time has no narrow no-break space', () {
      expect(_detail(_habit(hour: 10)).contains(String.fromCharCode(0x202F)), isFalse);
      expect(_detail(_habit(hour: 10)).endsWith('10 am'), isTrue);
    });
  });
}
