// Store-screenshot demo: the real app on in-memory fakes, pinned to the SPEC worked example
// (today Mon 26 Oct 2026 10:30, payday the 4th, hero ₹1,430). It never opens the database, so
// installing it over a debug build leaves the owner's data alone.
//
//   flutter run -d <device> -t tool/store/demo_main.dart [--dart-define=DEMO_THEME=dark]
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/font_licenses.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/helpers/fake_services.dart';
import '../../test/helpers/fixtures/ledger/worked_example.dart';

const String _theme = String.fromEnvironment('DEMO_THEME', defaultValue: 'light');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'en_IN';
  await initializeDateFormatting('en_IN');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  registerFontLicenses();

  final FakeServices services = FakeServices(entries: _entries())
    ..preferences.theme = _theme == 'dark' ? ThemeChoice.dark : ThemeChoice.light;
  runApp(HisaabApp(getIt: services.register(GetIt.I)));
}

int _id = 100;

Entry _e(int day, int category, int rupees, String note, int hour, int minute) => Entry(
      id: _id++,
      amount: Money.fromMajor(rupees),
      kind: EntryKind.spent,
      categoryId: category,
      date: CalendarDate(2026, 10, day),
      createdAt: DateTime(2026, 10, day, hour, minute),
      note: note,
    );

/// The worked example's ledger with its ₹18,950 of typed spends spread over the cycle so far.
List<Entry> _entries() {
  const int food = 1, travel = 2, shopping = 3, bills = 4, fun = 5, health = 6, other = 8;
  final List<Entry> typed = <Entry>[
    // A weekday chai at about 10, so *your usual* has a habit to offer.
    for (final int d in <int>[5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 19, 20, 21, 22, 23]) _e(d, food, 20, 'Chai', 10, 2 + d % 6),
    _e(4, shopping, 2400, 'Kurta for Diwali', 18, 10),
    _e(5, travel, 1500, 'Metro card', 8, 40),
    _e(6, food, 640, 'Groceries', 19, 5),
    _e(8, fun, 900, 'Movie night', 21, 0),
    _e(9, health, 450, 'Medicines', 12, 15),
    _e(10, food, 1200, 'Dinner with friends', 21, 30),
    _e(11, shopping, 1850, 'Shoes', 17, 20),
    _e(12, travel, 380, 'Auto', 9, 10),
    _e(13, food, 720, 'Groceries', 19, 0),
    _e(14, bills, 599, 'Phone recharge', 11, 0),
    _e(15, travel, 260, 'Cab home', 22, 10),
    _e(16, fun, 499, 'Cricket tickets', 20, 0),
    _e(17, food, 860, 'Weekend groceries', 11, 30),
    _e(18, fun, 650, 'Bowling', 18, 0),
    _e(19, food, 340, 'Lunch', 13, 15),
    _e(20, shopping, 1400, 'Diwali lights', 18, 45),
    _e(21, health, 800, 'Gym month', 7, 30),
    _e(22, travel, 420, 'Auto', 9, 5),
    _e(23, food, 980, 'Groceries', 19, 20),
    _e(24, fun, 750, 'Mall with family', 17, 0),
    _e(25, food, 520, 'Sweets', 16, 40),
  ];
  final int sum = typed.fold(0, (int a, Entry e) => a + e.amount.floorMajor);
  // why: the hero only reads ₹1,430 if typed spends before today total exactly ₹18,950.
  typed.add(_e(24, other, 18950 - sum, 'Gifts', 15, 0));

  final List<Entry> base = WorkedExample.entries.where((Entry e) => e.id != 3).toList();
  return <Entry>[...base, ...typed];
}
