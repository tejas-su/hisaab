import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

/// One window a keypad sheet must keep its amount and action key on screen in.
typedef PinnedCase = ({String name, Size size, double textScale, double bottomInset, List<DisplayFeature> features});

/// The windows of UI_DESIGN §13 plus split-screen, a tabletop fold, a 3-button navigation bar and
/// large text, for the keypad sheets of the bill-sheet route (P2, P3).
const List<PinnedCase> pinnedCases = <PinnedCase>[
  (name: 'phone', size: TestWindows.phone, textScale: 1, bottomInset: 0, features: <DisplayFeature>[]),
  (name: 'phone with a 3-button bar', size: TestWindows.phone, textScale: 1, bottomInset: 48, features: <DisplayFeature>[]),
  (name: '320x568', size: TestWindows.smallPhone, textScale: 1, bottomInset: 0, features: <DisplayFeature>[]),
  (name: '320x568 at 1.5x text', size: TestWindows.smallPhone, textScale: 1.5, bottomInset: 0, features: <DisplayFeature>[]),
  (name: '412x400 split-screen', size: TestWindows.splitScreen, textScale: 1, bottomInset: 0, features: <DisplayFeature>[]),
  (name: 'phone landscape', size: TestWindows.phoneLandscape, textScale: 1, bottomInset: 0, features: <DisplayFeature>[]),
  (name: 'foldable unfolded', size: TestWindows.foldableUnfolded, textScale: 1, bottomInset: 0, features: <DisplayFeature>[]),
  (name: 'tablet', size: TestWindows.tablet, textScale: 1, bottomInset: 0, features: <DisplayFeature>[]),
  (name: 'tabletop', size: TestWindows.tabletop, textScale: 1, bottomInset: 0, features: <DisplayFeature>[TestWindows.tabletopFold]),
];

/// Sets the system bar inset at the bottom of the test window.
void setBottomInset(WidgetTester tester, double inset) {
  tester.view
    ..padding = FakeViewPadding(bottom: inset)
    ..viewPadding = FakeViewPadding(bottom: inset);
}

/// Expects the typed amount, the keypad and the action key to lie wholly inside the window (below
/// the fold in a tabletop, above the bottom system bar), so none needs scrolling to.
void expectPinnedOnScreen(WidgetTester tester, {required PinnedCase window, required Finder amount, required Finder action}) {
  final double top = window.features.isEmpty ? 0 : window.features.first.bounds.bottom;
  final Rect visible = Rect.fromLTRB(0, top, window.size.width, window.size.height - window.bottomInset);
  final Finder keypad = find.byKey(const ValueKey<String>('keypad-5'));
  for (final MapEntry<String, Finder> part in <String, Finder>{'amount': amount, 'keypad': keypad, 'action key': action}.entries) {
    final Rect box = tester.getRect(part.value);
    expect(visible.inflate(0.5).contains(box.topLeft) && visible.inflate(0.5).contains(box.bottomRight), isTrue,
        reason: '${window.name}: ${part.key} $box is outside $visible');
  }
  final Rect lastRow = tester.getRect(find.byKey(const ValueKey<String>('keypad-0')));
  expect(visible.inflate(0.5).contains(lastRow.bottomRight), isTrue, reason: '${window.name}: the keypad\'s last row $lastRow is outside $visible');
}
