import 'package:flutter/gestures.dart' show PointerEnterEvent, PointerExitEvent;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../habits/habits.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The missed-log line in Home's nudge slot, as a tappable `sunk` row: a neutral question glyph,
/// "Spent on Food today?", "Usually around 1 pm." and a chevron (SPEC FR-HO-3, D171). A tap
/// opens the Add tray carrying the habit. It shows no amount, has no ×, and is never marigold.
class MissedLogRow extends StatefulWidget {
  /// Creates the row for [line]; [onTap] opens the Add tray.
  const MissedLogRow({super.key, required this.line, required this.onTap});

  final MissedLog line;
  final VoidCallback onTap;

  static const double _minHeight = 56;
  static const double _radius = 18;

  // why: the row spans the hero card's width and its well's glyph lands on the card's content
  // inset, as the due-soon row's does.
  static const double _startInset = HisaabSpacing.m;

  @override
  State<MissedLogRow> createState() => _MissedLogRowState();
}

class _MissedLogRowState extends State<MissedLogRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String title = strings.missedLogTitle(widget.line.category.labelIn(strings));
    final String body = strings.missedLogBody(UsualWords.hourWord(widget.line.aroundHour, Localizations.localeOf(context).toString()));
    return MouseRegion(
      onEnter: (PointerEnterEvent _) => setState(() => _hovered = true),
      onExit: (PointerExitEvent _) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (bool focused) => setState(() => _focused = focused),
        child: Pressable(
          semanticLabel: '$title $body',
          semanticHint: strings.waitingOpensHint,
          focusRadius: MissedLogRow._radius,
          onPressed: widget.onTap,
          builder: (BuildContext context, bool pressed) => Container(
            constraints: const BoxConstraints(minHeight: MissedLogRow._minHeight),
            padding: const EdgeInsetsDirectional.fromSTEB(
              MissedLogRow._startInset,
              HisaabSpacing.s,
              HisaabSpacing.m,
              HisaabSpacing.s,
            ),
            decoration: ShapeDecoration(
              color: pressed ? context.colors.hairline : context.colors.sunk,
              shape: HisaabShapes.squircle(
                MissedLogRow._radius,
                side: _hovered || _focused ? BorderSide(color: context.colors.ink2) : BorderSide.none,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: HisaabSizes.iconWell,
                  height: HisaabSizes.iconWell,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.chip)),
                  // why: never the category's glyph: a Today row is "category glyph, name, amount",
                  // and this one would read as a logged entry.
                  child: const AppIcon(AppIcons.questionLine),
                ),
                const SizedBox(width: HisaabSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: text.bodyMedium),
                      Text(body, style: text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: HisaabSpacing.s),
                AppIcon(AppIcons.next, size: 18, color: context.colors.ink2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
