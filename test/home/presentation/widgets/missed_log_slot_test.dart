import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/missed_log_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

final UsualHabit _foodHabit = UsualHabit(
  categoryId: 1,
  dayType: DayType.weekday,
  pooled: false,
  window: const TimeWindow(startMinute: 735, lengthMinutes: 105),
  amount: Money.fromMajor(55),
  hitDays: 18,
  activeDays: 20,
  lastHit: DateTime(2026, 10, 23, 13),
  fading: false,
);

void main() {
  late FakeServices services;
  late HomeBloc home;
  late HomeLinesBloc lines;

  setUp(() {
    services = FakeServices();
    home = services.homeBloc();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 15, 30));
    lines = HomeLinesBloc(markAsked: MarkMissedLogAsked(states: services.states, clock: clock), clock: clock, haptics: services.haptics);
  });

  tearDown(() async {
    await home.close();
    await lines.close();
    await services.dispose();
  });

  Future<void> decide() async {
    await lines.dispatch(const HomeLinesPointReached());
    await lines.dispatch(
      HomeLinesEvaluated(
        HomeLinesFacts(
          index: HabitIndex(
            builtOn: WorkedExample.today,
            habits: <UsualHabit>[_foodHabit],
            loggedToday: const <int>{},
            states: const <int, SuggestionState>{},
          ),
          categories: seedCategories,
          now: DateTime(2026, 10, 26, 15, 30),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, List<MissedLog> opened, {bool reduceMotion = false}) => pumpApp(
        tester,
        MultiBlocProvider(
          providers: <BlocProvider<Object?>>[
            BlocProvider<HomeBloc>.value(value: home),
            BlocProvider<HomeLinesBloc>.value(value: lines),
          ],
          child: Scaffold(body: Column(children: <Widget>[MissedLogSlot(onTap: opened.add), const Text('Today')])),
        ),
        reduceMotion: reduceMotion,
      );

  group('MissedLogSlot (FR-HO-3)', () {
    testWidgets('is empty and takes no height when there is no line', (WidgetTester tester) async {
      await pump(tester, <MissedLog>[]);

      expect(find.byType(MissedLogRow), findsNothing);
      expect(tester.getRect(find.byType(MissedLogSlot)).height, 0);
    });

    testWidgets('shows the line; a tap sends the tap once and calls onTap, and a second tap is ignored (AC-2)', (WidgetTester tester) async {
      await tester.runAsync(decide);
      final List<MissedLog> opened = <MissedLog>[];
      await pump(tester, opened);

      await tester.tap(find.byType(MissedLogRow));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.tap(find.byType(MissedLogRow));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(lines.state.tapped, isTrue);
      expect(services.haptics.events.where((String event) => event == 'tick'), hasLength(1));
    });

    testWidgets('collapses over the resize token when the line goes', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <MissedLog>[]);
      final double withLine = tester.getTopLeft(find.text('Today')).dy;

      await tester.runAsync(() => lines.dispatch(const HomeLinesMidnight()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final double midway = tester.getTopLeft(find.text('Today')).dy;
      await tester.pumpAndSettle();
      final double without = tester.getTopLeft(find.text('Today')).dy;

      expect(midway, lessThan(withLine));
      expect(midway, greaterThan(without));
      expect(find.byType(MissedLogRow), findsNothing);
    });

    testWidgets('with reduced motion the line fades over 150 ms and the height goes at once', (WidgetTester tester) async {
      await tester.runAsync(decide);
      await pump(tester, <MissedLog>[], reduceMotion: true);

      await tester.runAsync(() => lines.dispatch(const HomeLinesMidnight()));
      await tester.pump();
      expect(find.byType(MissedLogRow), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 160));

      expect(find.byType(MissedLogRow), findsNothing);
    });
  });
}
