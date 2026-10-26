import 'package:expense_tracker/add_entry/presentation/widgets/kind_switch.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Future<void> _pump(WidgetTester tester, {ThemeMode themeMode = ThemeMode.light, ValueChanged<EntryKind>? onChanged}) =>
    pumpApp(
      tester,
      Scaffold(body: Center(child: KindSwitch(kind: EntryKind.spent, onChanged: onChanged ?? (EntryKind _) {}))),
      themeMode: themeMode,
    );

Color? _fill(WidgetTester tester, EntryKind kind) {
  final Container segment = tester.widget<Container>(
    find.descendant(of: find.byKey(ValueKey<String>('kind-${kind.name}')), matching: find.byType(Container)).first,
  );
  return (segment.decoration! as ShapeDecoration).color;
}

Color? _textColor(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style?.color;

void main() {
  group('KindSwitch', () {
    testWidgets('light: the selected segment is a raised surface pill with ink text (UI_DESIGN §3.5)', (WidgetTester tester) async {
      await _pump(tester);
      expect(_fill(tester, EntryKind.spent), HisaabColors.light.surface);
      expect(_textColor(tester, 'Spent'), HisaabColors.light.ink);
    });

    testWidgets('dark: the selected segment stays an ink pill', (WidgetTester tester) async {
      await _pump(tester, themeMode: ThemeMode.dark);
      expect(_fill(tester, EntryKind.spent), HisaabColors.dark.ink);
      expect(_textColor(tester, 'Spent'), HisaabColors.dark.background);
    });

    testWidgets('the unselected segment is unfilled with ink2 text', (WidgetTester tester) async {
      await _pump(tester);
      expect(_fill(tester, EntryKind.got), isNull);
      expect(_textColor(tester, 'Got'), HisaabColors.light.ink2);
    });

    testWidgets('tapping Got reports it', (WidgetTester tester) async {
      final List<EntryKind> changes = <EntryKind>[];
      await _pump(tester, onChanged: changes.add);
      await tester.tap(find.byKey(const ValueKey<String>('kind-got')));
      expect(changes, <EntryKind>[EntryKind.got]);
    });
  });
}
