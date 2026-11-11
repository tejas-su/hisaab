import 'package:hisaab/core/widgets/days_rail/days_rail_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DaysRailLayout (BR-6)', () {
    test('today is the first, bigger dot at the start edge', () {
      final List<RailDot> dots = DaysRailLayout.dots(count: 9, width: 234);
      expect(dots.first, (centre: DaysRailLayout.todaySize / 2, size: DaysRailLayout.todaySize));
    });

    test('the other days share the rest of the width evenly at full size', () {
      final List<RailDot> dots = DaysRailLayout.dots(count: 9, width: 234);
      const double slot = (234 - DaysRailLayout.todaySize) / 8;
      expect(dots.length, 9);
      expect(dots[1], (centre: DaysRailLayout.todaySize + slot / 2, size: DaysRailLayout.laterSize));
      expect(dots.last.centre, closeTo(234 - slot / 2, 1e-9));
    });

    test('31 days on a small phone: dots shrink to keep a gap, never under the floor', () {
      final List<RailDot> dots = DaysRailLayout.dots(count: 31, width: 194);
      const double slot = (194 - DaysRailLayout.todaySize) / 30;
      expect(dots[1].size, closeTo(slot - DaysRailLayout.minGap, 1e-9));
      expect(dots[2].centre - dots[1].centre - dots[1].size, closeTo(DaysRailLayout.minGap, 1e-9));
    });

    test('a very narrow rail keeps dots at the smallest size', () {
      expect(DaysRailLayout.dots(count: 31, width: 60)[1].size, DaysRailLayout.smallestSize);
    });

    test('the last day before payday is today alone', () {
      expect(DaysRailLayout.dots(count: 1, width: 234), <RailDot>[(centre: DaysRailLayout.todaySize / 2, size: DaysRailLayout.todaySize)]);
    });
  });
}
