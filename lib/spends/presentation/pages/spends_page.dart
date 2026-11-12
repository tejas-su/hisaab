import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/top_bar_scroll_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_spend.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/spends_overview.dart';
import '../bloc/spends_bloc.dart';
import '../bloc/spends_event.dart';
import '../bloc/spends_state.dart';
import '../cycle_label.dart';
import '../widgets/ask_ai_card.dart';
import '../widgets/cycle_switcher.dart';
import '../widgets/insights_card.dart';
import '../widgets/pace_card.dart';
import '../widgets/spends_card.dart';
import '../widgets/spends_empty_illustration.dart';
import '../widgets/spent_saved_line.dart';
import '../widgets/where_it_went_card.dart';

/// Spends: where a cycle's money went, its pace and a few insights (SPEC FR-SP).
///
/// Needs a [SpendsBloc] above it. [today] names cycles; [onSeeEntries] opens a cycle's
/// entries, optionally for one category (FR-SP-6); [onAskAi] opens Ask AI for a cycle (FR-SP-2).
class SpendsPage extends StatelessWidget {
  const SpendsPage({super.key, required this.today, required this.onSeeEntries, required this.onAskAi});

  final CalendarDate today;
  final void Function(PayCycle cycle, Option<int> categoryId) onSeeEntries;
  final ValueChanged<PayCycle> onAskAi;

  @override
  Widget build(BuildContext context) => BlocBuilder<SpendsBloc, SpendsState>(
        builder: (BuildContext context, SpendsState state) => TopBarScrollView(
          bar: _header(context, state),
          fill: switch (state) {
            SpendsReady(:final SpendsOverview overview) when overview.isEmpty => const SpendsEmptyIllustration(),
            _ => null,
          },
          children: _content(context, state),
        ),
      );

  Widget _header(BuildContext context, SpendsState state) {
    final SpendsBloc bloc = context.read<SpendsBloc>();
    return Row(
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
    );
  }

  List<Widget> _content(BuildContext context, SpendsState state) => switch (state) {
        SpendsLoading() => const <Widget>[],
        SpendsFailed() => <Widget>[_failed(context)],
        SpendsReady(:final SpendsOverview overview) when overview.isEmpty => <Widget>[
            _nothingSpent(context, overview),
          ],
        SpendsReady(:final SpendsOverview overview, :final bool limitsFailed) => <Widget>[
            AskAiCard(
              key: const ValueKey<String>('ask-ai-card'),
              cycleLabel: _label(context, overview.cycle),
              onPressed: () => onAskAi(overview.cycle),
            ),
            const SizedBox(height: HisaabSpacing.m),
            PaceCard(spent: overview.spent, pace: overview.pace, cycle: overview.cycle, showToday: overview.isCurrent),
            const SizedBox(height: HisaabSpacing.m),
            if (!overview.saved.isZero) ...<Widget>[
              SpentSavedLine(key: const ValueKey<String>('spent-saved'), spent: overview.spent, saved: overview.saved),
              const SizedBox(height: HisaabSpacing.s),
            ],
            WhereItWentCard(
              rows: overview.rows,
              cycleLabel: _label(context, overview.cycle),
              onSeeAll: () => onSeeEntries(overview.cycle, const Option<int>.none()),
            ),
            if (overview.insights.isNotEmpty) ...<Widget>[
              const SizedBox(height: HisaabSpacing.m),
              InsightsCard(
                insights: overview.insights,
                categories: <int, Category>{for (final CategorySpend row in overview.rows) row.category.id: row.category},
                previousCycle: _label(context, overview.previous),
                onSeeEntries: (int categoryId) => onSeeEntries(overview.cycle, Option<int>.of(categoryId)),
                onUseLimits: (LimitOffer offer) => context.read<SpendsBloc>().add(SpendsLimitsAccepted(offer)),
                limitsFailed: limitsFailed,
              ),
            ],
          ],
      };

  /// The empty state: one sentence in one card, with no link (D151).
  Widget _nothingSpent(BuildContext context, SpendsOverview overview) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SpendsCard(
      child: Text(
        strings.nothingSpentIn(_label(context, overview.cycle), overview.isCurrent ? 'current' : 'past'),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2),
      ),
    );
  }

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
