import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/hero_card.dart';
import '../widgets/hero_skeleton.dart';
import '../widgets/home_header.dart';
import '../widgets/no_income_card.dart';
import '../widgets/today_list.dart';

/// Home: how much is safe to spend today, the Day Blocks and today's entries (SPEC FR-HO).
///
/// Needs a [HomeCubit] above it. [onAdd] opens the Add tray (on *Got* for "Add money"),
/// [onEdit] opens it on an entry, and [onOpenSettings] opens Settings.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenSettings,
    this.assemble = false,
  });

  final ValueChanged<EntryKind> onAdd;
  final ValueChanged<Entry> onEdit;
  final VoidCallback onOpenSettings;

  /// Plays the blocks-assemble entrance (after onboarding).
  final bool assemble;

  /// How long Undo stays offered (SPEC BR-10).
  static const Duration undoWindow = Duration(seconds: 6);

  @override
  Widget build(BuildContext context) => BlocConsumer<HomeCubit, HomeState>(
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
            const SizedBox(height: HisaabSpacing.m),
            _todayList(context, state),
          ],
        HomeReady(:final CycleSummary summary) => <Widget>[
            HeroCard(summary: summary, assemble: assemble),
            const SizedBox(height: HisaabSpacing.m),
            _todayList(context, state),
          ],
      };

  Widget _todayList(BuildContext context, HomeReady state) {
    final HomeCubit cubit = context.read<HomeCubit>();
    return TodayList(
      entries: state.todayEntries,
      categories: state.categories,
      spentToday: state.summary.spentToday,
      onEdit: onEdit,
      onDelete: cubit.delete,
      onThresholdReached: cubit.swipeThresholdReached,
    );
  }

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.m),
        HisaabChip(label: strings.tryAgain, onPressed: context.read<HomeCubit>().load),
      ],
    );
  }

  static void _offerUndo(BuildContext context, HomeState state) {
    final Entry? deleted = state is HomeReady ? state.undo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeCubit cubit = context.read<HomeCubit>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: undoWindow,
          content: Text(strings.entryDeleted(context.money.format(deleted.amount))),
          action: SnackBarAction(label: strings.undo, onPressed: () => cubit.undo(deleted)),
        ),
      );
  }
}

