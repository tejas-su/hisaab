import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/today_bar/today_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../today_bar_mapper.dart';

/// The hero's *Today* chart: today's bar, then "₹420 spent" and "of ₹1,850 for today" under it
/// (SPEC BR-6, FR-HO-2).
///
/// [spends] are today's *Spent* entries, oldest first; [categories] name their bites.
class HeroTodayRows extends StatelessWidget {
  const HeroTodayRows({super.key, required this.summary, required this.spends, required this.categories});

  final CycleSummary summary;
  final List<Entry> spends;
  final Map<int, Category> categories;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? caption = HisaabType.regular(Theme.of(context).textTheme.labelSmall)?.copyWith(color: context.colors.displayInk2);
    String nameOf(Entry entry) => categories[entry.categoryId]?.labelIn(strings) ?? strings.categoryName('other');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TodayBar(
          // why: a new day gets a fresh bar that fills in again (D91).
          key: ValueKey<CalendarDate>(summary.today),
          data: TodayBarMapper.of(summary, spends, nameOf: nameOf),
          fillIn: true,
        ),
        const SizedBox(height: HisaabSpacing.xs),
        Row(
          children: <Widget>[
            Text(strings.todayBarSpent(context.money.format(summary.spentToday)), style: caption),
            const SizedBox(width: HisaabSpacing.s),
            Expanded(
              child: Text(strings.todayBarOfShare(context.money.format(summary.todayShare)), style: caption, textAlign: TextAlign.end),
            ),
          ],
        ),
      ],
    );
  }
}
