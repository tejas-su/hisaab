import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/shortcuts/data/mapper/widget_snapshot_json.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

const WidgetStrings _strings = WidgetStrings(title: 'T', add: 'A', addSpoken: 'AS', setUp: 'S', setUpBody: 'SB');

WidgetDay _day({Option<String> over = const Option<String>.none(), Option<double> tick = const Option<double>.none()}) => WidgetDay(
      date: const CalendarDate(2026, 10, 26),
      state: WidgetDayState.overToday,
      hero: '₹0',
      heroMuted: true,
      over: over,
      glance: 'g',
      range: 'r',
      days: '9 days',
      daysLeft: '9 days left',
      flag: '4 Nov',
      bar: WidgetBar(style: WidgetBarStyle.over, left: 0, bites: const <double>[0.5, 0.5], tick: tick),
      dots: const WidgetDots(count: 9, style: WidgetDotsStyle.overToday),
      spoken: 'spoken',
    );

void main() {
  group('WidgetSnapshotJson.toJson', () {
    test('writes the version, time, look, strings and each row (widget spec §4)', () {
      final Map<String, Object?> json = WidgetSnapshotJson.toJson(
        WidgetSnapshot(
          writtenAt: DateTime(2026, 10, 26, 21, 14, 5),
          look: ThemeChoice.matchPhone,
          strings: _strings,
          rows: <WidgetDay>[_day(over: const Option<String>.of('₹220 over today'), tick: const Option<double>.of(0.9))],
        ),
      );

      expect(json, <String, Object?>{
        'v': 1,
        'writtenAt': '2026-10-26T21:14:05.000',
        'look': 'system',
        'strings': <String, Object?>{'title': 'T', 'add': 'A', 'addSpoken': 'AS', 'setUp': 'S', 'setUpBody': 'SB'},
        'rows': <Object?>[
          <String, Object?>{
            'date': '2026-10-26',
            'state': 'overToday',
            'hero': '₹0',
            'heroMuted': true,
            'over': '₹220 over today',
            'glance': 'g',
            'range': 'r',
            'days': '9 days',
            'daysLeft': '9 days left',
            'flag': '4 Nov',
            'bar': <String, Object?>{'style': 'over', 'left': 0.0, 'bites': <double>[0.5, 0.5], 'tick': 0.9},
            'dots': <String, Object?>{'count': 9, 'style': 'overToday'},
            'spoken': 'spoken',
          },
        ],
      });
    });

    test('writes null for no over line and no tick', () {
      final Map<String, Object?> row = (WidgetSnapshotJson.toJson(
        WidgetSnapshot(writtenAt: DateTime(2026), look: ThemeChoice.light, strings: _strings, rows: <WidgetDay>[_day()]),
      )['rows']! as List<Object?>)
          .single! as Map<String, Object?>;

      expect(row['over'], isNull);
      expect((row['bar']! as Map<String, Object?>)['tick'], isNull);
    });

    const Map<ThemeChoice, String> looks = <ThemeChoice, String>{
      ThemeChoice.matchPhone: 'system',
      ThemeChoice.light: 'light',
      ThemeChoice.dark: 'dark',
    };
    for (final MapEntry<ThemeChoice, String> look in looks.entries) {
      test('writes the ${look.key.name} look as "${look.value}"', () {
        final Map<String, Object?> json =
            WidgetSnapshotJson.toJson(WidgetSnapshot(writtenAt: DateTime(2026), look: look.key, strings: _strings, rows: const <WidgetDay>[]));
        expect(json['look'], look.value);
        expect(json['rows'], isEmpty);
      });
    }
  });
}
