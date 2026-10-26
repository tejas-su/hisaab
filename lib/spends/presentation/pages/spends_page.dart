import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_spend.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/spends_overview.dart';
import '../bloc/spends_bloc.dart';
import '../bloc/spends_event.dart';
import '../bloc/spends_state.dart';
import '../cycle_label.dart';
import '../widgets/cycle_switcher.dart';
import '../widgets/insights_card.dart';
import '../widgets/pace_card.dart';
import '../widgets/spends_card.dart';
import '../widgets/where_it_went_card.dart';

/// Spends: where a cycle's money went, its pace and a few insights (SPEC FR-SP).
///
/// Needs a [SpendsBloc] above it. [today] names cycles; [onSeeEntries] opens a cycle's
/// entries, optionally for one category (FR-SP-6).
class SpendsPage extends StatelessWidget {
  const SpendsPage({super.key, required this.today, required this.onSeeEntries});

  final CalendarDate today;
  final void Function(PayCycle cycle, Option<int> categoryId) onSeeEntries;

  @override
  Widget build(BuildContext context) => BlocBuilder<SpendsBloc, SpendsState>(
        builder: (BuildContext context, SpendsState state) => ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.xl),
          children: <Widget>[
            _header(context, state),
            const SizedBox(height: 14),
            ..._content(context, state),
          ],
        ),
      );

  Widget _header(BuildContext context, SpendsState state) {
    final SpendsBloc bloc = context.read<SpendsBloc>();
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget + 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                header: true,
                child: Text(AppLocalizations.of(context).navSpends, style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),
          ),
          if (state case SpendsReady(:final SpendsOverview overview)) ...<Widget>[
            const SizedBox(width: HisaabSpacing.m),
            CycleSwitcher(
              label: _label(context, overview.cycle),
              onEarlier: overview.canGoBack ? () => bloc.add(const SpendsEarlierPressed()) : null,
              onLater: overview.isCurrent ? null : () => bloc.add(const SpendsLaterPressed()),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, SpendsState state) => switch (state) {
        SpendsLoading() => const <Widget>[],
        SpendsFailed() => <Widget>[_failed(context)],
        SpendsReady(:final SpendsOverview overview) when overview.isEmpty => <Widget>[
            SpendsCard(
              child: Text(
                AppLocalizations.of(context).nothingSpentIn(_label(context, overview.cycle)),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2),
              ),
            ),
            ..._seeEveryEntry(context, overview),
          ],
        SpendsReady(:final SpendsOverview overview, :final bool limitsFailed) => <Widget>[
            PaceCard(spent: overview.spent, pace: overview.pace, showToday: overview.isCurrent),
            const SizedBox(height: HisaabSpacing.m),
            WhereItWentCard(rows: overview.rows),
            if (overview.insights.isNotEmpty) ...<Widget>[
              const SizedBox(height: HisaabSpacing.m),
              InsightsCard(
                insights: overview.insights,
                categories: <int, Category>{for (final CategorySpend row in overview.rows) row.category.id: row.category},
                onSeeEntries: (int categoryId) => onSeeEntries(overview.cycle, Option<int>.of(categoryId)),
                onUseLimits: (LimitOffer offer) => context.read<SpendsBloc>().add(SpendsLimitsAccepted(offer)),
                limitsFailed: limitsFailed,
              ),
            ],
            ..._seeEveryEntry(context, overview),
          ],
      };

  List<Widget> _seeEveryEntry(BuildContext context, SpendsOverview overview) => <Widget>[
        const SizedBox(height: HisaabSpacing.l),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: HisaabChip(
            key: const ValueKey<String>('see-every-entry'),
            label: AppLocalizations.of(context).seeEveryEntry,
            trailingIcon: AppIcons.next,
            onPressed: () => onSeeEntries(overview.cycle, const Option<int>.none()),
          ),
        ),
      ];

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.m),
        HisaabChip(label: strings.tryAgain, onPressed: () => context.read<SpendsBloc>().add(const SpendsLoadRequested())),
      ],
    );
  }

  String _label(BuildContext context, PayCycle cycle) =>
      CycleLabel.of(cycle, locale: Localizations.localeOf(context).toString(), today: today);
}
