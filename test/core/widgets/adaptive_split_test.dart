import 'dart:ui';

import 'package:hisaab/core/widgets/adaptive_split.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const Key _header = ValueKey<String>('header');
const Key _controls = ValueKey<String>('controls');
const Key _art = ValueKey<String>('art');

Widget _splitWithArt({double headerHeight = 120, void Function(double)? onArtHeight}) => Scaffold(
      body: AdaptiveSplit(
        header: SizedBox(key: _header, height: headerHeight, width: 200),
        art: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints space) {
            onArtHeight?.call(space.maxHeight);
            return const SizedBox.expand(key: _art);
          },
        ),
        controls: const SizedBox(key: _controls, height: 200, width: 200),
      ),
    );

Widget _split({bool fullWindow = true}) => const Scaffold(
      body: AdaptiveSplit(
        header: SizedBox(key: _header, height: 120, width: 200),
        controls: SizedBox(key: _controls, height: 200, width: 200),
      ),
    ).withFullWindow(fullWindow);

extension on Scaffold {
  Widget withFullWindow(bool fullWindow) => fullWindow
      ? this
      : const Scaffold(
          body: AdaptiveSplit(
            fullWindow: false,
            header: SizedBox(key: _header, height: 120, width: 200),
            controls: SizedBox(key: _controls, height: 200, width: 200),
          ),
        );
}

void main() {
  group('AdaptiveSplit (UI_DESIGN §13)', () {
    testWidgets('phone: header on top, controls at the bottom', (WidgetTester tester) async {
      await pumpApp(tester, _split());
      expect(tester.getRect(find.byKey(_header)).bottom, lessThan(tester.getRect(find.byKey(_controls)).top));
      expect(tester.getRect(find.byKey(_controls)).bottom, greaterThan(TestWindows.phone.height - 100));
    });

    testWidgets('unfolded foldable: no wider than 560dp', (WidgetTester tester) async {
      await pumpApp(tester, _split(), size: TestWindows.foldableUnfolded);
      expect(tester.getRect(find.byType(Column).first).width, lessThanOrEqualTo(AdaptiveSplit.readableWidth));
    });

    testWidgets('tabletop posture: header above the fold, controls below it', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _split(),
        size: const Size(701, 841),
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 420, 701, 420),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(tester.getRect(find.byKey(_header)).bottom, lessThanOrEqualTo(420));
      expect(tester.getRect(find.byKey(_controls)).top, greaterThanOrEqualTo(420));
    });

    testWidgets('book posture: either side of the fold', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _split(),
        size: TestWindows.foldableLandscape,
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(420, 0, 420, 701),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(tester.getRect(find.byKey(_header)).right, lessThanOrEqualTo(420));
      expect(tester.getRect(find.byKey(_controls)).left, greaterThanOrEqualTo(420));
    });

    testWidgets('inside a tray on a short window: side by side', (WidgetTester tester) async {
      await pumpApp(tester, _split(fullWindow: false), size: const Size(700, 412));
      expect(tester.getRect(find.byKey(_header)).right, lessThanOrEqualTo(tester.getRect(find.byKey(_controls)).left));
    });

    testWidgets('phone with art: the art fills the gap between header and controls', (WidgetTester tester) async {
      await pumpApp(tester, _splitWithArt());

      final Rect art = tester.getRect(find.byKey(_art));
      expect(art.top, greaterThan(tester.getRect(find.byKey(_header)).bottom));
      expect(art.bottom, lessThan(tester.getRect(find.byKey(_controls)).top));
      expect(art.height, greaterThan(300));
    });

    testWidgets('a header that fills the screen leaves the art no room, and nothing overflows', (WidgetTester tester) async {
      double? artHeight;
      await pumpApp(tester, _splitWithArt(headerHeight: 800, onArtHeight: (double height) => artHeight = height));

      expect(artHeight, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('short window: side by side, with no art', (WidgetTester tester) async {
      await pumpApp(tester, _splitWithArt(), size: TestWindows.phoneLandscape);

      expect(find.byKey(_header), findsOneWidget);
      expect(find.byKey(_art), findsNothing);
    });
  });
}
