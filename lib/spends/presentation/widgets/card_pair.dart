import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';

/// Lays out [first] and [second] beside each other, the same height, when the width the pane gives
/// them fits two cards at the current text size; otherwise [first] above [second]. Spends uses it
/// for the Ask AI and *Can I afford it?* cards (UI_DESIGN 5.4a).
///
/// It reads the width it is given, not the window's, so a pane beside Home or beside a hinge stacks
/// when it is narrow even though the window is wide.
class CardPair extends StatelessWidget {
  const CardPair({super.key, required this.first, required this.second});

  /// The narrowest a card may get beside the other at 1× text.
  // why: two cards fit from a 600dp window's single pane (UI_DESIGN 5.4a) but not on a 412dp phone,
  // where the title of each would wrap to three lines.
  static const double minCardWidth = 200;

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            constraints.maxWidth >= _besideWidth(context) ? _beside() : _stacked(),
      );

  double _besideWidth(BuildContext context) => MediaQuery.textScalerOf(context).scale(minCardWidth) * 2 + HisaabSpacing.m;

  Widget _beside() => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(child: second),
          ],
        ),
      );

  Widget _stacked() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[first, const SizedBox(height: HisaabSpacing.m), second],
      );
}
