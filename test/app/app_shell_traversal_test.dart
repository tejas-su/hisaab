import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/app/app_shell.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// In two panes Tab walks one pane and then the other, never alternating between them
/// (SPEC FR-KS-1 AC-7, P17).
void main() {
  late List<FocusNode> nodes;

  setUp(() {
    nodes = <FocusNode>[
      for (final String label in <String>['home 1', 'home 2', 'spends 1', 'spends 2']) FocusNode(debugLabel: label),
    ];
  });

  tearDown(() {
    for (final FocusNode node in nodes) {
      node.dispose();
    }
  });

  Widget pane(FocusNode first, FocusNode second) => Column(
        children: <Widget>[
          TextButton(focusNode: first, onPressed: () {}, child: Text(first.debugLabel!)),
          TextButton(focusNode: second, onPressed: () {}, child: Text(second.debugLabel!)),
        ],
      );

  Future<List<String?>> tabThrough(WidgetTester tester, int presses) async {
    final List<String?> order = <String?>[];
    for (int i = 0; i < presses; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      order.add(FocusManager.instance.primaryFocus?.debugLabel);
    }
    return order;
  }

  group('AppShell focus order in two panes', () {
    testWidgets('Tab finishes Home, then Add, then Spends, instead of alternating by row', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: AppShell(home: pane(nodes[0], nodes[1]), spends: pane(nodes[2], nodes[3]), onAdd: () {})),
        size: TestWindows.tablet,
      );

      final List<String?> order = await tabThrough(tester, 5);

      expect(order.take(2), <String?>['home 1', 'home 2']);
      expect(order.skip(3), <String?>['spends 1', 'spends 2']);
    });

    testWidgets('each pane is its own traversal group', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: AppShell(home: pane(nodes[0], nodes[1]), spends: pane(nodes[2], nodes[3]), onAdd: () {})),
        size: TestWindows.tablet,
      );

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(2));
    });
  });
}
