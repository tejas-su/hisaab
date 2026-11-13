import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

Entry _used({String? note = 'Insurance'}) => Entry(
      id: 900,
      amount: Money.fromMajor(4000),
      kind: EntryKind.used,
      categoryId: SeedCategoryIds.saved,
      date: WorkedExample.today,
      createdAt: WorkedExample.now,
      note: note,
      savingId: 5,
    );

void main() {
  late List<String> calls;

  setUp(() => calls = <String>[]);

  Future<void> pumpRow(WidgetTester tester, {Entry? entry, bool showUsedDetail = false, double textScale = 1}) => pumpApp(
        tester,
        Scaffold(
          body: EntryRow(
            entry: entry ?? _used(),
            category: null,
            showUsedDetail: showUsedDetail,
            onEdit: () => calls.add('edit'),
            onDelete: () => calls.add('delete'),
            onThresholdReached: () {},
          ),
        ),
        textScale: textScale,
      );

  group('EntryRow for a Used entry (FR-HO-4, FR-SP-6, D187, NFR-11)', () {
    testWidgets("reads the saving's name over \"Used from savings\", the amount at the end, the saving glyph", (WidgetTester tester) async {
      await pumpRow(tester);

      expect(find.text('Insurance'), findsOneWidget);
      expect(find.text('Used from savings'), findsOneWidget);
      expect(find.text('₹4,000'), findsOneWidget);
      expect(tester.widget<AppIcon>(find.byType(AppIcon).first).icon, AppIcons.saving);
      expect(tester.getTopRight(find.text('₹4,000')).dx, greaterThan(tester.getTopLeft(find.text('Insurance')).dx));
    });

    testWidgets('it has no tap and no sign', (WidgetTester tester) async {
      await pumpRow(tester);

      await tester.tap(find.text('Insurance'));

      expect(calls, isEmpty);
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
      expect(find.textContaining('+'), findsNothing);
      expect(find.textContaining('-'), findsNothing);
    });

    testWidgets('Today has no extra line', (WidgetTester tester) async {
      await pumpRow(tester);

      expect(find.text('Paid from what you set aside.'), findsNothing);
    });

    testWidgets('Every entry adds "Paid from what you set aside."', (WidgetTester tester) async {
      await pumpRow(tester, showUsedDetail: true);

      expect(find.text('Paid from what you set aside.'), findsOneWidget);
    });

    testWidgets('TalkBack reads "Insurance. Used from savings 4,000 rupees."', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpRow(tester);

      expect(find.bySemanticsLabel('Insurance. Used from savings 4,000 rupees.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('in Every entry the extra line is in the same screen-reader node', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpRow(tester, showUsedDetail: true);

      expect(
        find.bySemanticsLabel('Insurance. Used from savings 4,000 rupees., Paid from what you set aside.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Delete is a custom semantics action on the row (NFR-11)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpRow(tester);

      final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel(RegExp('Insurance. Used from savings')));
      final List<String> labels = (node.getSemanticsData().customSemanticsActionIds ?? <int>[])
          .map((int id) => CustomSemanticsAction.getAction(id)?.label ?? '')
          .toList();

      expect(labels, contains('Delete'));
      handle.dispose();
    });

    testWidgets('swiping away deletes it', (WidgetTester tester) async {
      await pumpRow(tester);

      await tester.drag(find.text('Insurance'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(calls, <String>['delete']);
    });

    testWidgets('a Used entry with no note falls back to "Saving"', (WidgetTester tester) async {
      await pumpRow(tester, entry: _used(note: null));

      expect(find.text('Saving'), findsOneWidget);
    });

    testWidgets('lays out at 2.0x text without overflow', (WidgetTester tester) async {
      await pumpRow(tester, showUsedDetail: true, textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });
}
