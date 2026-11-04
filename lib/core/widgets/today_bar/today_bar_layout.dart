import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'today_bar_data.dart';

/// One drawn piece of today's bar: one bite, or several tiny ones joined.
typedef BitePiece = ({double left, double width, String? label});

/// Where today's bar draws its yellow, bites and tick in a row [of] a given width (SPEC BR-6).
final class TodayBarLayout extends Equatable {
  const TodayBarLayout._({required this.bites, required this.yellowEnd, required this.tickX});

  /// Lays [data] out across [width]: the first bite at the end edge, each later one nearer the
  /// yellow, [gap] apart. A bite narrower than [minBite] joins its neighbours, so any spend
  /// shows and nothing is a sliver; a joined piece keeps the name of its biggest bite.
  factory TodayBarLayout.of(TodayBarData data, double width) {
    final List<BitePiece> pieces = <BitePiece>[];
    double end = width;
    double pending = 0;
    TodayBite? biggest;
    for (final TodayBite bite in data.bites) {
      pending += bite.share * width;
      biggest = biggest == null || bite.share > biggest.share ? bite : biggest;
      if (pending - gap >= minBite) {
        pieces.add((left: end - pending + gap, width: pending - gap, label: biggest.label));
        end -= pending;
        pending = 0;
        biggest = null;
      }
    }
    final List<BitePiece> bites = pending > 0 ? _joinTail(pieces, end, pending) : pieces;
    final double yellow = data.left * width;
    return TodayBarLayout._(
      bites: bites,
      yellowEnd: bites.isEmpty ? yellow : math.min(yellow, bites.last.left - gap),
      tickX: switch (data.tick) {
        final double tick => tick * width,
        null => null,
      },
    );
  }

  /// Space between two pieces, and between the yellow and the nearest bite.
  static const double gap = 3;

  /// The narrowest piece drawn.
  static const double minBite = 4;

  /// Pieces from the end edge towards the yellow.
  final List<BitePiece> bites;

  /// Where the yellow stops at rest, a [gap] before the nearest bite.
  final double yellowEnd;

  /// Where today's share ends when it was overspent; null when not over.
  final double? tickX;

  // why: a tiny bite left beside the yellow joins the piece before it; alone, it is drawn at
  // minBite so a ₹1 spend still shows (D91).
  static List<BitePiece> _joinTail(List<BitePiece> pieces, double end, double pending) {
    if (pieces.isEmpty) {
      final double width = math.max(pending - gap, minBite);
      return <BitePiece>[(left: end - width, width: width, label: null)];
    }
    final BitePiece last = pieces.last;
    return <BitePiece>[
      ...pieces.take(pieces.length - 1),
      (left: end - pending + gap, width: last.width + pending, label: last.label),
    ];
  }

  @override
  List<Object?> get props => <Object?>[bites, yellowEnd, tickX];
}
