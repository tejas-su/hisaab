import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../spends_graph_copy.dart';

/// One comparison against the cycle before, with its arrow: the pace card's line (FR-SP-3a) and an
/// opened row's change (FR-SP-4 AC-R2). Words carry it; the arrow is never read, and there is no
/// colour. The parent reads [words]' spoken form.
class ComparisonLine extends StatelessWidget {
  const ComparisonLine({super.key, required this.words, this.small = false});

  final ComparisonWords words;

  /// `bodySmall` for a row's change; `bodyMedium` for the pace card.
  final bool small;

  static const double _arrowSize = 16;

  @override
  Widget build(BuildContext context) {
    final TextTheme type = Theme.of(context).textTheme;
    final AppIconData? arrow = words.arrow;
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (arrow != null) ...<Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: AppIcon(arrow, size: _arrowSize, color: context.colors.ink2),
            ),
            const SizedBox(width: HisaabSpacing.xs),
          ],
          Expanded(child: Text(words.shown, style: (small ? type.bodySmall : type.bodyMedium)?.copyWith(color: context.colors.ink))),
        ],
      ),
    );
  }
}
