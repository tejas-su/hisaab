import 'package:hisaab/core/widgets/pinned_keypad_body.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PinnedKeypadBody (P2, P3)', () {
    const Key lead = ValueKey<String>('lead');
    const Key figure = ValueKey<String>('figure');
    const Key action = ValueKey<String>('action');

    Widget body({double leadHeight = 40}) => PinnedKeypadBody(
          lead: SizedBox(key: lead, height: leadHeight),
          figure: const SizedBox(key: figure, height: 60),
          controls: (BuildContext _, double keyHeight) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[SizedBox(key: const ValueKey<String>('keys'), height: keyHeight * 4 + 24), const SizedBox(key: action, height: 58)],
          ),
        );

    testWidgets('stacked in a tall window: lead, figure, controls in order, 56dp keys', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: Align(alignment: Alignment.bottomCenter, child: body())));
      expect(tester.getBottomLeft(find.byKey(lead)).dy, lessThanOrEqualTo(tester.getTopLeft(find.byKey(figure)).dy));
      expect(tester.getBottomLeft(find.byKey(figure)).dy, lessThanOrEqualTo(tester.getTopLeft(find.byKey(const ValueKey<String>('keys'))).dy));
      expect(tester.getSize(find.byKey(const ValueKey<String>('keys'))).height, 56 * 4 + 24);
    });

    testWidgets('the lead scrolls while the figure and controls stay', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: Align(alignment: Alignment.bottomCenter, child: body(leadHeight: 600))), size: TestWindows.smallPhone);
      final Rect before = tester.getRect(find.byKey(action));
      await tester.drag(find.byKey(lead), const Offset(0, -100));
      await tester.pump();
      expect(tester.getRect(find.byKey(action)), before);
      expect(before.bottom, lessThanOrEqualTo(TestWindows.smallPhone.height));
    });

    testWidgets('in a short, wide window it goes side by side with 48dp keys', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: body()), size: TestWindows.splitScreen);
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('keys'))).dx, greaterThan(tester.getTopLeft(find.byKey(figure)).dx));
      expect(tester.getSize(find.byKey(const ValueKey<String>('keys'))).height, 48 * 4 + 24);
    });

    testWidgets('with no height bound it lays out at its natural size', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: SingleChildScrollView(child: body())));
      expect(tester.takeException(), isNull);
      expect(find.byKey(action), findsOneWidget);
    });

    testWidgets('when nothing fits (320dp wide, 2x text) everything scrolls, so the keys stay reachable', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: Align(alignment: Alignment.bottomCenter, child: body())),
        size: const Size(320, 400),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byKey(action), 100, scrollable: find.byType(Scrollable).first);
      expect(tester.getRect(find.byKey(action)).bottom, lessThanOrEqualTo(400));
    });
  });
}
