import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../../ledger/ledger.dart';
import '../../../settings/settings.dart';
import '../bloc/fix_bloc.dart';
import '../bloc/fix_event.dart';
import '../bloc/fix_state.dart';
import '../widgets/fix_keypad_body.dart';

/// The *Fix my number* sheet: the user types how much of this cycle's money is left and *Fix it*
/// adds one *Not logged* entry for the difference (SPEC FR-FX). Open it with [show].
///
/// It rises in the bill sheet's route. Back, system back and Escape step back from the guard like
/// *No*; on the keypad they close the sheet, and so do the handle, a swipe down and the scrim, with
/// nothing posted (FR-FX-4 AC-4).
class FixSheet extends StatelessWidget {
  const FixSheet({super.key});

  /// Opens the sheet for [bloc] over [context] and closes [bloc] once it is done. Completes after
  /// the exit animation with what was posted, or [None] when it was closed without a fix.
  ///
  /// The caller adds [FixLoadRequested] to [bloc] first.
  static Future<Option<FixOutcome>> show(BuildContext context, FixBloc bloc) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext _) => BlocProvider<FixBloc>.value(value: bloc, child: const FixSheet()),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    // why: Back during a save closes the sheet, but the write still lands; waiting for it keeps its Undo (E86).
    final FixState last = _settled(bloc.state) ? bloc.state : await bloc.stream.firstWhere(_settled);
    unawaited(bloc.close());
    return last is FixDone ? Option<FixOutcome>.of(last.outcome) : const Option<FixOutcome>.none();
  }

  static bool _settled(FixState state) => state is! FixReady || !state.saving;

  @override
  Widget build(BuildContext context) => BlocConsumer<FixBloc, FixState>(
        listenWhen: (FixState _, FixState current) => current is FixDone,
        listener: (BuildContext context, FixState _) => Navigator.of(context).pop(),
        builder: (BuildContext context, FixState state) => PopScope(
          // why: from the guard, back steps back to the keypad like No; a second back closes (FR-FX-4 AC-4).
          canPop: !(state is FixReady && state.guard.isSome()),
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              context.read<FixBloc>().add(const FixBackPressed());
            }
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
            },
            child: FixKeypadBody(state: state),
          ),
        ),
      );
}
