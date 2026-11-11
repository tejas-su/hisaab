import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'limit_bar_painter.dart';

/// The one-line key under *Where it went* that says what a hatched bar means (FR-SP-4, BR-12).
///
/// It describes how the bar looks, so it is hidden from TalkBack: each hatched row already says
/// "past limit" in words.
class HatchKey extends StatelessWidget {
  const HatchKey({super.key});

  static const Size _swatch = Size(22, 12);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(
          children: <Widget>[
            CustomPaint(
              size: _swatch,
              painter: LimitBarPainter(
                fill: 1,
                limitAt: 0,
                ink: context.colors.ink,
                track: context.colors.sunk,
                notch: context.colors.surface,
                tick: context.colors.surface,
              ),
            ),
            const SizedBox(width: HisaabSpacing.s),
            Expanded(
              child: Text(AppLocalizations.of(context).hatchKey, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      );
}
