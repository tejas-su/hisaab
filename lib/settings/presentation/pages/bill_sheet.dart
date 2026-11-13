import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../bloc/bill_sheet_bloc.dart';
import '../bloc/bill_sheet_event.dart';
import '../bloc/bill_sheet_state.dart';
import '../bloc/used_bloc.dart';
import '../bloc/used_state.dart';
import '../widgets/bill_sheet/bill_amount_question.dart';
import '../widgets/bill_sheet/bill_day_question.dart';
import '../widgets/bill_sheet/bill_icon_question.dart';
import '../widgets/bill_sheet/bill_mode_question.dart';
import '../widgets/bill_sheet/bill_name_question.dart';
import '../widgets/bill_sheet/bill_summary.dart';
import '../widgets/bill_sheet/used_question.dart';
import '../widgets/bill_sheet/used_sheet_link.dart';

/// The bill sheet: one fixed bill drawn as a paper bill, changed one answer at a time
/// (SPEC FR-SE-1, D118). Open it with [show].
///
/// Back from a question returns to the bill; Back, a swipe down or the scrim on the bill
/// closes it (AC-5).
class BillSheet extends StatefulWidget {
  const BillSheet({super.key});

  /// How long "Saved." stays in the footer after a save (AC-4).
  static const Duration savedNote = Duration(milliseconds: 2400);

  /// The window height under which the 48dp drag handle is not drawn; swipe, scrim and Back still
  /// close the sheet (FR-KS-1 AC-5, D180).
  static const double _handleMinHeight = 600;

  /// Opens the sheet for [bloc]'s bill over [context]; the sheet closes [bloc] when it goes.
  ///
  /// With a [used] bloc a saving's sheet can open the *Used some of it* question; the sheet closes
  /// [used] once it is done, after waiting for a write still in flight, so Back during a save keeps
  /// its Undo (AC-Y9).
  ///
  /// Completes after the exit animation with what the sheet did: [BillSheetUsed] after a *Used*
  /// save, [BillSheetDeleted] for the caller to delete with Undo, [BillSheetChanged] after any save,
  /// else [BillSheetUnchanged].
  static Future<BillSheetOutcome> show(BuildContext context, BillSheetBloc bloc, {UsedBloc? used}) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext _) => BlocProvider<BillSheetBloc>(
        create: (BuildContext _) => bloc,
        child: used == null
            ? const BillSheet()
            : BlocProvider<UsedBloc>.value(value: used, child: const UsedSheetLink(child: BillSheet())),
      ),
    );
    unawaited(Navigator.of(context).push(route));
    await route.completed;
    final BillSheetOutcome closed = switch (bloc.state) {
      BillSheetClosed(:final BillSheetOutcome outcome) => outcome,
      final BillSheetReady ready => ready.outcome,
    };
    return used == null ? closed : _withUsed(used, closed);
  }

  // why: Back during a save closes the sheet, but the write still lands; waiting for it keeps its Undo.
  static Future<BillSheetOutcome> _withUsed(UsedBloc used, BillSheetOutcome closed) async {
    final UsedState last = _settled(used.state) ? used.state : await used.stream.firstWhere(_settled);
    unawaited(used.close());
    return last is UsedDone ? BillSheetUsed(last.outcome) : closed;
  }

  static bool _settled(UsedState state) => state is! UsedReady || !state.writing;

  /// The bottom-sheet route the bill sheet rises in, shared with the *Put in extra* sheet (D120):
  /// [builder] builds its body. Its `completed` waits for the exit animation to end.
  static ModalBottomSheetRoute<void> route(BuildContext context, {required WidgetBuilder builder}) {
    final bool tabletop = context.layout.panes is TabletopPanes;
    final NavigatorState navigator = Navigator.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    // why: as AddEntryTray.show, the route's `completed` waits for the exit to end.
    return ModalBottomSheetRoute<void>(
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      isScrollControlled: true,
      useSafeArea: true,
      anchorPoint: tabletop ? Offset(0, MediaQuery.sizeOf(context).height) : null,
      backgroundColor: context.colors.background,
      modalBarrierColor: context.colors.scrim,
      shape: HisaabShapes.trayTop(),
      constraints: const BoxConstraints(maxWidth: AdaptiveSplit.readableWidth),
      showDragHandle: !tabletop && MediaQuery.sizeOf(context).height >= _handleMinHeight,
      builder: builder,
    );
  }

  @override
  State<BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends State<BillSheet> {
  Timer? _savedNote;

  @override
  void dispose() {
    _savedNote?.cancel();
    super.dispose();
  }

  void _onState(BuildContext context, BillSheetState state) {
    if (state is BillSheetClosed) {
      Navigator.of(context).pop();
      return;
    }
    if (state is BillSheetReady && state.justSaved.isSome()) {
      final BillSheetBloc bloc = context.read<BillSheetBloc>();
      _savedNote?.cancel();
      _savedNote = Timer(BillSheet.savedNote, () => bloc.add(const BillSheetSavedNoteExpired()));
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<BillSheetBloc, BillSheetState>(
        listenWhen: (BillSheetState previous, BillSheetState current) =>
            current is BillSheetClosed ||
            (current is BillSheetReady && previous is BillSheetReady && current.justSaved != previous.justSaved),
        listener: _onState,
        buildWhen: (BillSheetState _, BillSheetState current) => current is BillSheetReady,
        builder: (BuildContext context, BillSheetState state) {
          if (state is! BillSheetReady) {
            return const SizedBox.shrink();
          }
          return PopScope(
            canPop: state.open.isNone(),
            onPopInvokedWithResult: (bool didPop, Object? _) {
              if (!didPop) {
                context.read<BillSheetBloc>().add(const BillSheetBackPressed());
              }
            },
            child: AnimatedSwitcher(
              duration: HisaabMotion.reduceMotion(context) ? HisaabMotion.reducedCrossfade : HisaabMotion.numberRoll,
              child: KeyedSubtree(key: ValueKey<Option<BillAnswer>>(state.open), child: _body(context, state)),
            ),
          );
        },
      );

  // why: the amount question pins its keypad and scrolls only its lead (P2), so it brings its own
  // padding and scroll; every other question scrolls whole, clear of the keyboard and the system bar.
  static Widget _body(BuildContext context, BillSheetReady state) {
    if (state.open.toNullable() == BillAnswer.amount || state.open.toNullable() == BillAnswer.used) {
      return _view(state);
    }
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        HisaabSpacing.gutter,
        0,
        HisaabSpacing.gutter,
        HisaabSpacing.gutter + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: _view(state),
    );
  }

  static Widget _view(BillSheetReady state) => switch (state.open.toNullable()) {
        null => BillSummary(state: state),
        BillAnswer.amount => BillAmountQuestion(state: state),
        BillAnswer.day => BillDayQuestion(state: state),
        BillAnswer.name => BillNameQuestion(state: state),
        BillAnswer.icon => BillIconQuestion(state: state),
        BillAnswer.mode => BillModeQuestion(state: state),
        BillAnswer.used => UsedQuestion(rule: state.rule),
      };
}
