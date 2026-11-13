import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/home/presentation/widgets/today_list.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

Entry _used(int id, {int hour = 11}) => Entry(
      id: id,
      amount: Money.fromMajor(4000),
      kind: EntryKind.used,
      categoryId: SeedCategoryIds.saved,
      date: WorkedExample.today,
      createdAt: DateTime(2026, 10, 26, hour),
      note: 'Insurance',
      savingId: 5,
    );

void main() {
  Future<void> pumpList(WidgetTester tester, List<Entry> entries, {Money spentToday = const Money(42000)}) => pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: TodayList(
              entries: entries,
              categories: <int, Category>{for (final Category c in seedCategories) c.id: c},
              spentToday: spentToday,
              onEdit: (Entry _) {},
              onDelete: (Entry _) {},
              onThresholdReached: () {},
            ),
          ),
        ),
      );

  group('TodayList with a Used entry (FR-HO-4, BR-19)', () {
    testWidgets("a used row reads the saving's name over \"Used from savings\"", (WidgetTester tester) async {
      await pumpList(tester, <Entry>[_used(900), ...WorkedExample.entries.reversed.take(3)]);

      expect(find.text('Insurance'), findsOneWidget);
      expect(find.text('Used from savings'), findsOneWidget);
      expect(find.text('Paid from what you set aside.'), findsNothing);
    });

    testWidgets('the header total is the one the caller passes: a used row adds nothing to it', (WidgetTester tester) async {
      await pumpList(tester, <Entry>[_used(900), ...WorkedExample.entries.reversed.take(3)]);

      expect(find.text('₹420'), findsOneWidget);
      expect(find.text('₹4,420'), findsNothing);
    });

    testWidgets('a used row counts among the rows and sits in the order it was given', (WidgetTester tester) async {
      await pumpList(tester, <Entry>[_used(900), ...WorkedExample.entries.reversed.take(4)]);

      expect(find.byType(EntryRow), findsNWidgets(5));
      expect(tester.getTopLeft(find.text('Insurance')).dy, lessThan(tester.getTopLeft(find.text('Groceries')).dy));
    });
  });
}
