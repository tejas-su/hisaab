import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/missed_log_probe.dart';
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

  setUp(() async {
    services = FakeServices();
    home = services.homeBloc();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 15, 30));
    lines = HomeLinesBloc(markAsked: MarkMissedLogAsked(states: services.states, clock: clock), clock: clock, haptics: services.haptics);
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
  });

  tearDown(() async {
    await home.close();
    await lines.close();
    await services.dispose();
  });

  Widget providers(Widget child) => MultiBlocProvider(
        providers: <BlocProvider<Object?>>[
          BlocProvider<HomeBloc>.value(value: home),
          BlocProvider<HomeLinesBloc>.value(value: lines),
        ],
        child: child,
      );

  Widget probe({bool tickers = true}) =>
      providers(Scaffold(body: TickerMode(enabled: tickers, child: const MissedLogProbe(child: Text('line')))));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  int askedWrites() => services.states.calls.where((String call) => call.startsWith('asked')).length;

  group('MissedLogProbe (FR-HO-3 AC-4)', () {
    testWidgets('reports once, after the first frame, when Home is in view and uncovered', (WidgetTester tester) async {
      await pumpApp(tester, probe());
      await settle(tester);

      expect(lines.state.asked, isTrue);
      expect(askedWrites(), 1);
      await pumpApp(tester, probe());
      await settle(tester);
      expect(askedWrites(), 1);
    });

    testWidgets('does not report while a tray or sheet holds Home, nor after it closes', (WidgetTester tester) async {
      await tester.runAsync(() => home.dispatch(const HomeTrayOpened()));

      await pumpApp(tester, probe());
      await settle(tester);

      expect(lines.state.asked, isFalse);
      await tester.runAsync(() => home.dispatch(const HomeTrayClosed()));
      await settle(tester);
      expect(lines.state.asked, isFalse);
    });

    testWidgets('does not report when Home is not the destination in view (tickers off)', (WidgetTester tester) async {
      await pumpApp(tester, probe(tickers: false));
      await settle(tester);

      expect(lines.state.asked, isFalse);
    });

    testWidgets('does not report while another route is over Home', (WidgetTester tester) async {
      await pumpApp(
        tester,
        providers(
          Navigator(
            pages: const <Page<void>>[
              MaterialPage<void>(child: Scaffold(body: MissedLogProbe(child: Text('line')))),
              MaterialPage<void>(child: Scaffold(body: Text('over'))),
            ],
            onDidRemovePage: (Page<Object?> _) {},
          ),
        ),
      );
      await settle(tester);

      expect(lines.state.asked, isFalse);
    });
  });
}
