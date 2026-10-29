import 'package:flutter/material.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'display_etch.dart';

/// The "display" card that holds amounts and Day Blocks: the light `surface` layer in light
/// theme, a calculator-style readout in dark (UI_DESIGN §3.1). Text inside uses
/// `displayInk` / `displayInk2`.
///
/// The hero and its loading shape set [raised] and [etched] (D106): the only raised card on
/// Home, with a guilloché etch, grain and a keyline behind the content, and more room above and
/// below it (D107). Other cards leave both off.
class DisplayCard extends StatelessWidget {
  const DisplayCard({
    super.key,
    required this.child,
    this.radius = HisaabRadii.card,
    this.padding,
    this.raised = false,
    this.etched = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Casts the `displayShadow` (transparent in dark, where the hairline edge does the job).
  final bool raised;

  /// Draws [DisplayEtch] behind [child], clipped to the card's shape.
  final bool etched;

  static const EdgeInsetsGeometry _plainPadding = EdgeInsetsDirectional.fromSTEB(
    HisaabSpacing.gutter,
    HisaabSpacing.gutter,
    HisaabSpacing.gutter,
    18,
  );

  // why: the sides keep the shared content inset; top and bottom get more room inside the keyline (D107).
  static const EdgeInsetsGeometry _etchedPadding = EdgeInsetsDirectional.symmetric(
    horizontal: HisaabSpacing.gutter,
    vertical: HisaabSpacing.xl,
  );

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Widget content = Padding(padding: padding ?? (etched ? _etchedPadding : _plainPadding), child: child);
    return Container(
      width: double.infinity,
      clipBehavior: etched ? Clip.antiAlias : Clip.none,
      decoration: ShapeDecoration(
        color: context.colors.display,
        // why: in dark mode the card is barely lighter than the page, so a hairline separates it.
        shape: HisaabShapes.squircle(radius, side: dark ? BorderSide(color: context.colors.hairline) : BorderSide.none),
        shadows: raised ? HisaabShapes.raised(context.colors.displayShadow) : null,
      ),
      child: etched
          ? Stack(
              children: <Widget>[
                const Positioned.fill(child: DisplayEtch()),
                content,
              ],
            )
          : content,
    );
  }
}
