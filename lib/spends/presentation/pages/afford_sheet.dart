import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../settings/settings.dart';
import '../../domain/entities/saving_started.dart';
import '../afford_copy.dart';
import '../bloc/afford_bloc.dart';
import '../bloc/afford_event.dart';
import '../bloc/afford_state.dart';
import '../widgets/afford/afford_answer_view.dart';
import '../widgets/afford/afford_have_step.dart';
import '../widgets/afford/afford_header.dart';
import '../widgets/afford/afford_item_step.dart';

/// The *Can I afford it?* sheet over Spends (SPEC BR-24, FR-SP-9): what and how much, what is
/// saved for it, then the answer. Open it with [show].
///
/// Back, system back and Escape step back one step and close it from step 1; the draft is dropped
/// on close with no prompt (AC-7). It stores nothing unless *Start saving* is tapped.
class AffordSheet extends StatelessWidget {
  const AffordSheet({super.key});

  /// The sheet's route name, so a *Can I afford it?* shortcut tap can keep an open check (E167).
  static const String routeName = 'afford-sheet';

  /// Opens the sheet for [bloc] over [context] in the bill sheet's route and closes [bloc] once it
  /// is done. Completes after the exit animation with the saving *Start saving* wrote, or [None]
  /// when it closed without one; pass it to `AffordUndoBloc` as `AffordUndoOffered` so Spends
  /// offers Undo (AC-6).
  static Future<Option<SavingStarted>> show(BuildContext context, AffordBloc bloc) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext _) => BlocProvider<AffordBloc>.value(value: bloc, child: const AffordSheet()),
      settings: const RouteSettings(name: routeName),
      // why: no paper slip here, so the sheet itself is the raised layer (UI_DESIGN §3).
      raised: true,
    );
    await Navigator.of(context).push(route);
    await route.completed;
    // why: closed during a save, the write still lands; waiting for it keeps its Undo (as E86).
    final AffordState last = _settled(bloc.state) ? bloc.state : await bloc.stream.firstWhere(_settled);
    unawaited(bloc.close());
    return last is AffordSavingStarted ? Option<SavingStarted>.of(last.started) : const Option<SavingStarted>.none();
  }

  static bool _settled(AffordState state) => state is! AffordAnswered || !state.saving;

  @override
  Widget build(BuildContext context) => BlocConsumer<AffordBloc, AffordState>(
        listenWhen: (AffordState previous, AffordState current) =>
            current is AffordSavingStarted || current is AffordClosed || (current is AffordAnswered && previous is! AffordAnswered),
        listener: _onState,
        buildWhen: (AffordState _, AffordState current) => current is! AffordSavingStarted && current is! AffordClosed,
        builder: (BuildContext context, AffordState state) => PopScope(
          // why: Back steps back one step; only step 1 lets the route go (AC-7).
          canPop: state is AffordItemStep,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              context.read<AffordBloc>().add(const AffordBackPressed());
            }
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _header(context, state),
                Flexible(child: _body(context, state)),
              ],
            ),
          ),
        ),
      );

  // why: TalkBack hears the answer once as it appears, since focus stays on the key that asked
  // for it (AC-9); opening and closing Other ways doesn't repeat it.
  static void _onState(BuildContext context, AffordState state) {
    if (state is AffordAnswered) {
      final String answer = AffordCopy.spokenAnswer(state, AppLocalizations.of(context), context.money);
      SemanticsService.sendAnnouncement(View.of(context), answer, Directionality.of(context));
      return;
    }
    Navigator.of(context).pop();
  }

  static Widget _header(BuildContext context, AffordState state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (state is AffordItemStep) {
      return AffordHeader(title: strings.affordTitle, spokenTitle: strings.affordTitle);
    }
    final String name = state.draft.name.trim();
    return AffordHeader(
      title: strings.affordHeading(name, context.money.format(state.draft.priceMoney)),
      spokenTitle: strings.affordHeadingSpoken(name, strings.spokenAmount(context.money.digits(state.draft.priceMoney))),
      showsItem: true,
    );
  }

  static Widget _body(BuildContext context, AffordState state) => switch (state) {
        AffordItemStep(:final AffordDraft draft) => AffordItemStepView(draft: draft),
        AffordHaveStep(:final AffordDraft draft) => AffordHaveStepView(draft: draft),
        AffordAnswered() => AffordAnswerView(state: state),
        AffordFailed() => Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.gutter),
            child: Text(AppLocalizations.of(context).loadFailed, style: Theme.of(context).textTheme.bodyLarge),
          ),
        AffordLoading() || AffordSavingStarted() || AffordClosed() => const SizedBox(height: HisaabSizes.minTouchTarget),
      };
}
