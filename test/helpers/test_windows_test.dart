import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  group('TestWindows', () {
    test('book is the unfolded foldable, 673 by 841', () {
      expect(TestWindows.book, const Size(673, 841));
      expect(TestWindows.book, TestWindows.foldableUnfolded);
    });

    test('bookHinge is a 40dp vertical hinge as tall as the book window', () {
      expect(TestWindows.bookHinge.bounds.width, 40);
      expect(TestWindows.bookHinge.bounds.height, TestWindows.book.height);
      expect(TestWindows.bookHinge.type, DisplayFeatureType.hinge);
    });

    test('tabletop is 701 by 841 with a horizontal fold across it', () {
      expect(TestWindows.tabletop, const Size(701, 841));
      expect(TestWindows.tabletopFold.bounds.height, 0);
      expect(TestWindows.tabletopFold.bounds.width, TestWindows.tabletop.width);
    });

    test('splitScreen is 412 by 400 and splitScreenShort 412 by 300', () {
      expect(TestWindows.splitScreen, const Size(412, 400));
      expect(TestWindows.splitScreenShort, const Size(412, 300));
    });
  });
}
