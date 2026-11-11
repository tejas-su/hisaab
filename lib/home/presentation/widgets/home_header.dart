import 'package:material_ui/material_ui.dart';
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

  static const double _wellMargin = (HisaabSizes.minTouchTarget - HisaabSizes.iconWell) / 2;

  @override
  Widget build(BuildContext context) {
    final CalendarDate? day = today;
    final String settings = AppLocalizations.of(context).settings;
    return Row(
      children: <Widget>[
        // why: a loose Flexible next to an Expanded leaves its unused share empty at the row's
        // end, pushing Settings off the cards' edge; both shrinkable parts share one Expanded.
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // why: at the largest text sizes the row is wider than a small phone; scale, don't clip.
              const Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Wordmark()),
              ),
              if (day != null) ...<Widget>[
                const SizedBox(width: HisaabSpacing.m),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      DateFormat('EEE, d MMM', Localizations.localeOf(context).toString())
                          .format(DateTime(day.year, day.month, day.day)),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.colors.ink2, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: HisaabSpacing.m),
        Pressable(
          key: const ValueKey<String>('open-settings'),
          semanticLabel: settings,
          onPressed: onOpenSettings,
          // why: the ring hugs the visible well, which sits at the end of the 48dp target.
          focusInset: const EdgeInsetsDirectional.only(start: 2 * _wellMargin, top: _wellMargin, bottom: _wellMargin),
          // why: the well is smaller than the tap area so it doesn't outweigh the wordmark; it sits
          // at the end so its visible edge stays flush with the cards.
          builder: (BuildContext context, bool pressed) => Container(
            width: HisaabSizes.minTouchTarget,
            height: HisaabSizes.minTouchTarget,
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              key: const ValueKey<String>('open-settings-well'),
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: pressed ? context.colors.sunk : context.colors.control,
                shape: HisaabShapes.squircle(HisaabRadii.chip),
              ),
              child: const AppIcon(AppIcons.settings),
            ),
          ),
        ),
      ],
    );
  }
}
