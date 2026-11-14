import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/fix_undo_bloc.dart';
import '../bloc/fix_undo_event.dart';
import '../bloc/fix_undo_state.dart';

/// Shows the Undo of a fix made from Settings and announces "Undone." (SPEC FR-FX-5 AC-4, AC-5).
///
/// Needs a [FixUndoBloc] above it and a snackbar host above it, so it sits inside the Settings
/// page's own host: Home's host is under the Settings route and would never show it (D179).
class FixUndoListener extends StatelessWidget {
  const FixUndoListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<FixUndoBloc, FixUndoState>(
        listener: _onState,
        child: child,
      );

  static void _onState(BuildContext context, FixUndoState state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    switch (state) {
      case FixUndoIdle():
        return;
      case FixUndoDone():
        SemanticsService.sendAnnouncement(View.of(context), strings.undone, Directionality.of(context));
      case FixUndoShown(:final outcome):
        final FixUndoBloc bloc = context.read<FixUndoBloc>();
        HisaabSnackbarHost.of(context).show(
          HisaabSnackbar(
            message: strings.fixDone(context.money.format(outcome.safeToday)),
            semanticsLabel: strings.fixDone(strings.spokenAmount(context.money.digits(outcome.safeToday))),
            action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(FixUndoRequested(outcome))),
          ),
        );
    }
  }
}
