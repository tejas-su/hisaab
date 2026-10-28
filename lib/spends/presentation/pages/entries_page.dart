import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/entries_bloc.dart';
import '../bloc/entries_event.dart';
import '../bloc/entries_state.dart';
import '../cycle_label.dart';
import '../widgets/entries_day.dart';

/// *Every entry* in one cycle, by day, with category chips (SPEC FR-SP-6).
///
/// Needs an [EntriesBloc] above it for [cycle]; [today] names it ("October"). [onEdit] opens
/// the Add tray on an entry. Swipe deletes with Undo, as on Home.
class EntriesPage extends StatelessWidget {
  const EntriesPage({super.key, required this.cycle, required this.today, required this.onEdit});

  final PayCycle cycle;
  final CalendarDate today;
  final ValueChanged<Entry> onEdit;

  /// How long Undo stays offered (SPEC BR-10).
  static const Duration undoWindow = Duration(seconds: 6);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: HisaabBackButton.leadingWidth,
        leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
        titleSpacing: HisaabSpacing.s,
        title: Text(strings.everyEntry),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<EntriesBloc, EntriesState>(
          listenWhen: (EntriesState previous, EntriesState current) => current is EntriesReady && current.undo.isSome(),
          listener: _offerUndo,
          builder: (BuildContext context, EntriesState state) => switch (state) {
            EntriesLoading() => const SizedBox.shrink(),
            EntriesFailed() => _failed(context),
            EntriesReady() => _list(context, state),
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, EntriesReady state) {
    final EntriesBloc bloc = context.read<EntriesBloc>();
    final List<(CalendarDate, List<Entry>)> days = state.days;
    return ListView.builder(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.xl),
      itemCount: days.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _top(context, state);
        }
        final (day, entries) = days[index - 1];
        return EntriesDay(
          key: ValueKey<CalendarDate>(day),
          day: day,
          entries: entries,
          categories: state.categories,
          onEdit: onEdit,
          onDelete: (Entry entry) => bloc.add(EntriesDeleteRequested(entry)),
          onThresholdReached: () => bloc.add(const EntriesSwipeThresholdReached()),
        );
      },
    );
  }

  Widget _top(BuildContext context, EntriesReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final EntriesBloc bloc = context.read<EntriesBloc>();
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(CycleLabel.of(cycle, locale: context.money.locale, today: today), style: text.titleLarge),
        const SizedBox(height: HisaabSpacing.m),
        Wrap(
          spacing: HisaabSpacing.s,
          runSpacing: HisaabSpacing.s,
          children: <Widget>[
            HisaabChip(
              key: const ValueKey<String>('filter-all'),
              label: strings.allCategories,
              selected: state.filter.isNone(),
              onPressed: () => bloc.add(const EntriesFilterChanged(Option<int>.none())),
            ),
            for (final Category category in state.chips)
              HisaabChip(
                key: ValueKey<String>('filter-${category.key}'),
                label: category.labelIn(strings),
                selected: state.filter == Option<int>.of(category.id),
                onPressed: () => bloc.add(EntriesFilterChanged(Option<int>.of(category.id))),
              ),
          ],
        ),
        if (state.shown.isEmpty) ...<Widget>[
          const SizedBox(height: HisaabSpacing.l),
          Text(strings.noEntriesHere, style: text.bodyLarge?.copyWith(color: context.colors.ink2)),
        ],
      ],
    );
  }

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
          const SizedBox(height: HisaabSpacing.m),
          HisaabChip(label: strings.tryAgain, onPressed: () => context.read<EntriesBloc>().add(const EntriesLoadRequested())),
        ],
      ),
    );
  }

  static void _offerUndo(BuildContext context, EntriesState state) {
    final Entry? deleted = state is EntriesReady ? state.undo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final EntriesBloc bloc = context.read<EntriesBloc>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: undoWindow,
          content: Text(strings.entryDeleted(context.money.format(deleted.amount))),
          action: SnackBarAction(label: strings.undo, onPressed: () => bloc.add(EntriesUndoRequested(deleted))),
        ),
      );
  }
}
