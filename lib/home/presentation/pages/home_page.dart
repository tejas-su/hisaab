import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/due_soon_note.dart';
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
/// [onEdit] opens it on an entry, and [onOpenSettings] opens Settings. [onSeeAll] opens the
/// cycle's entries (FR-HO-4) and [onSeeWhereItWent] shows Spends (FR-HO-5); each is hidden when
/// null.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenSettings,
    this.onSeeAll,
    this.onSeeWhereItWent,
    this.assemble = false,
  });

  final ValueChanged<EntryKind> onAdd;
  final ValueChanged<Entry> onEdit;
  final VoidCallback onOpenSettings;
  final ValueChanged<PayCycle>? onSeeAll;
  final VoidCallback? onSeeWhereItWent;

  /// Plays the blocks-assemble entrance (after onboarding).
  final bool assemble;

  /// How long Undo stays offered (SPEC BR-10).
  static const Duration undoWindow = Duration(seconds: 6);

  @override
  Widget build(BuildContext context) => BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (HomeState previous, HomeState current) => current is HomeReady && current.undo.isSome(),
        listener: _offerUndo,
        builder: (BuildContext context, HomeState state) => ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.xl),
          children: <Widget>[
            HomeHeader(today: _today(state), onOpenSettings: onOpenSettings),
            const SizedBox(height: 14),
            ..._content(context, state),
          ],
        ),
      );

  static CalendarDate? _today(HomeState state) => state is HomeReady ? state.summary.today : null;

  List<Widget> _content(BuildContext context, HomeState state) => switch (state) {
        HomeLoading() => const <Widget>[HeroSkeleton()],
        HomeFailed() => <Widget>[_failed(context)],
        HomeReady(:final CycleSummary summary) when summary.state is NoIncome => <Widget>[
            NoIncomeCard(onAddMoney: () => onAdd(EntryKind.got)),
            ..._dueSoon(state),
            const SizedBox(height: HisaabSpacing.m),
            _todayList(context, state),
          ],
        HomeReady(:final CycleSummary summary) => <Widget>[
            HeroCard(
              summary: summary,
              week: state.showWeek,
              onTap: () => context.read<HomeBloc>().add(const HomeWeekToggled()),
              assemble: assemble,
            ),
            if (OverCard.appliesTo(summary)) ...<Widget>[
              const SizedBox(height: HisaabSpacing.m),
              OverCard(summary: summary, onSeeWhereItWent: onSeeWhereItWent),
            ],
            ..._savedYesterday(summary),
            ..._dueSoon(state),
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

  static List<Widget> _dueSoon(HomeReady state) => state.dueSoon.match(
        () => const <Widget>[],
        (DueSoonBill bill) => <Widget>[const SizedBox(height: HisaabSpacing.m), DueSoonNote(bill: bill)],
      );

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

  static void _offerUndo(BuildContext context, HomeState state) {
    final Entry? deleted = state is HomeReady ? state.undo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeBloc bloc = context.read<HomeBloc>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: undoWindow,
          content: Text(strings.entryDeleted(context.money.format(deleted.amount))),
          action: SnackBarAction(label: strings.undo, onPressed: () => bloc.add(HomeUndoRequested(deleted))),
        ),
      );
  }
}

