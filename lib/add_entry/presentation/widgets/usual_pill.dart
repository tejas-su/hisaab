import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_colors.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../habits/habits.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The *your usual* pill of the Add tray: "Chai ₹20 · your usual"; one tap saves it (SPEC
/// FR-AD-10, UI_DESIGN §5.3).
///
/// A fully round `sunk` capsule with no edge, like the chips, never marigold (D207). The
/// category icon sits in a round `surface` well at the start and a round `ink` add cap ends it,
/// so it reads as a button that adds. It is [height] tall and grows with the text up to
/// [maxHeight], inside a tap target of [maxHeight]. It keeps to one line: when the line doesn't
/// fit the width it gets, the "· your usual" tag drops; when it still doesn't fit, or the text is
/// taller than [maxHeight], nothing is built (AC-2).
class UsualPill extends StatelessWidget {
  /// Offers [usual]; [onPressed] runs on a tap, also to try again when [failed].
  const UsualPill({super.key, required this.usual, required this.onPressed, this.filled = false, this.failed = false});

  /// The category and amount a tap saves.
  final UsualSpend usual;

  /// Called on a tap, on Enter and on a screen reader's activate.
  final VoidCallback onPressed;

  /// Paints the pill `ink`, and its cap `surface` with a tick, while its save runs and the tray
  /// closes (AC-4).
  final bool filled;

  /// Shows "Couldn't save. Try again." in place of the offer (AC-4).
  final bool failed;

  /// The pill's height at the default text size.
  static const double height = HisaabSizes.iconWell;

  /// The tallest the pill grows to, and the height of its tap target: the slot's 48dp.
  static const double maxHeight = HisaabSizes.minTouchTarget;

  /// The well and the cap; 4dp inside the 40dp pill, so the pill stays 40dp and the 12dp gap
  /// to the chips holds (D153).
  static const double _circle = 32;
  static const double _iconSize = 20;
  static const double _capIconSize = 18;
  static const double _amountSize = 17;
  static const double _lineHeight = 20;

  /// What is drawn beside the text: the insets, the well, the cap and their gaps.
  static const double _chrome = 2 * HisaabSpacing.xs + 2 * _circle + 2 * HisaabSpacing.s;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double room = constraints.maxWidth - _chrome;
          final (InlineSpan, Size)? fit = _lines(context)
              .map((InlineSpan line) => (line, _measure(context, line)))
              .where(((InlineSpan, Size) tried) => tried.$2.width <= room && tried.$2.height <= maxHeight)
              .firstOrNull;
          return fit == null ? const SizedBox.shrink() : _pill(context, fit.$1, fit.$2.height);
        },
      );

  /// The lines to try, widest first: with the tag, then without it.
  List<InlineSpan> _lines(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    if (failed) {
      return <InlineSpan>[TextSpan(text: strings.couldntSave)];
    }
    final List<InlineSpan> offer = <InlineSpan>[
      TextSpan(text: '${usual.category.labelIn(strings)} '),
      TextSpan(
        text: context.money.format(usual.amount),
        style: text.titleLarge?.copyWith(
          fontSize: _amountSize,
          height: _lineHeight / _amountSize,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    ];
    final InlineSpan tag = TextSpan(
      text: '${strings.separator}${strings.usualTag}',
      style: HisaabType.regular(text.titleMedium)?.copyWith(color: filled ? null : context.colors.ink2),
    );
    return <InlineSpan>[
      TextSpan(children: <InlineSpan>[...offer, tag]),
      TextSpan(children: offer),
    ];
  }

  TextStyle? _style(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(color: filled ? context.colors.surface : context.colors.ink);

  Size _measure(BuildContext context, InlineSpan line) {
    final TextPainter painter = TextPainter(
      text: TextSpan(style: _style(context), children: <InlineSpan>[line]),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final Size size = painter.size;
    painter.dispose();
    return size;
  }

  Widget _pill(BuildContext context, InlineSpan line, double lineHeight) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HisaabColors colors = context.colors;
    final double pillHeight = math.min(maxHeight, math.max(height, lineHeight + HisaabSpacing.l));
    return Pressable(
      semanticLabel: failed
          ? strings.couldntSave
          : strings.usualSuggestionSpoken(
              usual.category.labelIn(strings),
              strings.spokenAmount(context.money.digits(usual.amount)),
            ),
      onPressed: onPressed,
      focusRadius: pillHeight / 2,
      focusInset: EdgeInsets.symmetric(vertical: (maxHeight - pillHeight) / 2),
      builder: (BuildContext context, bool _) => SizedBox(
        height: maxHeight,
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.press,
            height: pillHeight,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.xs),
            decoration: ShapeDecoration(color: filled ? colors.ink : colors.sunk, shape: const StadiumBorder()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _round(
                  const ValueKey<String>('usual-pill-well'),
                  colors.surface,
                  AppIcon(AppIcons.forKey(usual.category.iconKey), size: _iconSize, color: colors.ink),
                ),
                const SizedBox(width: HisaabSpacing.s),
                Text.rich(line, style: _style(context), maxLines: 1, softWrap: false),
                const SizedBox(width: HisaabSpacing.s),
                _round(
                  const ValueKey<String>('usual-pill-cap'),
                  filled ? colors.surface : colors.ink,
                  AppIcon(
                    filled ? AppIcons.check : AppIcons.add,
                    size: _capIconSize,
                    color: filled ? colors.ink : colors.surface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A [_circle]-wide round fill of [color] holding [icon]: the well and the cap.
  static Widget _round(Key key, Color color, Widget icon) => SizedBox.square(
        dimension: _circle,
        child: DecoratedBox(
          key: key,
          decoration: ShapeDecoration(color: color, shape: const CircleBorder()),
          child: Center(child: icon),
        ),
      );
}
