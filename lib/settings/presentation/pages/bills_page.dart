import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_words.dart';
import '../bloc/bills_bloc.dart';
import '../bloc/bills_event.dart';
import '../bloc/bills_state.dart';
import '../widgets/bills_list.dart';
import '../widgets/rule_list_actions.dart';

/// Fixed bills, or Savings when [kind] is *Saved* (SPEC FR-SE-1, D120): the list, tap to open
/// the sheet, swipe to delete with Undo, and Add pinned to the bottom in thumb reach (D136).
/// Savings add the "put in" total and *Put in extra*. The list and key share one 560dp column.
///
/// Needs a [BillsBloc] above it. [onAdd] opens the editor, [onEdit] the sheet, and
/// [onPutInExtra] the *Put in extra* keypad (savings only; hidden when null).
class BillsPage extends StatelessWidget {
  const BillsPage({
    super.key,
    required this.onAdd,
    required this.onEdit,
    this.kind = EntryKind.spent,
    this.onPutInExtra,
  });

  final VoidCallback onAdd;
  final ValueChanged<RecurringRule> onEdit;
  final EntryKind kind;
  final VoidCallback? onPutInExtra;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: HisaabBackButton.leadingWidth,
        leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
        titleSpacing: HisaabSpacing.s,
        title: Text(strings.ruleListTitle(kind)),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LayoutBreakpoints.singlePaneMaxWidth),
            child: BlocBuilder<BillsBloc, BillsState>(
              builder: (BuildContext context, BillsState state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _undoAboveActions(_list(context, state))),
                  if (state is BillsReady)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        HisaabSpacing.gutter,
                        HisaabSpacing.s,
                        HisaabSpacing.gutter,
                        HisaabSpacing.l,
                      ),
                      child: RuleListActions(kind: kind, onAdd: onAdd, onPutInExtra: onPutInExtra),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, BillsState state) => ListView(
    padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.l),
    children: <Widget>[
      Text(
        AppLocalizations.of(context).ruleListHint(kind),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
      ),
      const SizedBox(height: HisaabSpacing.l),
      ..._content(context, state),
    ],
  );

  // why: the host wraps only the list, so the Undo bar rises right above the pinned key and never
  // covers it; the key's own top padding is the gap. Undo exists only once the list is ready.
  Widget _undoAboveActions(Widget list) => HisaabSnackbarHost(
    bottom: 0,
    child: BlocListener<BillsBloc, BillsState>(
      listenWhen: (BillsState previous, BillsState current) => current is BillsReady && current.undo.isSome(),
      listener: _offerUndo,
      child: list,
    ),
  );

  List<Widget> _content(BuildContext context, BillsState state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillsBloc bloc = context.read<BillsBloc>();
    return switch (state) {
      BillsLoading() => const <Widget>[],
      BillsFailed() => <Widget>[
        Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: HisaabChip(label: strings.tryAgain, onPressed: () => bloc.add(const BillsLoadRequested())),
        ),
      ],
      BillsReady(:final List<RecurringRule> bills, :final Option<SavedTotal> saved) => <Widget>[
        if (bills.isEmpty)
          Text(strings.ruleNone(kind), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2))
        else
          BillsList(
            bills: bills,
            onEdit: onEdit,
            onDelete: (RecurringRule bill) => bloc.add(BillsDeleteRequested(bill)),
            onThresholdReached: () => bloc.add(const BillsSwipeThresholdReached()),
          ),
        if (saved case Some<SavedTotal>(:final SavedTotal value)) ...<Widget>[
          const SizedBox(height: HisaabSpacing.m),
          Text(
            strings.savedSince(context.money.format(value.total), _month(context, value.since)),
            key: const ValueKey<String>('saved-since'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
          ),
        ],
      ],
    };
  }

  // why: the footer names only the month the first saving went in ("since Oct", spec §5).
  static String _month(BuildContext context, CalendarDate since) =>
      DateFormat('MMM', Localizations.localeOf(context).toString()).format(DateTime(since.year, since.month));

  static void _offerUndo(BuildContext context, BillsState state) {
    final RecurringRule? deleted = state is BillsReady ? state.undo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillsBloc bloc = context.read<BillsBloc>();
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: strings.ruleDeleted(deleted),
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(BillsUndoRequested(deleted))),
      ),
    );
  }
}
