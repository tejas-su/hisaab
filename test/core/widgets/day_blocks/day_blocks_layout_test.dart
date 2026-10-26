import 'dart:ui';

import 'package:expense_tracker/core/widgets/day_blocks/day_blocks_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayBlocksLayout (BR-6 widths)', () {
    test('9 blocks share the width with 6dp gaps', () {
      final DayBlocksLayout layout = DayBlocksLayout.of(count: 9, width: 300, labelWidth: 20);
      expect(layout.blocks, hasLength(9));
      expect(layout.blocks.first.width, closeTo((300 - 6 * 8) / 9, 1e-9));
      expect(layout.blocks[1].left, closeTo(layout.blocks.first.width + 6, 1e-9));
      expect(layout.hiddenCount, 0);
    });

    test('above 16 blocks the gap narrows to 3dp', () {
      final DayBlocksLayout layout = DayBlocksLayout.of(count: 31, width: 330, labelWidth: 20);
      expect(layout.blocks, hasLength(31));
      expect(layout.blocks[1].left - layout.blocks.first.width, closeTo(3, 1e-9));
    });

    test('blocks under 6dp collapse to the next 7 days and a +N label', () {
      final DayBlocksLayout layout = DayBlocksLayout.of(count: 31, width: 200, labelWidth: 24);
      expect(layout.blocks, hasLength(7));
      expect(layout.hiddenCount, 24);
      expect(layout.labelLeft + 24, closeTo(200, 1e-9));
    });

    test('one block on the last day fills the row', () {
      expect(DayBlocksLayout.of(count: 1, width: 120, labelWidth: 0).blocks.single.width, 120);
    });

    test('blockRect is bottom-aligned and scaled', () {
      expect(blockRect((left: 10, width: 20), 40, 0.5), const Rect.fromLTWH(10, 20, 20, 20));
    });

    test('layouts compare by value', () {
      expect(DayBlocksLayout.of(count: 9, width: 300, labelWidth: 0), DayBlocksLayout.of(count: 9, width: 300, labelWidth: 0));
    });
  });
}
