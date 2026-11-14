import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/pump_app.dart';

/// A *Not logged* row (SPEC BR-18, FR-HO-4, FR-SP-6, D187, NFR-11): its title, its direction as a word,
/// no tap, no sign, and Delete without a swipe.
void main() {
  const CalendarDate day = CalendarDate(2026, 10, 26);

  Widget row(Entry entry, {int deletes = 0, List<int>? deleted, bool detail = false}) => Scaffold(
        body: EntryRow(
          entry: entry,
          category: null,
          showNotLoggedDetail: detail,
          onEdit: () => fail('a Not logged row is never edited in the tray'),
          onDelete: () => deleted?.add(entry.id),
          onThresholdReached: () {},
        ),
      );

  group('EntryRow for a Not logged entry', () {
    testWidgets('a Spent fix: "Not logged", "Spent", the amount at the end, no sign', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day)));

      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('₹4,200'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('a Got fix says "Got" and shows the amount plain, with no sign or tint', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(1000, day, got: true)));

      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('Got'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('its title never falls back to "Other" when the category map lacks the hidden row', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day)));

      expect(find.text('Other'), findsNothing);
    });

    testWidgets('it uses the neutral glyph', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day)));

      expect(find.byWidgetPredicate((Widget w) => w is AppIcon && w.icon == AppIcons.notLogged), findsOneWidget);
    });

    testWidgets('it has no tap: the row is never opened in the Add tray', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day)));

      await tester.tap(find.text('Not logged'));
      await tester.pump();

      expect(tester.widget<InkWell>(find.descendant(of: find.byType(EntryRow), matching: find.byType(InkWell))).onTap, isNull);
    });

    testWidgets('Every entry adds "Added when you fixed your number." as a line', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day), detail: true));

      expect(find.text('Added when you fixed your number.'), findsOneWidget);
    });

    testWidgets('Home\'s row has no extra line', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day)));

      expect(find.text('Added when you fixed your number.'), findsNothing);
    });
  });

  group('EntryRow for a Not logged entry: TalkBack', () {
    testWidgets('reads "Not logged. Spent 4,200 rupees." and "Not logged. Got 1,000 rupees."', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, row(notLogged(4200, day)));
      expect(find.bySemanticsLabel('Not logged. Spent 4,200 rupees.'), findsOneWidget);

      await pumpApp(tester, row(notLogged(1000, day, got: true)));
      expect(find.bySemanticsLabel('Not logged. Got 1,000 rupees.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Every entry adds the detail in the same node', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, row(notLogged(4200, day), detail: true));

      expect(find.bySemanticsLabel(RegExp(r'Not logged\. Spent 4,200 rupees\..*Added when you fixed your number\.')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Delete is a custom action on the row, so it needs no swipe (NFR-11, P12)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<int> deleted = <int>[];
      await pumpApp(tester, row(notLogged(4200, day), deleted: deleted));

      final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel('Not logged. Spent 4,200 rupees.'));
      final List<CustomSemanticsAction> actions = <CustomSemanticsAction>[
        for (final int id in node.getSemanticsData().customSemanticsActionIds ?? const <int>[]) ?CustomSemanticsAction.getAction(id),
      ];
      expect(actions.map((CustomSemanticsAction a) => a.label), contains('Delete'));
      final CustomSemanticsAction delete = actions.firstWhere((CustomSemanticsAction a) => a.label == 'Delete');

      tester.semantics.performAction(find.semantics.byLabel(RegExp('Not logged. Spent 4,200 rupees')), SemanticsAction.customAction, args: CustomSemanticsAction.getIdentifier(delete));

      expect(deleted, <int>[800]);
      handle.dispose();
    });

    testWidgets('a Not logged row is 48dp or more tall', (WidgetTester tester) async {
      await pumpApp(tester, row(notLogged(4200, day)));

      expect(tester.getSize(find.byType(EntryRow)).height >= 48, isTrue);
    });
  });
}
