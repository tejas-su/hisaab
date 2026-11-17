import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card_words.dart';

/// Acts on what a closing card hands back (SPEC BR-10, FR-AD-8 AC-9, AC-10): shows the edit's Undo
/// bar on the page's [HisaabSnackbarHost], and passes a Delete to [onDelete], which deletes with the
/// page's own Undo.
///
/// Place it below the page's snackbar host.
class EntryCardOutcomes extends StatelessWidget {
  const EntryCardOutcomes({super.key, required this.bloc, required this.onDelete, required this.child});

  final EntryCardBloc bloc;
  final ValueChanged<Entry> onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<EntryCardBloc, EntryCardState>(
        bloc: bloc,
        listenWhen: (EntryCardState previous, EntryCardState current) => current is EntryCardClosed && current != previous,
        listener: (BuildContext context, EntryCardState state) {
          if (state is! EntryCardClosed) {
            return;
          }
          state.deleted.map(onDelete);
          state.edit.map((EntryEdit edit) => _offerUndo(context, edit));
        },
        child: child,
      );

  void _offerUndo(BuildContext context, EntryEdit edit) {
    final AppLocalizations strings = AppLocalizations.of(context);
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: EntryCardWords.edit(
          context,
          edit,
          categories: edit.categories,
          today: edit.today,
          amount: (Entry entry) => context.money.format(entry.amount),
        ),
        action: HisaabSnackbarAction(
          label: strings.undo,
          onPressed: () {
            bloc.add(EntryCardUndoRequested(edit));
            SemanticsService.sendAnnouncement(View.of(context), strings.undone, Directionality.of(context));
          },
        ),
      ),
    );
  }
}
