import 'package:expense_tracker/backup/presentation/widgets/hold_fill_clipper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HoldFillClipper', () {
    const Size size = Size(200, 64);

    test('fills from the left in a left-to-right layout', () {
      expect(const HoldFillClipper(fraction: 0.25, textDirection: TextDirection.ltr).getClip(size), const Rect.fromLTWH(0, 0, 50, 64));
    });

    test('fills from the right in a right-to-left layout', () {
      expect(const HoldFillClipper(fraction: 0.25, textDirection: TextDirection.rtl).getClip(size), const Rect.fromLTWH(150, 0, 50, 64));
    });

    test('never clips outside the key', () {
      expect(const HoldFillClipper(fraction: 1.5, textDirection: TextDirection.ltr).getClip(size).width, 200);
      expect(const HoldFillClipper(fraction: -1, textDirection: TextDirection.ltr).getClip(size).width, 0);
    });

    test('reclips only when its inputs change', () {
      const HoldFillClipper clipper = HoldFillClipper(fraction: 0.5, textDirection: TextDirection.ltr);

      expect(clipper.shouldReclip(const HoldFillClipper(fraction: 0.5, textDirection: TextDirection.ltr)), isFalse);
      expect(clipper.shouldReclip(const HoldFillClipper(fraction: 0.6, textDirection: TextDirection.ltr)), isTrue);
      expect(clipper.shouldReclip(const HoldFillClipper(fraction: 0.5, textDirection: TextDirection.rtl)), isTrue);
    });
  });
}
