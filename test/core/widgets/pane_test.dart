import 'package:hisaab/core/widgets/pane.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pane', () {
    Future<EdgeInsets> insetsSeenBy(WidgetTester tester, {bool insetTop = true}) async {
      EdgeInsets seen = EdgeInsets.zero;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800), padding: EdgeInsets.only(top: 24, bottom: 16)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: <Widget>[
                Pane(
                  rect: const Rect.fromLTWH(0, 0, 400, 800),
                  windowSize: const Size(400, 800),
                  insetTop: insetTop,
                  child: Builder(
                    builder: (BuildContext context) {
                      seen = MediaQuery.paddingOf(context);
                      return const SizedBox.expand(key: ValueKey<String>('child'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return seen;
    }

    final Finder child = find.byKey(const ValueKey<String>('child'));

    testWidgets('keeps its child clear of the status and gesture bars by default', (WidgetTester tester) async {
      expect(await insetsSeenBy(tester), EdgeInsets.zero);
      expect(tester.getRect(child), const Rect.fromLTRB(0, 24, 400, 784));
    });

    testWidgets('without insetTop the child reaches the top and reads the inset itself', (WidgetTester tester) async {
      expect((await insetsSeenBy(tester, insetTop: false)).top, 24);
      expect(tester.getTopLeft(child).dy, 0);
    });
  });
}
