import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/wordmark.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Home's top row: the wordmark, today's date ("Mon, 26 Oct") and Settings (SPEC FR-HO-1).
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.today, required this.onOpenSettings});

  /// Null while loading; the date is left out.
  final CalendarDate? today;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final CalendarDate? day = today;
    final String settings = AppLocalizations.of(context).settings;
    return Row(
      children: <Widget>[
        // why: at the largest text sizes the row is wider than a small phone; scale, don't clip.
        const Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Wordmark()),
        ),
        const SizedBox(width: HisaabSpacing.m),
        Expanded(
          child: day == null
              ? const SizedBox.shrink()
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    DateFormat('EEE, d MMM', Localizations.localeOf(context).toString())
                        .format(DateTime(day.year, day.month, day.day)),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.colors.ink2, fontSize: 15),
                  ),
                ),
        ),
        const SizedBox(width: HisaabSpacing.m),
        Pressable(
          key: const ValueKey<String>('open-settings'),
          semanticLabel: settings,
          onPressed: onOpenSettings,
          builder: (BuildContext context, bool pressed) => Container(
            width: HisaabSizes.minTouchTarget,
            height: HisaabSizes.minTouchTarget,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: pressed ? context.colors.hairline : context.colors.sunk,
              shape: HisaabShapes.squircle(14),
            ),
            child: const AppIcon(AppIcons.settings),
          ),
        ),
      ],
    );
  }
}
