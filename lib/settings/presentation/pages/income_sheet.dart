import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../bloc/income_sheet_bloc.dart';
import '../bloc/income_sheet_event.dart';
import '../bloc/income_sheet_state.dart';
import '../widgets/income_sheet/income_amount_question.dart';
import '../widgets/income_sheet/income_day_question.dart';
import '../widgets/income_sheet/income_summary.dart';
import '../widgets/income_sheet/income_weekday_question.dart';
import '../widgets/income_sheet/income_when_question.dart';
import 'bill_sheet.dart';

/// The income sheet: the money coming in drawn as the bill sheet's paper slip, its amount changed
/// on the keypad and when it comes on onboarding's choices (SPEC FR-SE-1, D137, D140, mockup 32).
/// Open it with [show].
///
/// Back from a question returns one step; Back, a swipe down or the scrim on the slip closes it.
class IncomeSheet extends StatefulWidget {
  const IncomeSheet({super.key});

  /// Opens the sheet for [bloc]'s income over [context]; the sheet closes [bloc] when it goes.
  /// Completes after the exit animation.
  static Future<void> show(BuildContext context, IncomeSheetBloc bloc) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext _) => BlocProvider<IncomeSheetBloc>(create: (BuildContext _) => bloc, child: const IncomeSheet()),
    );
    unawaited(Navigator.of(context).push(route));
    await route.completed;
  }

  @override
  State<IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<IncomeSheet> {
  Timer? _savedNote;

  @override
  void dispose() {
    _savedNote?.cancel();
    super.dispose();
  }

  void _onState(BuildContext context, IncomeSheetState state) {
    if (state is IncomeSheetClosed) {
      Navigator.of(context).pop();
      return;
    }
    if (state is IncomeSheetReady && state.justSaved) {
      final IncomeSheetBloc bloc = context.read<IncomeSheetBloc>();
      _savedNote?.cancel();
      _savedNote = Timer(BillSheet.savedNote, () => bloc.add(const IncomeSheetSavedNoteExpired()));
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<IncomeSheetBloc, IncomeSheetState>(
        listenWhen: (IncomeSheetState previous, IncomeSheetState current) =>
            current is IncomeSheetClosed ||
            (current is IncomeSheetReady && previous is IncomeSheetReady && current.justSaved && !previous.justSaved),
        listener: _onState,
        buildWhen: (IncomeSheetState _, IncomeSheetState current) => current is IncomeSheetReady,
        builder: (BuildContext context, IncomeSheetState state) {
          if (state is! IncomeSheetReady) {
            return const SizedBox.shrink();
          }
          return PopScope(
            canPop: !state.amountOpen && state.step.isNone(),
            onPopInvokedWithResult: (bool didPop, Object? _) {
              if (!didPop) {
                context.read<IncomeSheetBloc>().add(const IncomeSheetBackPressed());
              }
            },
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                HisaabSpacing.gutter,
                0,
                HisaabSpacing.gutter,
                HisaabSpacing.gutter + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: AnimatedSwitcher(
                duration: HisaabMotion.reduceMotion(context) ? HisaabMotion.reducedCrossfade : HisaabMotion.numberRoll,
                child: KeyedSubtree(
                  key: ValueKey<(bool, IncomeWhenStep?)>((state.amountOpen, state.step.toNullable())),
                  child: _view(state),
                ),
              ),
            ),
          );
        },
      );

  static Widget _view(IncomeSheetReady state) {
    if (state.amountOpen) {
      return IncomeAmountQuestion(state: state);
    }
    return switch (state.step.toNullable()) {
      null => IncomeSummary(state: state),
      IncomeWhenStep.choices => IncomeWhenQuestion(state: state),
      IncomeWhenStep.day => IncomeDayQuestion(state: state),
      IncomeWhenStep.weekday => IncomeWeekdayQuestion(state: state),
    };
  }
}
