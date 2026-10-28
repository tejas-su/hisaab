import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// Back for every pushed screen: a 40dp well inside the 48dp tap target, its visible edge
/// flush with the content edge (D57, D80). Pops the current route.
///
/// In an [AppBar], pass it as `leading` inside [HisaabBackButton.leadingPadding] with
/// [HisaabBackButton.leadingWidth] so the well lines up with the cards' edge.
class HisaabBackButton extends StatelessWidget {
  const HisaabBackButton({super.key});

  /// The [AppBar.leadingWidth] that fits the gutter and the tap target.
  static const double leadingWidth = HisaabSpacing.gutter + HisaabSizes.minTouchTarget;

  /// Puts the button's start on the gutter inside an [AppBar]'s leading slot.
  static const EdgeInsetsDirectional leadingPadding = EdgeInsetsDirectional.only(start: HisaabSpacing.gutter);

  @override
  Widget build(BuildContext context) {
    final String back = AppLocalizations.of(context).back;
    // why: without its own container, Back merges with a title beside it into one node and
    // TalkBack reads "Back Ask AI" as one heading button.
    return Semantics(
      container: true,
      // why: the long-press hint Material's IconButton gave; Pressable already announces the label.
      child: Tooltip(
        message: back,
        excludeFromSemantics: true,
        child: Pressable(
          semanticLabel: back,
          onPressed: () => Navigator.of(context).maybePop(),
          builder: (BuildContext context, bool pressed) => Container(
            width: HisaabSizes.minTouchTarget,
            height: HisaabSizes.minTouchTarget,
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              key: const ValueKey<String>('back-well'),
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: pressed ? context.colors.hairline : context.colors.sunk,
                shape: HisaabShapes.squircle(HisaabRadii.chip),
              ),
              child: const AppIcon(AppIcons.back),
            ),
          ),
        ),
      ),
    );
  }
}
