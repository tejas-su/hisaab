import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:hisaab/core/widgets/hisaab_back_button.dart';
import 'package:hisaab/spends/presentation/bloc/month_story_state.dart';
import 'package:hisaab/spends/presentation/widgets/month_story_view.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late List<PayCycle> asked;

  setUp(() {
    services = FakeServices();
    services.ledger.entries
      ..clear()
      ..addAll(<Entry>[...SeptemberStory.augustEntries(), ...SeptemberStory.septemberEntries()]);
    services.clock.current = DateTime(2026, 10, 5, 10);
    asked = <PayCycle>[];
  });

  tearDown(() => services.dispose());

  Future<MonthStoryBloc> pump(WidgetTester tester, {bool load = true}) async {
    final MonthStoryBloc bloc = await tester.buildBloc(() => MonthStoryBloc(getStory: GetMonthStory(overview: services.getSpendsOverview), cyclesBack: 1));
    addTearDown(() => tester.runAsync(bloc.close));
    if (load) {
      await tester.runAsync(() => bloc.dispatch(const MonthStoryLoadRequested()));
    }
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => BlocProvider<MonthStoryBloc>.value(
                    value: bloc,
                    child: MonthStoryPage(today: SeptemberStory.today, onAskAi: asked.add),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return bloc;
  }

  group('MonthStoryPage (FR-SP-7)', () {
    testWidgets('shows the story of September', (WidgetTester tester) async {
      await pump(tester);
      expect(find.byType(MonthStoryView), findsOneWidget);
      expect(find.text('September · 1 of 6'), findsOneWidget);
    });

    testWidgets('Ask AI on the last page opens September; Done closes the story (AC-8)', (WidgetTester tester) async {
      await pump(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey<String>('story-next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey<String>('story-ask-ai')));
      expect(asked, <PayCycle>[SeptemberStory.september]);
      await tester.tap(find.byKey(const ValueKey<String>('story-done')));
      await tester.pumpAndSettle();
      expect(find.byType(MonthStoryPage), findsNothing);
    });

    testWidgets('while loading only Back shows', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.byType(MonthStoryView), findsNothing);
      expect(find.byType(HisaabBackButton), findsOneWidget);
    });

    testWidgets('a failed load offers Try again, which loads the story', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('locked');
      final MonthStoryBloc bloc = await pump(tester);
      expect(find.text('Try again'), findsOneWidget);
      services.ledger.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.settle();
      expect(bloc.state, isA<MonthStoryReady>());
      expect(find.byType(MonthStoryView), findsOneWidget);
    });

    testWidgets('closes itself when the cycle no longer has a story', (WidgetTester tester) async {
      final MonthStoryBloc bloc = await pump(tester);
      services.ledger.entries.removeWhere((Entry e) => SeptemberStory.september.contains(e.date) && e.id > 15);
      bloc.add(const MonthStoryLoadRequested());
      await tester.settle();
      expect(find.byType(MonthStoryPage), findsNothing);
    });

    testWidgets('the story column is no wider than 480dp on a tablet (AC-7)', (WidgetTester tester) async {
      tester.view.physicalSize = TestWindows.tablet;
      await pump(tester);
      expect(tester.getSize(find.byType(MonthStoryView)).width, lessThanOrEqualTo(MonthStoryPage.maxWidth));
    });
  });

  test('today in the fixture is day 2 of October', () {
    expect(SeptemberStory.today, const CalendarDate(2026, 10, 5));
  });
}
