import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Where each block goes in a row of a given width (SPEC BR-6 widths).
///
/// Blocks share the width equally with a 6dp gap (3dp above 16 blocks). If a block would be
/// narrower than 6dp, only the next 7 days are drawn and [hiddenCount] are summarised as "+N".
final class DayBlocksLayout extends Equatable {
  const DayBlocksLayout._({required this.blocks, required this.hiddenCount});

  /// Lays out [count] blocks in [width], reserving [labelWidth] for the "+N" label if needed.
  factory DayBlocksLayout.of({required int count, required double width, required double labelWidth}) {
    final double gap = count <= _wideGapLimit ? _wideGap : _narrowGap;
    final double blockWidth = (width - gap * (count - 1)) / count;
    if (blockWidth >= minBlockWidth) {
      return DayBlocksLayout._(blocks: _row(count, blockWidth, gap), hiddenCount: 0);
    }
    final double visibleWidth = (width - labelWidth - _wideGap * _collapsedCount) / _collapsedCount;
    return DayBlocksLayout._(blocks: _row(_collapsedCount, visibleWidth, _wideGap), hiddenCount: count - _collapsedCount);
  }

  static const double minBlockWidth = 6;
  static const int _wideGapLimit = 16;
  static const double _wideGap = 6;
  static const double _narrowGap = 3;
  static const int _collapsedCount = 7;

  /// Left edge and width of each drawn block.
  final List<({double left, double width})> blocks;

  /// Days not drawn; 0 when every block fits.
  final int hiddenCount;

  /// Left edge of the "+N" label.
  double get labelLeft => blocks.last.left + blocks.last.width + _wideGap;

  static List<({double left, double width})> _row(int count, double width, double gap) =>
      List<({double left, double width})>.generate(count, (int i) => (left: i * (width + gap), width: width));

  @override
  List<Object?> get props => <Object?>[blocks, hiddenCount];
}

/// A block's rectangle, bottom-aligned in a row of [rowHeight], scaled to [heightFactor].
Rect blockRect(({double left, double width}) block, double rowHeight, double heightFactor) {
  final double height = rowHeight * heightFactor;
  return Rect.fromLTWH(block.left, rowHeight - height, block.width, height);
}
