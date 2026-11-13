import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/money/money_formatter.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

import '../../helpers/fake_services.dart';
import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));
  final WidgetWords words = (strings: lookupAppLocalizations(const Locale('en')), money: MoneyFormatter());
  final DateTime writtenAt = DateTime(2026, 10, 26, 21, 14);

  Future<List<ProjectedDay>> project(FakeServices services) async =>
      (await services.projectWidgetDays(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));

  Future<WidgetSnapshot> snapshotOf(FakeServices services, {ThemeChoice look = ThemeChoice.matchPhone}) async =>
      WidgetSnapshotMapper.of(await project(services), look: look, writtenAt: writtenAt, words: words);

  Entry spentToday(int id, int rupees) => Entry(
        id: id,
        amount: Money.fromMajor(rupees),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: DateTime(2026, 10, 26, 12, id),
      );

  group('WidgetSnapshotMapper', () {
    test("words today as Home's hero does, for the worked example (FR-WG-1, FR-WG-8)", () async {
      final WidgetSnapshot snapshot = await snapshotOf(FakeServices());
      final WidgetDay today = snapshot.rows.first;

      expect(snapshot.writtenAt, writtenAt);
      expect(snapshot.look, ThemeChoice.matchPhone);
      expect(
        snapshot.strings,
        const WidgetStrings(
          title: 'Safe to spend today',
          add: 'Add',
          addSpoken: 'Add a spend',
          setUp: 'Set up',
          setUpBody: "Set up hisaab to see what's safe to spend today.",
        ),
      );
      expect(today.date, WorkedExample.today);
      expect(today.state, WidgetDayState.onTrack);
      expect((today.hero, today.heroMuted, today.over), ('₹1,430', false, const Option<String>.none()));
      expect(today.glance, 'left today');
      expect(today.range, 'Lasts till payday · about ₹9,300 spare');
      expect((today.days, today.daysLeft, today.flag), ('9 days', '9 days left', '4 Nov'));
      expect(today.dots, const WidgetDots(count: 9, style: WidgetDotsStyle.onTrack));
      expect(today.bar.style, WidgetBarStyle.onTrack);
      expect(today.bar.bites, hasLength(3));
      expect(today.bar.left, closeTo(1430 / 1850, 1e-9));
      expect(today.bar.tick, const Option<double>.none());
      expect(today.spoken, 'Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday, about 9,300 rupees spare.');
    });

    test('a later day has no bites and one day fewer', () async {
      final WidgetDay tomorrow = (await snapshotOf(FakeServices())).rows[1];

      expect(tomorrow.date, const CalendarDate(2026, 10, 27));
      expect(tomorrow.bar.bites, isEmpty);
      expect(tomorrow.bar.left, 1);
      expect(tomorrow.days, '8 days');
    });

    test('the last day of the cycle says 1 day', () async {
      final WidgetDay last = (await snapshotOf(FakeServices())).rows.firstWhere((WidgetDay d) => d.date == const CalendarDate(2026, 11, 3));

      expect((last.days, last.daysLeft), ('1 day', '1 day left'));
    });

    test('over today shows ₹0, muted, with the over line and a tick (BR-5 #3)', () async {
      final FakeServices services = FakeServices(entries: <Entry>[...WorkedExample.entries, spentToday(7, 1650)]);

      final WidgetDay today = (await snapshotOf(services)).rows.first;

      expect(today.state, WidgetDayState.overToday);
      expect((today.hero, today.heroMuted), ('₹0', true));
      expect(today.over, const Option<String>.of('₹220 over today'));
      expect(today.glance, '₹220 over today');
      expect(today.bar.style, WidgetBarStyle.over);
      expect(today.bar.tick.isSome(), isTrue);
      expect(today.dots.style, WidgetDotsStyle.overToday);
    });

    test('over the cycle says "Over by" on the 2×1 line (§15 #4, BR-5 #2)', () async {
      final FakeServices services = FakeServices(entries: <Entry>[...WorkedExample.entries, spentToday(7, 20000)]);

      final WidgetDay today = (await snapshotOf(services)).rows.first;

      expect(today.state, WidgetDayState.overCycle);
      expect(today.hero, '₹0');
      expect(today.over.isSome(), isTrue);
      expect(today.glance, startsWith('Over by ₹'));
      expect(today.dots.style, WidgetDotsStyle.overCycle);
    });

    test('a slow day draws an outlined bar and ring (BR-5 #4)', () async {
      final FakeServices services = FakeServices(entries: <Entry>[...WorkedExample.entries, spentToday(7, 1100)]);

      final WidgetDay today = (await snapshotOf(services)).rows.first;

      expect(today.state, WidgetDayState.slowDown);
      expect(today.bar.style, WidgetBarStyle.slowDown);
      expect(today.dots.style, WidgetDotsStyle.slowDown);
      expect(today.glance, 'left today');
    });

    test('no income is the set-up state (FR-WG-3, E51)', () async {
      final WidgetSnapshot snapshot = await snapshotOf(FakeServices(entries: const <Entry>[], rules: const <RecurringRule>[]));

      expect(snapshot.rows.map((WidgetDay d) => d.state).toSet(), <WidgetDayState>{WidgetDayState.setUp});
      expect(snapshot.rows.first.glance, 'left today');
    });

    test('keeps the look it is given', () async {
      expect((await snapshotOf(FakeServices(), look: ThemeChoice.dark)).look, ThemeChoice.dark);
    });
  });
}
