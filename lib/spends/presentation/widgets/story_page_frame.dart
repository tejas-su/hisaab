import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// One month story page (SPEC FR-SP-7): an eyebrow, a big line and the page's [children], scrolling
/// when taller than the window (AC-7). TalkBack reads it as one node, [spoken] (AC-5).
class StoryPageFrame extends StatelessWidget {
  const StoryPageFrame({
    super.key,
    required this.eyebrow,
    required this.big,
    required this.spoken,
    required this.children,
    this.bigIsAmount = true,
  });

  final String eyebrow;
  final String big;
  final String spoken;
  final List<Widget> children;

  /// An amount or a name is set in the display size; a sentence one step smaller.
  final bool bigIsAmount;

  /// From this text scale up, the big line steps down a size so nothing clips (AC-7).
  static const double _largeText = 1.5;

  @override
  Widget build(BuildContext context) {
    final TextTheme type = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(eyebrow, style: type.labelMedium?.copyWith(color: context.colors.ink2)),
            const SizedBox(height: HisaabSpacing.s),
            Text(big, style: _bigStyle(context, type)),
            const SizedBox(height: HisaabSpacing.l),
            ...children,
          ],
        ),
      ),
    );
  }

  TextStyle? _bigStyle(BuildContext context, TextTheme type) {
    final bool large = MediaQuery.textScalerOf(context).scale(1) >= _largeText;
    if (!bigIsAmount) {
      return large ? type.titleLarge : type.displaySmall;
    }
    return large ? type.displaySmall : type.displayMedium;
  }

  /// A plain body line in the story, `ink2` when [quiet].
  static Widget line(BuildContext context, String text, {bool quiet = false}) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.xs),
        child: Text(
          text,
          style: HisaabType.regular(Theme.of(context).textTheme.bodyLarge)?.copyWith(color: quiet ? context.colors.ink2 : context.colors.ink),
        ),
      );
}
