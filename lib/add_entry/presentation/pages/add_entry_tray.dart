import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import '../widgets/amount_step.dart';
import '../widgets/category_step.dart';

/// The Add tray: amount, then category; tapping a tile saves and the tray drops (SPEC FR-AD).
///
/// Open it with [show]. Back on step 2 returns to step 1 with the amount kept; back on step 1
/// closes without saving (FR-AD-7).
class AddEntryTray extends StatelessWidget {
  const AddEntryTray({super.key});

  /// Space left above the tray on step 1, so the hero stays in sight behind the scrim.
  static const double _gapAbove = 72;

  /// Opens the tray over [context] with [bloc], which the tray closes when it goes away.
  ///
  /// Completes once the tray's exit animation has ended, not when it starts to close, so Home
  /// can hold its drain until it's in view (FR-AD-5).
  ///
  /// On a tabletop fold the sheet keeps to the lower half (Flutter's sheets never straddle a
  /// fold), so the hero stays readable above it and the keypad sits on the flat half.
  static Future<void> show(BuildContext context, AddEntryBloc bloc) {
    final bool tabletop = context.layout.panes is TabletopPanes;
    final NavigatorState navigator = Navigator.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    // why: showModalBottomSheet's future completes as the exit starts; the route's `completed`
    // waits for the exit to end. These are showModalBottomSheet's own arguments.
    final ModalBottomSheetRoute<void> route = ModalBottomSheetRoute<void>(
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      isScrollControlled: true,
      useSafeArea: true,
      anchorPoint: tabletop ? Offset(0, MediaQuery.sizeOf(context).height) : null,
      backgroundColor: context.colors.surface,
      modalBarrierColor: context.colors.ink.withValues(alpha: 0.32),
      shape: HisaabShapes.trayTop(),
      constraints: tabletop ? const BoxConstraints() : const BoxConstraints(maxWidth: AdaptiveSplit.readableWidth),
      showDragHandle: !tabletop,
      builder: (BuildContext _) => BlocProvider<AddEntryBloc>(create: (BuildContext _) => bloc, child: const AddEntryTray()),
    );
    navigator.push(route);
    return route.completed;
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AddEntryBloc, AddEntryState>(
        listenWhen: (AddEntryState previous, AddEntryState current) => current is AddEntryFinished,
        listener: (BuildContext context, AddEntryState state) => Navigator.of(context).pop(),
        builder: (BuildContext context, AddEntryState state) => PopScope(
          canPop: state.form.step == AddEntryStep.amount,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              context.read<AddEntryBloc>().add(const AddEntryBackPressed());
            }
          },
          child: Padding(
            padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: AnimatedSize(
              duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.numberRoll,
              curve: HisaabMotion.easeOut,
              alignment: Alignment.bottomCenter,
              child: _step(context, state),
            ),
          ),
        ),
      );

  Widget _step(BuildContext context, AddEntryState state) {
    if (state is AddEntryEditing && state.form.step == AddEntryStep.amount) {
      final PaneArrangement panes = context.layout.panes;
      final double height = panes is TabletopPanes
          ? panes.bottom.height - MediaQuery.paddingOf(context).bottom
          : MediaQuery.sizeOf(context).height - _gapAbove - HisaabSpacing.xxl;
      return SizedBox(height: height, child: AmountStep(state: state, sideBySide: panes is TabletopPanes));
    }
    return CategoryStep(state: state);
  }
}
