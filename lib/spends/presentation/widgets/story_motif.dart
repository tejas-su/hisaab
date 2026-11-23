import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../domain/entities/month_story.dart';

/// The line patterns behind the month story, one per page, in the hero etch's hand, and the slow
/// drift each one makes once it has settled in (D210).
///
/// A drift only moves the painted layer (a turn about [origin], a grow, or a [shift]), so the
/// pattern is never repainted while it moves.
enum StoryMotif {
  /// A guilloché rosette at the top end, like the hero's: the month itself, and the story card.
  rosette(origin: AlignmentDirectional(0.76, -0.45), turn: 0.35),

  /// Ripples spreading from the bottom end corner: what you kept.
  rings(origin: AlignmentDirectional(1, 0.84), grow: 0.12),

  /// A sunburst from the bottom start corner: where the money went.
  rays(origin: AlignmentDirectional(-1, 1), turn: -0.12),

  /// Stacked waves across the bottom, rolling towards the start: the ups and downs of your days.
  waves(shift: Offset(-HisaabSpacing.xxxl * 3, 0)),

  /// Two overlapping sets of rings: this month against the last.
  orbits(origin: AlignmentDirectional(0, 0.6), turn: 0.25),

  /// Day blocks scattered like confetti, drifting down: the end.
  blocks(shift: Offset(0, HisaabSpacing.xxxl));

  const StoryMotif({this.origin = AlignmentDirectional.center, this.turn = 0, this.grow = 0, this.shift = Offset.zero});

  /// The point the drift turns and grows about.
  final AlignmentDirectional origin;

  /// How far the drift turns, in radians, in left-to-right.
  final double turn;

  /// How much the drift grows, as a fraction of the pattern's size.
  final double grow;

  /// How far the drift slides, in dp, in left-to-right.
  final Offset shift;

  /// The motif each story page is drawn with.
  static StoryMotif forPage(StoryPage page) => switch (page) {
        StoryPage.month => rosette,
        StoryPage.kept => rings,
        StoryPage.whereItWent => rays,
        StoryPage.days => waves,
        StoryPage.against => orbits,
        StoryPage.end => blocks,
      };

  /// The drift's transform [progress] of the way through (0 to 1), mirrored in right-to-left.
  Matrix4 driftAt(double progress, TextDirection direction) {
    final double mirror = direction == TextDirection.rtl ? -1 : 1;
    final double scale = 1 + grow * progress;
    return Matrix4.identity()
      ..translateByDouble(shift.dx * progress * mirror, shift.dy * progress, 0, 1)
      ..rotateZ(turn * progress * mirror)
      ..scaleByDouble(scale, scale, 1, 1);
  }
}
