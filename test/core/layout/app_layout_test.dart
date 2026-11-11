import 'dart:ui';

import 'package:hisaab/core/layout/app_layout.dart';
import 'package:hisaab/core/layout/window_class.dart';
import 'package:flutter_test/flutter_test.dart';

DisplayFeature _fold(Rect bounds, {DisplayFeatureState state = DisplayFeatureState.postureFlat}) =>
    DisplayFeature(bounds: bounds, type: DisplayFeatureType.fold, state: state);

void main() {
  group('widthClassOf / heightClassOf', () {
    test('uses the 600/840 dp breakpoints', () {
      expect(widthClassOf(599.9), WidthClass.compact);
      expect(widthClassOf(600), WidthClass.medium);
      expect(widthClassOf(839.9), WidthClass.medium);
      expect(widthClassOf(840), WidthClass.expanded);
    });

    test('treats heights under 480 dp as compact', () {
      expect(heightClassOf(479), HeightClass.compact);
      expect(heightClassOf(480), HeightClass.regular);
    });
  });

  group('AppLayout.resolve', () {
    test('phone portrait: one full-width pane', () {
      final AppLayout layout = AppLayout.resolve(window: const Size(412, 915));
      expect(layout.widthClass, WidthClass.compact);
      expect(layout.heightClass, HeightClass.regular);
      expect(layout.panes, const SinglePane(Rect.fromLTWH(0, 0, 412, 915)));
    });

    test('unfolded foldable portrait without a reported fold: centred 560 dp column', () {
      final AppLayout layout = AppLayout.resolve(window: const Size(673, 841));
      expect(layout.widthClass, WidthClass.medium);
      expect(layout.panes, const SinglePane(Rect.fromLTWH(56.5, 0, 560, 841)));
    });

    test('tablet landscape: primary pane capped at 480 dp beside the secondary pane', () {
      final AppLayout layout = AppLayout.resolve(window: const Size(1280, 800));
      expect(layout.widthClass, WidthClass.expanded);
      expect(
        layout.panes,
        const SideBySidePanes(
          primary: Rect.fromLTWH(0, 0, 480, 800),
          secondary: Rect.fromLTWH(480, 0, 800, 800),
          splitByHinge: false,
        ),
      );
    });

    test('phone landscape: two panes, compact height', () {
      final AppLayout layout = AppLayout.resolve(window: const Size(915, 412));
      expect(layout.heightClass, HeightClass.compact);
      expect(layout.panes, isA<SideBySidePanes>());
      expect((layout.panes as SideBySidePanes).primary.width, 366);
    });

    test('primary pane never drops below 360 dp', () {
      final AppLayout layout = AppLayout.resolve(window: const Size(860, 600));
      expect((layout.panes as SideBySidePanes).primary.width, 360);
    });

    test('book posture: panes split exactly at a vertical fold', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(841, 701),
        displayFeatures: <DisplayFeature>[_fold(const Rect.fromLTRB(420, 0, 420, 701))],
      );
      expect(
        layout.panes,
        const SideBySidePanes(
          primary: Rect.fromLTRB(0, 0, 420, 701),
          secondary: Rect.fromLTRB(420, 0, 841, 701),
          splitByHinge: true,
        ),
      );
    });

    test('a physical hinge with a gap: no content inside the hinge', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(1114, 720),
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(540, 0, 574, 720),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );
      final SideBySidePanes panes = layout.panes as SideBySidePanes;
      expect(panes.primary.right, 540);
      expect(panes.secondary.left, 574);
    });

    test('tabletop posture: top and bottom halves around a half-opened horizontal fold', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(701, 841),
        displayFeatures: <DisplayFeature>[
          _fold(const Rect.fromLTRB(0, 420, 701, 420), state: DisplayFeatureState.postureHalfOpened),
        ],
      );
      expect(
        layout.panes,
        const TabletopPanes(top: Rect.fromLTRB(0, 0, 701, 420), bottom: Rect.fromLTRB(0, 420, 701, 841)),
      );
    });

    test('a flat horizontal fold is ignored', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(701, 841),
        displayFeatures: <DisplayFeature>[_fold(const Rect.fromLTRB(0, 420, 701, 420))],
      );
      expect(layout.panes, isA<SinglePane>());
    });

    test('a vertical fold in a window narrower than 600 dp is ignored (split-screen half)', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(420, 701),
        displayFeatures: <DisplayFeature>[_fold(const Rect.fromLTRB(210, 0, 210, 701))],
      );
      expect(layout.panes, const SinglePane(Rect.fromLTWH(0, 0, 420, 701)));
    });

    test('a fold that does not span the window is ignored', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(841, 701),
        displayFeatures: <DisplayFeature>[_fold(const Rect.fromLTRB(420, 100, 420, 600))],
      );
      expect(layout.panes, isA<SideBySidePanes>());
      expect((layout.panes as SideBySidePanes).splitByHinge, isFalse);
    });

    test('display cutouts never split the layout', () {
      final AppLayout layout = AppLayout.resolve(
        window: const Size(412, 915),
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(180, 0, 232, 30),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );
      expect(layout.panes, isA<SinglePane>());
    });

    test('small split-screen window: compact in both directions', () {
      final AppLayout layout = AppLayout.resolve(window: const Size(412, 400));
      expect(layout.widthClass, WidthClass.compact);
      expect(layout.heightClass, HeightClass.compact);
      expect(layout.panes, isA<SinglePane>());
    });

    test('the same window resolves to an equal layout', () {
      expect(AppLayout.resolve(window: const Size(412, 915)), AppLayout.resolve(window: const Size(412, 915)));
      expect(AppLayout.resolve(window: const Size(412, 915)) == AppLayout.resolve(window: const Size(915, 412)), isFalse);
    });

    test('showsDock is true only for a single pane', () {
      expect(AppLayout.resolve(window: const Size(412, 915)).showsDock, isTrue);
      expect(AppLayout.resolve(window: const Size(1280, 800)).showsDock, isFalse);
    });
  });
}
