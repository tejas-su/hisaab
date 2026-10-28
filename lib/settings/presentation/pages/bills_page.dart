import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/bills_bloc.dart';
import '../bloc/bills_event.dart';
import '../bloc/bills_state.dart';
import '../widgets/bills_list.dart';

/// Fixed bills (SPEC FR-SE-1): the list, Add a bill, tap to edit, swipe to delete with Undo.
///
/// Needs a [BillsBloc] above it. [onAdd] and [onEdit] open the bill editor.
class BillsPage extends StatelessWidget {
  const BillsPage({super.key, required this.onAdd, required this.onEdit});

  final VoidCallback onAdd;
  final ValueChanged<RecurringRule> onEdit;

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
        title: Text(strings.fixedBills),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<BillsBloc, BillsState>(
          listenWhen: (BillsState previous, BillsState current) => current is BillsReady && current.undo.isSome(),
          listener: _offerUndo,
          builder: (BuildContext context, BillsState state) => ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.xl),
            children: <Widget>[
              Text(strings.fixedBillsHint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2)),
              const SizedBox(height: HisaabSpacing.l),
              ..._content(context, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, BillsState state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillsBloc bloc = context.read<BillsBloc>();
    return switch (state) {
      BillsLoading() => const <Widget>[],
      BillsFailed() => <Widget>[
          Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
          const SizedBox(height: HisaabSpacing.m),
          Align(alignment: AlignmentDirectional.centerStart, child: HisaabChip(label: strings.tryAgain, onPressed: () => bloc.add(const BillsLoadRequested()))),
        ],
      BillsReady(:final List<RecurringRule> bills) => <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: HisaabChip(key: const ValueKey<String>('add-bill'), label: strings.addBill, icon: AppIcons.add, onPressed: onAdd),
          ),
          const SizedBox(height: HisaabSpacing.l),
          if (bills.isEmpty)
            Text(strings.noBills, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2))
          else
            BillsList(bills: bills, onEdit: onEdit, onDelete: (RecurringRule bill) => bloc.add(BillsDeleteRequested(bill)),
              onThresholdReached: () => bloc.add(const BillsSwipeThresholdReached()),
            ),
        ],
    };
  }

  static void _offerUndo(BuildContext context, BillsState state) {
    final RecurringRule? deleted = state is BillsReady ? state.undo.toNullable() : null;
    if (deleted == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillsBloc bloc = context.read<BillsBloc>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: undoWindow,
          content: Text(strings.billDeleted(deleted.label)),
          action: SnackBarAction(label: strings.undo, onPressed: () => bloc.add(BillsUndoRequested(deleted))),
        ),
      );
  }
}
