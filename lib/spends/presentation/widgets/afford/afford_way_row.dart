import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../afford_copy.dart';

/// One *Other ways* row: its [glyph], its title in bold (ending "· suggested" for the suggested
/// way) and its one line, read by TalkBack as one line (SPEC FR-SP-9 AC-5, AC-9).
class AffordWayRow extends StatelessWidget {
  const AffordWayRow({super.key, required this.way, required this.spokenLine, required this.glyph});

  final AffordWay way;

  /// [way]'s line with its amounts spoken.
  final String spokenLine;
  final AppIconData glyph;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      label: '${way.title}. $spokenLine',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppIcon(glyph, color: context.colors.ink2),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(way.title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(way.line, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
