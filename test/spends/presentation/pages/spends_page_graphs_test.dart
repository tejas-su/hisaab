import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/months_strip_card.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late SpendsBloc bloc;
  late List<(PayCycle, Option<int>)> opened;

  setUp(() {
    services = FakeServices();
    services.ledger.entries
      ..clear()
      ..addAll(<Entry>[
        ...SeptemberStory.augustEntries(),
        ...SeptemberStory.septemberEntries(),
        ...WorkedExample.entries,
        Entry(
          id: 900,
          amount: Money.fromMajor(1000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 5),
          createdAt: DateTime(2026, 10, 5),
        ),
      ]);
    bloc = services.spendsBloc();
    opened = <(PayCycle, Option<int>)>[];
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() => bloc.dispatch(const SpendsLoadRequested()));
    await pumpApp(
      tester,
      BlocProvider<SpendsBloc>.value(
        value: bloc,
        child: Scaffold(
          body: SpendsPage(
            today: WorkedExample.today,
            onSeeEntries: (PayCycle cycle, Option<int> category) => opened.add((cycle, category)),
            onAskAi: (PayCycle _) {},
          ),
        ),
      ),
    );
  }

  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> tapOnScreen(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: scrollable());
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('SpendsPage: the graphs (BR-21, D195)', () {
    testWidgets('the pace card says the comparison; the split card says what is not spent yet', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('₹4,760 less than by this day in September.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('₹16,430 not spent yet'), 200, scrollable: scrollable());
      expect(find.text('Money in ₹45,000'), findsOneWidget);
    });

    testWidgets('an opened row\'s See entries opens that category', (WidgetTester tester) async {
      services.ledger.entries.addAll(<Entry>[
        for (int day = 6; day < 9; day++)
          Entry(
            id: 950 + day,
            amount: Money.fromMajor(100),
            kind: EntryKind.spent,
            categoryId: SeedCategoryIds.food,
            date: CalendarDate(2026, 10, day),
            createdAt: DateTime(2026, 10, day),
          ),
      ]);
      await pump(tester);
      await tapOnScreen(tester, find.text('Food'));
      await tapOnScreen(tester, find.byKey(const ValueKey<String>('see-category-entries')));
      expect(opened.single.$2, const Option<int>.of(SeedCategoryIds.food));
    });

    testWidgets('the strip is the last card, and Open shows the picked cycle (FR-SP-8)', (WidgetTester tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(find.byType(MonthsStripCard), 300, scrollable: scrollable());
      await tapOnScreen(tester, find.byKey(const ValueKey<String>('strip-open')));
      await tester.settle();
      expect((bloc.state as SpendsReady).overview.cyclesBack, 1);
    });
  });
}
