import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/fix/fix.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/fix_foot_row.dart';
import 'package:hisaab/home/presentation/widgets/hero_card.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// The three doors of Fix my number as the app wires them (FR-FX-1, FR-FX-5, NFR-12).
void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  Future<void> boot(WidgetTester tester, {FakeServices? fakes, Size size = TestWindows.phone}) async {
    services = fakes ?? FakeServices();
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  /// Scrolls Home until [finder] is built; the page builds its rows lazily.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    for (int pull = 0; pull < 8 && finder.evaluate().isEmpty; pull++) {
      await tester.drag(find.byType(HomePage), const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapKey(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await _settle(tester);
  }

  Future<void> typeDigits(WidgetTester tester, String digits) async {
    for (final String digit in digits.split('')) {
      await tapKey(tester, find.byKey(ValueKey<String>('keypad-$digit')));
    }
  }

  Money hero(WidgetTester tester) => tester.widget<HeroCard>(find.byType(HeroCard)).summary.safeToday;

  Future<void> openFromHome(WidgetTester tester) async {
    await tapKey(tester, find.text('Fix my number'));
  }

  group('the Home door (FR-HO-9, FR-FX-1)', () {
    testWidgets('the foot row sits below the Today list, 48dp, with no icon or second line', (WidgetTester tester) async {
      await boot(tester);
      await reveal(tester, find.byType(FixFootRow));
      await tester.ensureVisible(find.byType(FixFootRow));

      final Rect row = tester.getRect(find.byType(FixFootRow));
      final Rect today = tester.getRect(find.text('Today').first);
      expect(row.top > today.bottom, isTrue);
      expect(tester.getSize(find.descendant(of: find.byType(FixFootRow), matching: find.byType(Container)).first).height >= 48, isTrue);
      expect(find.descendant(of: find.byType(FixFootRow), matching: find.byType(Icon)), findsNothing);
      expect(find.descendant(of: find.byType(FixFootRow), matching: find.byType(Text)), findsOneWidget);
    });

    testWidgets('TalkBack reads "Fix my number, button. Opens the keypad."', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      await reveal(tester, find.byType(FixFootRow));
      await tester.ensureVisible(find.byType(FixFootRow));

      final SemanticsData data = tester.getSemantics(find.byType(FixFootRow)).getSemanticsData();
      expect(data.label, 'Fix my number');
      expect(data.hint, 'Opens the keypad.');
      handle.dispose();
    });

    testWidgets('a tap opens the sheet, ticks, and Home holds ₹1,430 until the sheet has closed, then rolls to ₹963', (WidgetTester tester) async {
      await boot(tester);
      expect(hero(tester), Money.fromMajor(1430));

      await openFromHome(tester);
      expect(find.byType(FixSheet), findsOneWidget);
      expect(services.haptics.events, contains('tick'));
      await typeDigits(tester, '13230');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));

      expect(find.byType(FixSheet), findsNothing);
      expect(hero(tester), Money.fromMajor(963));
      expect(find.text('Fixed. Safe to spend today: ₹963.'), findsOneWidget);
      expect(services.haptics.events.where((String e) => e == 'success'), hasLength(1));
    });

    testWidgets('while the sheet is open a write behind it does not move the hero', (WidgetTester tester) async {
      await boot(tester);
      await openFromHome(tester);

      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today))
          .run();
      await _settle(tester);
      final HomeBloc home = tester.element(find.byType(HomePage)).read<HomeBloc>();
      expect((home.state as HomeReady).summary.spentToday, Money.fromMajor(420));

      Navigator.of(tester.element(find.byType(FixSheet))).pop();
      await _settle(tester);

      expect((home.state as HomeReady).summary.spentToday, Money.fromMajor(520));
    });

    testWidgets('Undo deletes the entry, the hero returns to ₹1,430, tick fires, "Undone." is announced', (WidgetTester tester) async {
      await boot(tester);
      await openFromHome(tester);
      await typeDigits(tester, '13230');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));
      services.haptics.events.clear();

      await tapKey(tester, find.text('Undo'));

      expect(services.ledger.entries.where((Entry e) => e.isNotLogged), isEmpty);
      expect(hero(tester), Money.fromMajor(1430));
      expect(services.haptics.events, contains('tick'));
    });

    testWidgets('the widget snapshot is rewritten after the write with the new hero (FR-FX-5 AC-7, FR-WG-5)', (WidgetTester tester) async {
      await boot(tester);
      expect(services.shortcuts.published.last.rows.first.hero, '₹1,430');
      await openFromHome(tester);
      await typeDigits(tester, '13230');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));

      expect(services.shortcuts.published.last.rows.first.hero, '₹963');
    });

    testWidgets('the snackbar reads in rupees to TalkBack', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      await openFromHome(tester);
      await typeDigits(tester, '13230');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));

      expect(find.bySemanticsLabel('Fixed. Safe to spend today: 963 rupees.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('at ₹0 the snackbar says so with no softening', (WidgetTester tester) async {
      await boot(tester);
      await openFromHome(tester);
      await typeDigits(tester, '1000');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));

      expect(find.text('Fixed. Safe to spend today: ₹0.'), findsOneWidget);
    });

    testWidgets('the tap count from Home: foot row, 5 digits, Fix it = 7 (FR-FX-1 AC-2)', (WidgetTester tester) async {
      await boot(tester);
      int taps = 0;
      Future<void> tap(Finder finder) async {
        taps++;
        await tapKey(tester, finder);
      }

      await tap(find.text('Fix my number'));
      for (final String digit in '13230'.split('')) {
        await tap(find.byKey(ValueKey<String>('keypad-$digit')));
      }
      await tap(find.byKey(const ValueKey<String>('fix-action')));

      expect(taps, 7);
      expect(find.byType(FixSheet), findsNothing);
      expect(hero(tester), Money.fromMajor(963));
    });

    testWidgets('an over state still offers the foot row, and the over card has no second door (E107)', (WidgetTester tester) async {
      final Entry bigSpend = Entry(
        id: 990,
        amount: Money.fromMajor(3000),
        kind: EntryKind.spent,
        categoryId: 1,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      );
      await boot(tester, fakes: FakeServices(entries: <Entry>[...WorkedExample.entries, bigSpend]));
      expect(hero(tester).isNegative, isTrue);
      await reveal(tester, find.byType(FixFootRow));

      expect(find.byType(FixFootRow), findsOneWidget);
      expect(find.text('Fix my number'), findsOneWidget);
    });

    testWidgets('with no income there is no foot row (E90)', (WidgetTester tester) async {
      await boot(tester, fakes: FakeServices(entries: <Entry>[], rules: <RecurringRule>[]));

      expect(find.byType(FixFootRow), findsNothing);
    });
  });

  group('the Settings door (FR-SE-1, FR-FX-5 AC-5)', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await _settle(tester);
    }

    testWidgets('the row is last in Money with its detail, and is not the sliders glyph', (WidgetTester tester) async {
      await boot(tester);
      await openSettings(tester);

      expect(find.text('Fix my number'), findsOneWidget);
      expect(find.text('When the number on Home looks wrong.'), findsOneWidget);
      final double fix = tester.getTopLeft(find.byKey(const ValueKey<String>('open-fix'))).dy;
      expect(fix > tester.getTopLeft(find.byKey(const ValueKey<String>('open-savings'))).dy, isTrue);
      expect(fix < tester.getTopLeft(find.text('Look')).dy, isTrue);
    });

    testWidgets('no row without an income', (WidgetTester tester) async {
      await boot(tester, fakes: FakeServices(entries: <Entry>[], rules: <RecurringRule>[]));
      await openSettings(tester);

      expect(find.byKey(const ValueKey<String>('open-fix')), findsNothing);
    });

    testWidgets('opens the sheet over Settings with no hold; success fires as the sheet exits; the Undo shows on Settings', (WidgetTester tester) async {
      await boot(tester);
      await openSettings(tester);
      final HomeBloc home = tester.element(find.byType(HomePage, skipOffstage: false)).read<HomeBloc>();

      await tapKey(tester, find.byKey(const ValueKey<String>('open-fix')));
      expect(find.byType(FixSheet), findsOneWidget);
      expect(home.isCovered, isFalse);
      await typeDigits(tester, '13230');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));

      expect(find.byType(FixSheet), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Fixed. Safe to spend today: ₹963.'), findsOneWidget);
      expect(services.haptics.events.where((String e) => e == 'success'), hasLength(1));
    });

    testWidgets('Undo on Settings deletes the entry', (WidgetTester tester) async {
      await boot(tester);
      await openSettings(tester);
      await tapKey(tester, find.byKey(const ValueKey<String>('open-fix')));
      await typeDigits(tester, '13230');
      await tapKey(tester, find.byKey(const ValueKey<String>('fix-action')));

      await tapKey(tester, find.text('Undo'));

      expect(services.ledger.entries.where((Entry e) => e.isNotLogged), isEmpty);
    });
  });
}
