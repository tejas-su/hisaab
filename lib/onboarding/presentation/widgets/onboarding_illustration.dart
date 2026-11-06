import 'package:flutter/material.dart';

/// The pictures onboarding shows between a question and its controls (UI_DESIGN §5.1, D144).
enum OnboardingPicture {
  /// A hand holding up a calendar: "When does it come?".
  payday('payday'),

  /// A hand ringing one day with a pencil: "Which day of the month?" and "Which day of the week?".
  pickDay('pick_day'),

  /// A hand holding up a receipt: "Any fixed bills?".
  bills('bills');

  const OnboardingPicture(this.fileStem);

  /// The start of the asset's file name, before `_light.webp` or `_dark.webp`.
  final String fileStem;
}

/// A decorative onboarding [picture] that fills the space it is given, in the current theme.
///
/// It is hidden from TalkBack, and it draws nothing when the space is under [minHeight], so a
/// short window or large text never loses the controls to a picture.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration(this.picture, {super.key});

  final OnboardingPicture picture;

  /// Below this height the picture is too small to read, so it is left out.
  static const double minHeight = 120;

  // why: the art is drawn on a 336 × 266 canvas; wider than this it outgrows the question.
  static const double _maxWidth = 320;

  /// The asset for [picture] in light or dark.
  static String assetFor(OnboardingPicture picture, Brightness brightness) =>
      'assets/illustrations/${picture.fileStem}_${brightness.name}.webp';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints space) {
          if (space.maxHeight < minHeight) {
            return const SizedBox.shrink();
          }
          return ExcludeSemantics(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _maxWidth, maxHeight: space.maxHeight),
                child: Image.asset(assetFor(picture, Theme.of(context).brightness), fit: BoxFit.contain),
              ),
            ),
          );
        },
      );
}
