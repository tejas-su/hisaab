import 'package:expense_tracker/core/widgets/today_bar/today_bar_data.dart';
import 'package:expense_tracker/core/widgets/today_bar/today_bar_layout.dart';
import 'package:flutter_test/flutter_test.dart';

const double _width = 288;
const double _gap = TodayBarLayout.gap;

void main() {
  group('TodayBarLayout (BR-6)', () {
    test('the first bite sits at the end edge and each later one nearer the yellow, a gap apart', () {
      final TodayBarLayout layout = TodayBarLayout.of(
        const TodayBarData(
          style: TodayBarStyle.onTrack,
          left: 0.5,
          bites: <TodayBite>[TodayBite(share: 0.25, label: 'Food'), TodayBite(share: 0.25, label: 'Travel')],
        ),
        _width,
      );
      expect(layout.bites, <BitePiece>[
        (left: 216 + _gap, width: 72 - _gap, label: 'Food'),
        (left: 144 + _gap, width: 72 - _gap, label: 'Travel'),
      ]);
      expect(layout.yellowEnd, 144);
      expect(layout.tickX, isNull);
    });

    test('worked example at 288dp: chai (about 6dp) is under 4dp after its gap, so it joins lunch, which names the piece', () {
      final TodayBarLayout layout = TodayBarLayout.of(
        const TodayBarData(
          style: TodayBarStyle.onTrack,
          left: 1430 / 1850,
          bites: <TodayBite>[TodayBite(share: 40 / 1850, label: 'Chai'), TodayBite(share: 380 / 1850, label: 'Food')],
        ),
        _width,
      );
      final BitePiece piece = layout.bites.single;
      expect(piece.label, 'Food');
      expect(piece.left + piece.width, _width);
      expect(piece.left, closeTo(1430 / 1850 * _width + _gap, 1e-9));
      expect(layout.yellowEnd, closeTo(1430 / 1850 * _width, 1e-9));
    });

    test('a lone tiny spend still shows at 4dp, and the yellow stops a gap before it (any spend shows, D91)', () {
      final TodayBarLayout layout = TodayBarLayout.of(
        const TodayBarData(style: TodayBarStyle.onTrack, left: 1 - 1 / 1850, bites: <TodayBite>[TodayBite(share: 1 / 1850, label: 'Chai')]),
        _width,
      );
      expect(layout.bites.single, (left: _width - TodayBarLayout.minBite, width: TodayBarLayout.minBite, label: null));
      expect(layout.yellowEnd, _width - TodayBarLayout.minBite - _gap);
    });

    test('a tiny bite next to the yellow joins the bite before it', () {
      final TodayBarLayout layout = TodayBarLayout.of(
        const TodayBarData(
          style: TodayBarStyle.onTrack,
          left: 0.49,
          bites: <TodayBite>[TodayBite(share: 0.5, label: 'Rent'), TodayBite(share: 0.01, label: 'Chai')],
        ),
        _width,
      );
      expect(layout.bites.single.label, 'Rent');
      expect(layout.bites.single.left, closeTo(0.49 * _width + _gap, 1e-9));
    });

    test('thirty tiny spends become a few pieces, never slivers under 4dp', () {
      final TodayBarLayout layout = TodayBarLayout.of(
        TodayBarData(style: TodayBarStyle.onTrack, left: 0.7, bites: List<TodayBite>.filled(30, const TodayBite(share: 0.01))),
        _width,
      );
      expect(layout.bites.every((BitePiece p) => p.width >= TodayBarLayout.minBite), isTrue);
      expect(layout.bites.length, lessThan(30));
      expect(layout.bites.first.left + layout.bites.first.width, _width);
    });

    test('two layouts of the same picture are equal', () {
      const TodayBarData data = TodayBarData(style: TodayBarStyle.onTrack, left: 0.5, bites: <TodayBite>[TodayBite(share: 0.5)]);
      expect(TodayBarLayout.of(data, _width), TodayBarLayout.of(data, _width));
      expect(TodayBarLayout.of(data, _width), isNot(TodayBarLayout.of(data, 300)));
    });

    test('nothing spent: no bites, and the yellow runs the whole width', () {
      final TodayBarLayout layout = TodayBarLayout.of(const TodayBarData(style: TodayBarStyle.onTrack, left: 1), _width);
      expect(layout.bites, isEmpty);
      expect(layout.yellowEnd, _width);
    });

    test('over today: no yellow, and the tick sits at today\'s share', () {
      final TodayBarLayout layout = TodayBarLayout.of(
        const TodayBarData(style: TodayBarStyle.over, bites: <TodayBite>[TodayBite(share: 1, label: 'Food')], tick: 0.8),
        _width,
      );
      expect(layout.yellowEnd, 0);
      expect(layout.tickX, closeTo(0.8 * _width, 1e-9));
      expect(layout.bites.single, (left: _gap, width: _width - _gap, label: 'Food'));
    });
  });
}
