import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_glyph.dart';
import '../../../ledger/presentation/rule_words.dart';

/// Home's "How much?" line for a changing or card bill waiting for its amount (D123): the bill's
/// glyph, "Electricity went out today. How much?" and a chevron, in the due-soon row's place and
/// shape. A tap opens the bill amount sheet.
class WaitingBillRow extends StatelessWidget {
  const WaitingBillRow({super.key, required this.occurrence, required this.today, required this.onTap});

  final Occurrence occurrence;
  final CalendarDate today;
  final VoidCallback onTap;

  static const double _minHeight = 56;
  static const double _radius = 18;

  // why: the same start inset as the due-soon row, so the glyph lands on the hero's content inset.
  static const double _startInset = HisaabSpacing.m;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final DateTime due = DateTime(occurrence.date.year, occurrence.date.month, occurrence.date.day);
    final String date = DateFormat('d MMM', Localizations.localeOf(context).toString()).format(due);
    final String line = strings.ruleWaiting(occurrence.rule, date, isToday: occurrence.date == today);
    return Pressable(
      semanticLabel: line,
      semanticHint: strings.waitingOpensHint,
      focusRadius: _radius,
      onPressed: onTap,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsetsDirectional.fromSTEB(_startInset, HisaabSpacing.s, HisaabSpacing.m, HisaabSpacing.s),
        decoration: ShapeDecoration(
          color: pressed ? context.colors.hairline : context.colors.sunk,
          shape: HisaabShapes.squircle(_radius),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.chip)),
              child: AppIcon(occurrence.rule.glyph),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(child: Text(line, style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(width: HisaabSpacing.s),
            AppIcon(AppIcons.next, size: 18, color: context.colors.ink2),
          ],
        ),
      ),
    );
  }
}
