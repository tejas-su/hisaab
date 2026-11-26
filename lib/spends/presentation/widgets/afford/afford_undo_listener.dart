import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/hisaab_snackbar.dart';
import '../../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/afford_undo_bloc.dart';
import '../../bloc/afford_undo_event.dart';
import '../../bloc/afford_undo_state.dart';

/// Shows "Saving ₹5,000 a month for Mac" with *Undo* (4 s) after *Start saving*, and announces
/// "Undone." once it is undone (SPEC FR-SP-9 AC-6), or "Couldn't save. Try again." when the
/// Undo could not be written (E164).
///
/// Needs an [AffordUndoBloc] and a [HisaabSnackbarHost] above it, so it sits inside Spends' own
/// host, like `FixUndoListener` in Settings (D179).
class AffordUndoListener extends StatelessWidget {
  const AffordUndoListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AffordUndoBloc, AffordUndoState>(listener: _onState, child: child);

  static void _onState(BuildContext context, AffordUndoState state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    switch (state) {
      case AffordUndoIdle():
        return;
      case AffordUndoFailed():
        HisaabSnackbarHost.of(context).show(HisaabSnackbar(message: strings.couldntSave));
      case AffordUndoDone():
        SemanticsService.sendAnnouncement(View.of(context), strings.undone, Directionality.of(context));
      case AffordUndoShown(:final started):
        final AffordUndoBloc bloc = context.read<AffordUndoBloc>();
        HisaabSnackbarHost.of(context).show(
          HisaabSnackbar(
            message: strings.affordSavingStarted(context.money.format(started.rule.amount), started.rule.label),
            semanticsLabel: strings.affordSavingStarted(strings.spokenAmount(context.money.digits(started.rule.amount)), started.rule.label),
            action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(AffordUndoRequested(started))),
          ),
        );
    }
  }
}
