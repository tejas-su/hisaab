import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/month_story_card.dart';
import 'package:hisaab/spends/presentation/widgets/month_story_row.dart';
import 'package:hisaab/spends/presentation/widgets/pace_card.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late SpendsBloc bloc;
  late List<int> opened;

  setUp(() {
    services = FakeServices();
    services.ledger.entries
      ..clear()
      ..addAll(<Entry>[...SeptemberStory.augustEntries(), ...SeptemberStory.septemberEntries()]);
    services.clock.current = DateTime(2026, 10, 5, 10);
    bloc = services.spendsBloc();
    opened = <int>[];
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  void spendInOctober() => services.ledger.entries.add(
        Entry(
          id: 800,
          amount: Money.fromMajor(300),
          kind: EntryKind.spent,
          categoryId: SeedCategoryIds.food,
          date: SeptemberStory.today,
          createdAt: DateTime(2026, 10, 5, 9),
        ),
      );

  Future<void> pump(WidgetTester tester, {int cyclesBack = 0, bool withStory = true}) async {
    await tester.runAsync(() async {
      await bloc.dispatch(const SpendsLoadRequested());
      for (int i = 0; i < cyclesBack; i++) {
        await bloc.dispatch(const SpendsEarlierPressed());
      }
    });
    await pumpApp(
      tester,
      BlocProvider<SpendsBloc>.value(
        value: bloc,
        child: Scaffold(
          body: SpendsPage(
            today: SeptemberStory.today,
            onSeeEntries: (PayCycle _, Option<int> _) {},
            onAskAi: (PayCycle _) {},
            onOpenStory: withStory ? opened.add : null,
          ),
        ),
      ),
    );
  }

  group('SpendsPage: the month story doors (FR-SP-7)', () {
    testWidgets('a finished September has the story card directly below Ask AI (AC-1)', (WidgetTester tester) async {
      await pump(tester, cyclesBack: 1);
      final Rect ask = tester.getRect(find.byKey(const ValueKey<String>('ask-ai-card')));
      final Rect card = tester.getRect(find.byType(MonthStoryCard));
      final Rect pace = tester.getRect(find.byType(PaceCard));
      expect(card.top, greaterThan(ask.bottom));
      expect(pace.top, greaterThan(card.bottom));
      await tester.tap(find.byType(MonthStoryCard));
      expect(opened, <int>[1]);
    });

    testWidgets('day 2 of October shows the slim row below Ask AI (AC-2)', (WidgetTester tester) async {
      spendInOctober();
      await pump(tester);
      final Rect ask = tester.getRect(find.byKey(const ValueKey<String>('ask-ai-card')));
      expect(tester.getRect(find.byType(MonthStoryRow)).top, greaterThan(ask.bottom));
      expect(find.text('See your month'), findsNothing);
      expect(find.textContaining('September is done.', findRichText: true), findsOneWidget);
      await tester.tap(find.byType(MonthStoryRow));
      expect(opened, <int>[1]);
      expect(find.byType(MonthStoryCard), findsNothing);
    });

    testWidgets('an empty October still shows the slim row, under its sentence', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('Nothing spent in October yet.'), findsOneWidget);
      expect(find.byType(MonthStoryRow), findsOneWidget);
    });

    testWidgets('without onOpenStory there is no way in', (WidgetTester tester) async {
      await pump(tester, cyclesBack: 1, withStory: false);
      expect(find.byType(MonthStoryCard), findsNothing);
    });

    testWidgets('August with 10 entries has a card too, without page 5', (WidgetTester tester) async {
      services.ledger.entries.addAll(<Entry>[
        for (int i = 0; i < 3; i++)
          Entry(
            id: 700 + i,
            amount: Money.fromMajor(100),
            kind: EntryKind.got,
            categoryId: SeedCategoryIds.otherIncome,
            date: SeptemberStory.august.start.addDays(10 + i),
            createdAt: DateTime(2026, 8, 14 + i),
          ),
      ]);
      await pump(tester, cyclesBack: 2);
      expect(find.byType(MonthStoryCard), findsOneWidget);
    });
  });
}
