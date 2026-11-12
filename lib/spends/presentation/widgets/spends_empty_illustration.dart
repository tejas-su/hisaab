import 'package:material_ui/material_ui.dart';

/// The blank bill on a spike that fills the space under an empty Spends cycle's card (D150).
///
/// It is decorative and hidden from TalkBack. It fills the space it is given, in the current
/// theme, and draws nothing when that space is under [minHeight], so large text or a short
/// window never scrolls for a picture.
class SpendsEmptyIllustration extends StatelessWidget {
  const SpendsEmptyIllustration({super.key});

  /// Below this height the picture is too small to read, so it is left out.
  static const double minHeight = 120;

  // why: the art is drawn on a 320 × 250 canvas; wider than this it outweighs the card's sentence.
  static const double _maxWidth = 300;

  /// The asset in light or dark.
  static String assetFor(Brightness brightness) => 'assets/illustrations/spends_empty_${brightness.name}.webp';

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
                child: Image.asset(assetFor(Theme.of(context).brightness), fit: BoxFit.contain),
              ),
            ),
          );
        },
      );
}
