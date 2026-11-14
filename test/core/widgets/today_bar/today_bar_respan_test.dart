import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/widgets/today_bar/today_bar_data.dart';
import 'package:hisaab/core/widgets/today_bar/today_bar_layout.dart';

/// A change of today's share re-spans every segment in one motion (SPEC BR-6, FR-FX-5 AC-2): after a
/// fix the same ₹420 bite is a bigger part of a smaller share.
void main() {
  const double width = 1000;

  // ₹420 spent of A = ₹1,850: the yellow is 77%, the bite 23%.
  const TodayBarData before = TodayBarData(
    style: TodayBarStyle.onTrack,
    left: 1430 / 1850,
    bites: <TodayBite>[TodayBite(share: 420 / 1850, label: 'Food')],
  );

  // A = ₹1,383 after a ₹4,200 fix: yellow 70%, bite 30%.
  const TodayBarData lower = TodayBarData(
    style: TodayBarStyle.onTrack,
    left: 963 / 1383,
    bites: <TodayBite>[TodayBite(share: 420 / 1383, label: 'Food')],
  );

  // A = ₹1,961 after a ₹1,000 Got fix: yellow 78.6%, bite 21.4%.
  const TodayBarData higher = TodayBarData(
    style: TodayBarStyle.onTrack,
    left: 1541 / 1961,
    bites: <TodayBite>[TodayBite(share: 420 / 1961, label: 'Food')],
  );

  TodayBarLayout at(TodayBarData from, TodayBarData to, double t) =>
      TodayBarLayout.lerp(TodayBarLayout.of(from, width), TodayBarLayout.of(to, width), t);

  group('TodayBarLayout.lerp', () {
    test('at 0 it is the old layout and at 1 the new one', () {
      expect(at(before, lower, 0), TodayBarLayout.of(before, width));
      expect(at(before, lower, 1), TodayBarLayout.of(lower, width));
    });

    test('the yellow goes 77% to 70% and the bite 23% to 30% of the span (a lower figure)', () {
      final TodayBarLayout start = TodayBarLayout.of(before, width);
      final TodayBarLayout end = TodayBarLayout.of(lower, width);

      expect(start.yellowEnd / width, closeTo(0.77, 0.005));
      expect(end.yellowEnd / width, closeTo(0.70, 0.006));
      expect(start.bites.single.width / width, closeTo(0.227, 0.005));
      expect(end.bites.single.width / width, closeTo(0.304, 0.005));
    });

    test('halfway, the bite is half-way between its old and new width, and its left edge too', () {
      final TodayBarLayout start = TodayBarLayout.of(before, width);
      final TodayBarLayout end = TodayBarLayout.of(lower, width);

      final TodayBarLayout middle = at(before, lower, 0.5);

      expect(middle.bites.single.width, closeTo((start.bites.single.width + end.bites.single.width) / 2, 0.001));
      expect(middle.bites.single.left, closeTo((start.bites.single.left + end.bites.single.left) / 2, 0.001));
      expect(middle.yellowEnd, closeTo((start.yellowEnd + end.yellowEnd) / 2, 0.001));
    });

    test('a higher figure gives 78.6% and 21.4% and plays the same way', () {
      final TodayBarLayout end = TodayBarLayout.of(higher, width);

      expect(end.yellowEnd / width, closeTo(0.786, 0.001));
      expect(end.bites.single.width / width, closeTo(0.214, 0.005));
      final TodayBarLayout middle = at(before, higher, 0.5);
      expect(middle.bites.single.width, closeTo((TodayBarLayout.of(before, width).bites.single.width + end.bites.single.width) / 2, 0.001));
    });

    test('a bite that is new has nothing to move from, so it is drawn where it lands', () {
      const TodayBarData grown = TodayBarData(
        style: TodayBarStyle.onTrack,
        left: 0.5,
        bites: <TodayBite>[TodayBite(share: 0.2, label: 'Food'), TodayBite(share: 0.1, label: 'Chai')],
      );

      final TodayBarLayout middle = at(before, grown, 0.5);

      expect(middle.bites, hasLength(2));
      expect(middle.bites.last, TodayBarLayout.of(grown, width).bites.last);
    });

    test('the tick of the new layout is kept', () {
      const TodayBarData over = TodayBarData(style: TodayBarStyle.over, tick: 0.6, bites: <TodayBite>[TodayBite(share: 0.4)]);

      expect(at(before, over, 0.5).tickX, 600);
    });
  });
}
