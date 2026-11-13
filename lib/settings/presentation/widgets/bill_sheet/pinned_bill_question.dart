import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/hisaab_back_button.dart';
import '../../../../core/widgets/pinned_keypad_body.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'bill_head.dart';
import 'bill_slip.dart';

/// A bill-sheet keypad question that keeps its typed amount, keypad and action key on screen:
/// Back, the [question], the bill's [name] and [caption] scroll above a slip holding the
/// [figure], then [controls] (SPEC FR-SE-1 AC-3; see [PinnedKeypadBody]).
///
/// [slot] is an optional line under the caption, such as what a change does. When [saveFailed],
/// "Couldn't save. Try again." shows with them (AC-7).
class PinnedBillQuestion extends StatelessWidget {
  const PinnedBillQuestion({
    super.key,
    required this.question,
    required this.name,
    required this.glyph,
    required this.figure,
    required this.caption,
    required this.controls,
    this.slot,
    this.saveFailed = false,
    this.figureExtent = defaultFigureExtent,
  });

  final String question;
  final String name;
  final AppIconData glyph;
  final Widget figure;
  final String caption;
  final Widget? slot;
  final bool saveFailed;

  /// The slip and figure's height at 1x text; raise it when the figure carries more than the amount.
  final double figureExtent;
  final Widget Function(BuildContext context, double keyHeight) controls;

  /// The slip's paper and torn edge around the figure; fixed, it does not grow with text.
  static const double slipChrome = 18 + 14 + 8;

  /// The typed amount's height at 1x text.
  static const double amountExtent = 58;

  // why: the slip's paper and torn edge around the figure, plus the figure itself, at 1x text.
  static const double defaultFigureExtent = slipChrome + amountExtent;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget? extra = slot;
    return PinnedKeypadBody(
      figureExtent: figureExtent,
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const HisaabBackButton(),
              const SizedBox(width: HisaabSpacing.s),
              Expanded(
                child: Semantics(header: true, child: Text(question, style: text.titleLarge)),
              ),
            ],
          ),
          const SizedBox(height: HisaabSpacing.s),
          BillHead(name: name, glyph: glyph),
          const SizedBox(height: HisaabSpacing.s),
          Text(caption, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
          if (extra != null) ...<Widget>[const SizedBox(height: HisaabSpacing.s), extra],
          if (saveFailed) ...<Widget>[
            const SizedBox(height: HisaabSpacing.s),
            Semantics(liveRegion: true, child: Text(AppLocalizations.of(context).couldntSave, style: text.titleMedium)),
          ],
          const SizedBox(height: HisaabSpacing.s),
        ],
      ),
      figure: BillSlip(child: figure),
      controls: controls,
    );
  }
}
