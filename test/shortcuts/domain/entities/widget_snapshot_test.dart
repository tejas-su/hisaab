import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

WidgetDay _day({String hero = '₹1,430', double left = 0.5}) => WidgetDay(
      date: const CalendarDate(2026, 10, 26),
      state: WidgetDayState.onTrack,
      hero: hero,
      heroMuted: false,
      over: const Option<String>.none(),
      glance: 'left today',
      range: 'r',
      days: '9 days',
      daysLeft: '9 days left',
      flag: '4 Nov',
      bar: WidgetBar(style: WidgetBarStyle.onTrack, left: left, bites: const <double>[], tick: const Option<double>.none()),
      dots: const WidgetDots(count: 9, style: WidgetDotsStyle.onTrack),
      spoken: 's',
    );

WidgetSnapshot _snapshot(List<WidgetDay> rows) => WidgetSnapshot(
      writtenAt: DateTime(2026, 10, 26),
      look: ThemeChoice.matchPhone,
      strings: const WidgetStrings(title: 'T', add: 'A', addSpoken: 'AS', setUp: 'S', setUpBody: 'SB'),
      rows: rows,
    );

void main() {
  group('WidgetSnapshot entities compare by value', () {
    test('the same snapshot is equal; another hero or bar is not', () {
      expect(_snapshot(<WidgetDay>[_day()]), _snapshot(<WidgetDay>[_day()]));
      expect(_snapshot(<WidgetDay>[_day()]), isNot(_snapshot(<WidgetDay>[_day(hero: '₹0')])));
      expect(_day(), isNot(_day(left: 1)));
    });
  });
}
