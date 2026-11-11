import 'package:hisaab/core/layout/app_layout.dart';
import 'package:hisaab/core/layout/app_layout_scope.dart';
import 'package:hisaab/core/layout/window_class.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _LayoutProbe extends StatelessWidget {
  const _LayoutProbe(this.onBuild);

  final ValueChanged<AppLayout> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(AppLayoutScope.of(context));
    return const SizedBox();
  }
}

void main() {
  group('AppLayoutScope', () {
    testWidgets('without a scope, falls back to a layout for the window size', (WidgetTester tester) async {
      late AppLayout seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: _LayoutProbe((AppLayout layout) => seen = layout),
        ),
      );
      expect(seen.widthClass, WidthClass.expanded);
    });

    testWidgets('rebuilds dependents when a resize changes the layout', (WidgetTester tester) async {
      final List<WidthClass> seen = <WidthClass>[];
      Widget at(Size size) => MediaQuery(
            data: MediaQueryData(size: size),
            child: AppLayoutScope(child: _LayoutProbe((AppLayout layout) => seen.add(layout.widthClass))),
          );

      await tester.pumpWidget(at(const Size(412, 915)));
      await tester.pumpWidget(at(const Size(1280, 800)));
      expect(seen, <WidthClass>[WidthClass.compact, WidthClass.expanded]);
    });
  });
}
