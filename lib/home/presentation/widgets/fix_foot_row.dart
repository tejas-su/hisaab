import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// "Fix my number": the quiet last row of Home's scroll, below the Today list and *See all* (SPEC
/// FR-HO-9). Plain `ink2` text on the page: no fill, no icon well, no second line and no count, so it
/// is a door and never a nudge. A tap opens the keypad sheet through [onTap].
class FixFootRow extends StatelessWidget {
  const FixFootRow({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _minHeight = HisaabSizes.minTouchTarget;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
      child: Pressable(
        semanticLabel: strings.fixMyNumber,
        semanticHint: strings.waitingOpensHint,
        onPressed: onTap,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: const BoxConstraints(minHeight: _minHeight),
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
          child: Text(strings.fixMyNumber, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2)),
        ),
      ),
    );
  }
}
