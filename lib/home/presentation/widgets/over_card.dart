import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The calm card under the hero in the over states: what happens now, and one next step
/// (SPEC FR-HO-5). [onSeeWhereItWent] is null when Spends is already on screen beside Home.
class OverCard extends StatelessWidget {
  const OverCard({super.key, required this.summary, required this.onSeeWhereItWent});

  final CycleSummary summary;
  final VoidCallback? onSeeWhereItWent;

  /// Whether [summary] is in an over state, so the card has something to say.
  static bool appliesTo(CycleSummary summary) => summary.state is OverToday || summary.state is OverCycle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final VoidCallback? seeWhereItWent = onSeeWhereItWent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
      decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_words(context, strings), style: Theme.of(context).textTheme.bodyLarge),
          if (seeWhereItWent != null) ...<Widget>[
            const SizedBox(height: HisaabSpacing.m),
            HisaabChip(
              key: const ValueKey<String>('see-where-it-went'),
              label: strings.seeWhereItWent,
              trailingIcon: AppIcons.next,
              onPressed: seeWhereItWent,
            ),
          ],
        ],
      ),
    );
  }

  String _words(BuildContext context, AppLocalizations strings) => switch (summary.state) {
        OverToday(:final over) => strings.overTodayCard(context.money.format(over), summary.daysLeft - 1),
        OverCycle() || NoIncome() || SlowDown() || OnTrack() => strings.overCycleCard(
            DateFormat('d MMM', context.money.locale)
                .format(DateTime(summary.payday.year, summary.payday.month, summary.payday.day)),
          ),
      };
}
