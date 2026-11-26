import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/domain/entities/reached_line.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/reached_line_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

final Money _target = Money.fromMajor(12000);
final RecurringRule _insurance = WorkedExample.insurance.copyWith(target: Option<Money>.of(_target));

/// The reached line in Home's nudge slot (SPEC FR-HO-3 AC-R2, AC-R5 to AC-R7; spec §16.8 T6).
void main() {
  late FakeServices services;
  late HomeBloc home;
  late HomeLinesBloc lines;

  setUp(() {
    services = FakeServices(
      entries: <Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns],
      rules: <RecurringRule>[...WorkedExample.rules, _insurance],
    );
    home = services.homeBloc(getSetAside: GetSetAside(recurring: services.recurring, ledger: services.ledger));
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 15, 30));
    lines = HomeLinesBloc(
      markAsked: MarkMissedLogAsked(states: services.states, clock: clock),
      clock: clock,
      haptics: services.haptics,
      recurring: services.recurring,
    );
  });

  tearDown(() async {
    await home.close();
    await lines.close();
    await services.dispose();
  });

  Future<void> decide({RecurringRule? saving}) async {
    await home.dispatch(const HomeLoadRequested());
    await lines.dispatch(const HomeLinesPointReached());
    await lines.dispatch(
      HomeLinesEvaluated(
        HomeLinesFacts(
          index: null,
          categories: seedCategories,
          now: DateTime(2026, 10, 26, 15, 30),
          reached: Option<ReachedLine>.of(ReachedLine(saving: saving ?? _insurance, target: _target, pending: true)),
        ),
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    List<RecurringRule> opened, {
    Size size = TestWindows.phone,
    double textScale = 1,
    bool reduceMotion = false,
  }) =>
      pumpApp(
        tester,
        MultiBlocProvider(
          providers: <BlocProvider<Object?>>[
            BlocProvider<HomeBloc>.value(value: home),
            BlocProvider<HomeLinesBloc>.value(value: lines),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: <Widget>[ReachedLineSlot(onOpenBill: opened.add), const Text('Today')]),
            ),
          ),
        ),
        size: size,
        textScale: textScale,
        reduceMotion: reduceMotion,
      );

  Finder line() => find.byType(ReachedLineRow);

  group('ReachedLineSlot (FR-HO-3)', () {
    testWidgets('is empty and takes no height when there is no line', (WidgetTester tester) async {
      await pump(tester, <RecurringRule>[]);

      expect(line(), findsNothing);
      expect(tester.getRect(find.byType(ReachedLineSlot)).height, 0);
    });

    testWidgets('reads "{name} reached {target}." with no other amount (AC-R6)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <RecurringRule>[]);

      expect(find.text('Insurance reached ₹12,000.'), findsOneWidget);
      expect(find.textContaining('₹1,000'), findsNothing);
    });

    testWidgets('TalkBack reads one button with the spoken target and "Opens the saving.", not a live region (AC-R7)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.runAsync(decide);
      await pump(tester, <RecurringRule>[]);

      final SemanticsNode node = tester.getSemantics(line());
      expect(node.label, 'Insurance reached 12,000 rupees.');
      expect(node.hint, 'Opens the saving.');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isLiveRegion, isFalse);
      handle.dispose();
    });

    testWidgets('is at least 56dp tall, sunk, with no marigold (AC-R6, AC-T12)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <RecurringRule>[]);

      expect(tester.getSize(line()).height, greaterThanOrEqualTo(56));
      expect(tester.getSize(line()).width, greaterThan(0));
    });

    testWidgets('a tap ticks and opens that saving, and the line stays; a second tap opens it again (AC-R5)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      final List<RecurringRule> opened = <RecurringRule>[];
      await pump(tester, opened);

      await tester.tap(line());
      await tester.settle();
      await tester.tap(line());
      await tester.settle();

      expect(opened.map((RecurringRule r) => r.id), <int>[5, 5]);
      expect(services.haptics.events.where((String e) => e == 'tick'), hasLength(2));
      expect(line(), findsOneWidget);
    });

    testWidgets('on screen with nothing over Home it is written as shown (AC-R2)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <RecurringRule>[]);
      await tester.settle();

      final RecurringRule written = services.recurring.updates.single;
      expect(written.targetReachedFor, Option<Money>.of(_target));
      expect(written.targetReachedOn, const Option<CalendarDate>.of(CalendarDate(2026, 10, 26)));
    });

    testWidgets('a line drawn under a covering tray is not written (AC-R2)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await tester.runAsync(() => home.dispatch(const HomeTrayOpened()));
      await pump(tester, <RecurringRule>[]);
      await tester.settle();

      expect(services.recurring.updates, isEmpty);
      expect(lines.state.reachedMarked, isFalse);
    });

    testWidgets('reads the saving\'s current name from Home, so a rename shows at the next build (A8)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      services.recurring.rules = <RecurringRule>[...WorkedExample.rules, _insurance.copyWith(label: 'Car insurance')];
      await tester.runAsync(() => home.dispatch(const HomeLoadRequested()));
      final List<RecurringRule> opened = <RecurringRule>[];
      await pump(tester, opened);

      expect(find.text('Car insurance reached ₹12,000.'), findsOneWidget);
      await tester.tap(line());
      await tester.settle();
      expect(opened.single.label, 'Car insurance');
    });

    for (final double scale in <double>[1.5, 2.0]) {
      testWidgets('a long name wraps on a small phone at $scale x text, never cut and never overflowing', (WidgetTester tester) async {
        final RecurringRule long = _insurance.copyWith(label: 'School fees for the younger one');
        services.recurring.rules = <RecurringRule>[...WorkedExample.rules, long];
        await tester.runAsync(() => decide(saving: long));
        await pump(tester, <RecurringRule>[], size: TestWindows.smallPhone, textScale: scale);

        expect(tester.takeException(), isNull);
        final Text sentence = tester.widget<Text>(find.text('School fees for the younger one reached ₹12,000.'));
        expect(sentence.overflow, isNot(TextOverflow.ellipsis));
        expect(sentence.maxLines, isNull);
        expect(tester.getSize(line()).height, greaterThan(56));
      });
    }

    testWidgets('collapses over the resize token when the line goes', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <RecurringRule>[]);
      final double withLine = tester.getTopLeft(find.text('Today')).dy;

      await tester.runAsync(() => lines.dispatch(const HomeLinesMidnight()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final double midway = tester.getTopLeft(find.text('Today')).dy;
      await tester.pumpAndSettle();

      expect(midway, lessThan(withLine));
      expect(midway, greaterThan(tester.getTopLeft(find.text('Today')).dy));
      expect(line(), findsNothing);
    });

    testWidgets('with reduced motion the line fades over 150 ms and the height goes at once', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <RecurringRule>[], reduceMotion: true);

      await tester.runAsync(() => lines.dispatch(const HomeLinesMidnight()));
      await tester.pump();
      expect(line(), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 160));

      expect(line(), findsNothing);
    });
  });
}
