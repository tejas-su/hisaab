import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ShapeDecoration _decoration(WidgetTester tester) => tester
    .widget<AnimatedContainer>(find.descendant(of: find.byType(SignalKey), matching: find.byType(AnimatedContainer)))
    .decoration! as ShapeDecoration;

void main() {
  group('SignalKey', () {
    testWidgets('is marigold with an ink lip, and the lip collapses while pressed', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, Scaffold(body: Center(child: SignalKey(label: 'Next', icon: AppIcons.next, onPressed: () => taps++))));
      expect(_decoration(tester).color, HisaabColors.light.signal);
      expect(_decoration(tester).shadows, isNotEmpty);
      final TestGesture press = await tester.startGesture(tester.getCenter(find.byType(SignalKey)));
      await tester.pumpAndSettle();
      expect(_decoration(tester).shadows, isEmpty);
      await press.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('disabled, it turns grey and cannot act', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Scaffold(body: Center(child: SignalKey(label: 'Next', onPressed: null))));
      expect(_decoration(tester).color, HisaabColors.light.sunk);
      expect(tester.getSemantics(find.byType(SignalKey)), matchesSemantics(label: 'Next', isButton: true, hasEnabledState: true));
      handle.dispose();
    });

    testWidgets('reduced motion still works', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: Center(child: SignalKey(label: 'Add', onPressed: () {}))), reduceMotion: true);
      await tester.tap(find.byType(SignalKey));
      expect(tester.takeException(), isNull);
    });
  });
}
