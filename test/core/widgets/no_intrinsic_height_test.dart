import 'package:expense_tracker/core/widgets/no_intrinsic_height.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const Key _child = ValueKey<String>('child');

Future<RenderBox> _pumpAroundTallChild(WidgetTester tester) async {
  await pumpApp(
    tester,
    const Center(
      child: SizedBox(width: 100, height: 80, child: NoIntrinsicHeight(child: SizedBox(key: _child, height: 500))),
    ),
  );
  return tester.renderObject<RenderBox>(find.byType(NoIntrinsicHeight));
}

void main() {
  group('NoIntrinsicHeight', () {
    testWidgets('reports no minimum intrinsic height, however tall its child', (WidgetTester tester) async {
      final RenderBox box = await _pumpAroundTallChild(tester);

      expect(box.getMinIntrinsicHeight(100), 0);
    });

    testWidgets('reports no maximum intrinsic height, however tall its child', (WidgetTester tester) async {
      final RenderBox box = await _pumpAroundTallChild(tester);

      expect(box.getMaxIntrinsicHeight(100), 0);
    });

    testWidgets('lays its child out in exactly the space it is given', (WidgetTester tester) async {
      await _pumpAroundTallChild(tester);

      expect(tester.getSize(find.byKey(_child)), const Size(100, 80));
    });
  });
}
