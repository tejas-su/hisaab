import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../core/widgets/top_bar_scroll_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_words.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/due_soon_row.dart';
import '../widgets/waiting_bill_row.dart';
import '../widgets/hero_card.dart';
import '../widgets/hero_skeleton.dart';
import '../widgets/home_header.dart';
import '../widgets/no_income_card.dart';
import '../widgets/over_card.dart';
import '../widgets/saved_yesterday_note.dart';
import '../widgets/today_list.dart';

/// Home: how much is safe to spend today, the Day Blocks and today's entries (SPEC FR-HO).
///
/// Needs a [HomeBloc] above it. [onAdd] opens the Add tray (on *Got* for "Add money"),
/// [onEdit] opens it on an entry, [onOpenSettings] opens Settings, and [onOpenBill] opens the
/// due-soon bill's sheet (D118), and [onEnterBill] the amount sheet of a bill waiting for its amount
/// (D123). [onSeeAll] opens the
/// cycle's entries (FR-HO-4) and [onSeeWhereItWent] shows Spends (FR-HO-5); each is hidden when
/// null.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenSettings,
    required this.onOpenBill,
    required this.onEnterBill,
    this.onSeeAll,
    this.onSeeWhereItWent,
    this.assemble = false,
  });

  final ValueChanged<EntryKind> onAdd;
  final ValueChanged<Entry> onEdit;
  final VoidCallback onOpenSettings;
  final ValueChanged<RecurringRule> onOpenBill;
  final ValueChanged<Occurrence> onEnterBill;
  final ValueChanged<PayCycle>? onSeeAll;
  final VoidCallback? onSeeWhereItWent;

  /// Plays the blocks-assemble entrance (after onboarding).
  final bool assemble;

  @override
  // why: the dock or the Add key sits right below Home, and its own top padding is the gap.
  Widget build(BuildContext context) => HisaabSnackbarHost(
        bottom: 0,
        child: MultiBlocListener(
          listeners: <BlocListener<HomeBloc, HomeState>>[
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (HomeState previous, HomeState current) => current is HomeReady && current.billUndo.isSome(),
              listener: _offerBillUndo,
            ),
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (HomeState previous, HomeState current) => current is HomeReady && current.amountUndo.isSome(),
              listener: _offerAmountUndo,
            ),
          ],
          child: BlocConsumer<HomeBloc, HomeState>(
            listenWhen: (HomeState previous, HomeState current) => current is HomeReady && current.undo.isSome(),
            listener: _offerUndo,
            builder: (BuildContext context, HomeState state) => TopBarScrollView(
              bar: HomeHeader(today: _today(state), onOpenSettings: onOpenSettings),
              children: _content(context, state),
            ),
          ),
        ),
      );

  static CalendarDate? _today(HomeState state) => state is HomeReady ? state.summary.today : null;

  List<Widget> _content(BuildContext context, HomeState state) => switch (state) {
        HomeLoading() => const <Widget>[HeroSkeleton()],
        HomeFailed() => <Widget>[_failed(context)],
        HomeReady(:final CycleSummary summary) when summary.state is NoIncome => <Widget>[
            NoIncomeCard(onAddMoney: () => onAdd(EntryKind.got)),
            ..._nudge(state),
            const SizedBox(height: HisaabSpacing.m),
            _todayList(context, state),
          ],
        HomeReady(:final CycleSummary summary) => <Widget>[
            HeroCard(
              summary: summary,
              spends: state.todaySpends,
              categories: state.categories,
              week: state.showWeek,
              onTap: () => context.read<HomeBloc>().add(const HomeWeekToggled()),
              assemble: assemble,
            ),
            if (OverCard.appliesTo(summary)) ...<Widget>[
              const SizedBox(height: HisaabSpacing.m),
              OverCard(summary: summary, onSeeWhereItWent: onSeeWhereItWent),
            ],
            ..._savedYesterday(summary),
            ..._nudge(state),
            const SizedBox(height: HisaabSpacing.m),
            _todayList(context, state),
          ],
      };

  static List<Widget> _savedYesterday(CycleSummary summary) => summary.savedYesterday.match(
        () => const <Widget>[],
        (YesterdaySaving saving) => <Widget>[
          const SizedBox(height: HisaabSpacing.m),
          SavedYesterdayNote(saving: saving),
        ],
      );

  // why: a bill already gone out and waiting for its amount matters more than one still to come
  // (spec §5 Home, D123), so it takes the one nudge slot first.
  List<Widget> _nudge(HomeReady state) {
    final Occurrence? waiting = state.summary.waitingBills.firstOrNull;
    if (waiting != null) {
      return <Widget>[
        const SizedBox(height: HisaabSpacing.m),
        WaitingBillRow(occurrence: waiting, today: state.summary.today, onTap: () => onEnterBill(waiting)),
      ];
    }
    return state.dueSoon.match(
      () => const <Widget>[],
      (DueSoonBill bill) => <Widget>[
        const SizedBox(height: HisaabSpacing.m),
        DueSoonRow(bill: bill, onOpenBill: onOpenBill),
      ],
    );
  }

  Widget _todayList(BuildContext context, HomeReady state) {
    final HomeBloc bloc = context.read<HomeBloc>();
    return TodayList(
      entries: state.todayEntries,
      categories: state.categories,
      spentToday: state.summary.spentToday,
      onSeeAll: _seeAll(state.summary.cycle),
      onEdit: onEdit,
      onDelete: (Entry entry) => bloc.add(HomeDeleteRequested(entry)),
      onThresholdReached: () => bloc.add(const HomeSwipeThresholdReached()),
    );
  }

  VoidCallback? _seeAll(PayCycle cycle) {
    final ValueChanged<PayCycle>? open = onSeeAll;
    return open == null ? null : () => open(cycle);
  }

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.m),
        HisaabChip(label: strings.tryAgain, onPressed: () => context.read<HomeBloc>().add(const HomeLoadRequested())),
      ],
    );
  }

  static void _offerBillUndo(BuildContext context, HomeState state) {
    final RecurringRule? deleted = state is HomeReady ? state.billUndo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeBloc bloc = context.read<HomeBloc>();
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: strings.ruleDeleted(deleted),
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(HomeBillUndoRequested(deleted))),
      ),
    );
  }

  static void _offerAmountUndo(BuildContext context, HomeState state) {
    final BillAmountOutcome? outcome = state is HomeReady ? state.amountUndo.toNullable() : null;
    if (outcome == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeBloc bloc = context.read<HomeBloc>();
    final (String message, String spoken) = switch (outcome) {
      BillAmountWasEntered(:final BillAmountEntered entered) => (
          strings.billAmountAdded(entered.previous.label, context.money.format(entered.entry.amount)),
          strings.billAmountAdded(entered.previous.label, strings.spokenAmount(context.money.digits(entered.entry.amount))),
        ),
      BillAmountWasSkipped(:final Occurrence occurrence) => (strings.billSkipped(occurrence.rule.label), strings.billSkipped(occurrence.rule.label)),
    };
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: message,
        semanticsLabel: spoken,
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(HomeBillAmountUndoRequested(outcome))),
      ),
    );
  }

  static void _offerUndo(BuildContext context, HomeState state) {
    final Entry? deleted = state is HomeReady ? state.undo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeBloc bloc = context.read<HomeBloc>();
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: strings.entryRemoved(deleted, context.money.format(deleted.amount)),
        semanticsLabel: strings.entryRemoved(deleted, strings.spokenAmount(context.money.digits(deleted.amount))),
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(HomeUndoRequested(deleted))),
      ),
    );
  }
}

