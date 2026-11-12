import 'package:hisaab/core/design/hisaab_dimensions.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/widgets/top_bar_scroll_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('TopBarScrollView (D84)', () {
    Widget view({double statusBar = 0, double bottom = 0}) => Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.only(top: statusBar, bottom: bottom)),
        child: Scaffold(
          body: TopBarScrollView(
            bar: const Text('Title'),
            children: <Widget>[
              for (int index = 0; index < 30; index++)
                SizedBox(key: ValueKey<int>(index), height: 80, child: Text('Row $index')),
            ],
          ),
        ),
      ),
    );

    final Finder bar = find.byKey(const ValueKey<String>('top-bar'));

    BoxDecoration surface(WidgetTester tester) => tester.widget<DecoratedBox>(bar).decoration as BoxDecoration;

    double hairlineAlpha(WidgetTester tester) => (surface(tester).border! as Border).bottom.color.a;

    Future<void> scrollUnder(WidgetTester tester) async {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
    }

    testWidgets('the bar is solid background with no blur, and no hairline at rest (D84)', (WidgetTester tester) async {
      await pumpApp(tester, view());
      expect(find.byType(BackdropFilter), findsNothing);
      expect(surface(tester).color, HisaabColors.light.background);
      expect(hairlineAlpha(tester), 0);
    });

    testWidgets('content scrolled under it brings in the hairline; the bar stays solid', (WidgetTester tester) async {
      await pumpApp(tester, view());
      await scrollUnder(tester);
      expect(surface(tester).color, HisaabColors.light.background);
      expect((surface(tester).border! as Border).bottom.color, HisaabColors.light.hairline);
    });

    testWidgets('scrolling back to the top clears the hairline', (WidgetTester tester) async {
      await pumpApp(tester, view());
      await scrollUnder(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(hairlineAlpha(tester), 0);
    });

    testWidgets('with reduced motion the hairline still settles', (WidgetTester tester) async {
      await pumpApp(tester, view(), reduceMotion: true);
      await scrollUnder(tester);
      expect((surface(tester).border! as Border).bottom.color, HisaabColors.light.hairline);
    });

    testWidgets('reaches behind the status bar and keeps its row below it', (WidgetTester tester) async {
      await pumpApp(tester, view(statusBar: 24));
      expect(tester.getTopLeft(find.byType(CustomScrollView)).dy, 0);
      expect(tester.getTopLeft(find.text('Title')).dy, 24 + 12);
      expect(tester.getTopLeft(find.text('Title')).dx, 20);
      expect(tester.getTopLeft(find.byKey(const ValueKey<int>(0))).dy, 24 + 12 + TopBarScrollView.barHeight + 14);
    });

    final Finder fade = find.byKey(const ValueKey<String>('bottom-fade'));

    testWidgets('the list\'s bottom 32dp fades into the background, eased (D82)', (WidgetTester tester) async {
      await pumpApp(tester, view());
      expect(tester.getRect(fade), Rect.fromLTRB(0, TestWindows.phone.height - 32, TestWindows.phone.width, TestWindows.phone.height));
      final LinearGradient gradient =
          (tester.widget<DecoratedBox>(find.descendant(of: fade, matching: find.byType(DecoratedBox))).decoration as BoxDecoration).gradient!
              as LinearGradient;
      expect(gradient.colors.map((Color color) => color.a), <double>[0, 0.16, 0.5, 0.84, 1].map((double a) => closeTo(a, 0.01)));
      expect(gradient.colors.last, HisaabColors.light.background);
    });

    testWidgets('taps pass through the fade to the content behind it', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: TopBarScrollView(
            bar: const Text('Title'),
            children: <Widget>[SizedBox(height: 2000, child: GestureDetector(onTap: () => taps++, behavior: HitTestBehavior.opaque))],
          ),
        ),
      );
      await tester.tapAt(tester.getCenter(fade));
      expect(taps, 1);
    });

    testWidgets('high contrast drops the fade', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpApp(tester, view());
      expect(fade, findsNothing);
    });

    testWidgets('the last item comes to rest above the fade and the bottom inset', (WidgetTester tester) async {
      await pumpApp(tester, view(bottom: 20));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.byKey(const ValueKey<int>(29))).dy, TestWindows.phone.height - 20 - 32);
    });

    group('fill', () {
      Widget withFill({required double childHeight}) => Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(bottom: 20)),
          child: Scaffold(
            body: TopBarScrollView(
              bar: const Text('Title'),
              fill: const SizedBox.expand(key: ValueKey<String>('fill')),
              children: <Widget>[SizedBox(key: const ValueKey<String>('card'), height: childHeight)],
            ),
          ),
        ),
      );
      final Finder fill = find.byKey(const ValueKey<String>('fill'));

      testWidgets('takes the height left under the children, down to the fade and the inset', (WidgetTester tester) async {
        await pumpApp(tester, withFill(childHeight: 100));
        expect(tester.getTopLeft(fill).dy, tester.getBottomLeft(find.byKey(const ValueKey<String>('card'))).dy + HisaabSpacing.l);
        expect(tester.getBottomLeft(fill).dy, TestWindows.phone.height - 20 - 32);
        expect(tester.getTopLeft(fill).dx, 20);
        expect(tester.getTopRight(fill).dx, TestWindows.phone.width - 20);
      });

      testWidgets('never makes a short page scroll', (WidgetTester tester) async {
        await pumpApp(tester, withFill(childHeight: 100));
        final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
        expect(position.maxScrollExtent, 0);
      });

      testWidgets('gets no height when the children fill the screen', (WidgetTester tester) async {
        await pumpApp(tester, withFill(childHeight: 2000));
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
        await tester.pumpAndSettle();
        expect(tester.getSize(fill).height, lessThanOrEqualTo(HisaabSpacing.l + 32 + 20));
      });
    });

    testWidgets('revealing an item scrolls it below the bar, not under it', (WidgetTester tester) async {
      await pumpApp(tester, view());
      final Finder row = find.byKey(const ValueKey<int>(10));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(row).dy, greaterThanOrEqualTo(12 + TopBarScrollView.barHeight + 8));
    });
  });
}
