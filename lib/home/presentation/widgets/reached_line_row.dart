import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_glyph.dart';

/// The reached line in Home's nudge slot, as a tappable `sunk` row in the due-soon row's shape: the
/// saving's glyph in a `surface` well, "Insurance reached ₹12,000." and a chevron (SPEC FR-HO-3,
/// BR-23). A tap calls [onTap], which opens the saving's sheet.
///
/// It shows no amount but [target], has no ×, and is never marigold (AC-R6). TalkBack reads one
/// button with the spoken target, then "Opens the saving." (AC-R7). The name is never cut.
class ReachedLineRow extends StatelessWidget {
  const ReachedLineRow({super.key, required this.saving, required this.target, required this.onTap});

  final RecurringRule saving;

  /// The target that was reached.
  final Money target;
  final VoidCallback onTap;

  static const double _minHeight = 56;
  static const double _radius = 18;

  // why: the row spans the hero card's width and its well's glyph lands on the card's content
  // inset, as the due-soon row's does.
  static const double _startInset = HisaabSpacing.m;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Pressable(
      semanticLabel: strings.savingReachedLineSpoken(saving.label, strings.spokenAmount(context.money.digits(target))),
      semanticHint: strings.dueSoonOpensSaving,
      focusRadius: _radius,
      onPressed: onTap,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsetsDirectional.fromSTEB(_startInset, HisaabSpacing.s, HisaabSpacing.m, HisaabSpacing.s),
        decoration: ShapeDecoration(color: pressed ? context.colors.hairline : context.colors.sunk, shape: HisaabShapes.squircle(_radius)),
        child: Row(
          children: <Widget>[
            Container(
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.chip)),
              child: AppIcon(saving.glyph),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(
              child: Text(
                strings.savingReachedLine(saving.label, context.money.format(target)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: HisaabSpacing.s),
            AppIcon(AppIcons.next, size: 18, color: context.colors.ink2),
          ],
        ),
      ),
    );
  }
}
