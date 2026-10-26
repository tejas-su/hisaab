import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../cubit/add_entry_cubit.dart';
import '../cubit/add_entry_state.dart';
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

  /// Opens the tray over [context] with [cubit], which the tray closes when it goes away.
  ///
  /// On a tabletop fold the sheet keeps to the lower half (Flutter's sheets never straddle a
  /// fold), so the hero stays readable above it and the keypad sits on the flat half.
  static Future<void> show(BuildContext context, AddEntryCubit cubit) {
    final bool tabletop = context.layout.panes is TabletopPanes;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      anchorPoint: tabletop ? Offset(0, MediaQuery.sizeOf(context).height) : null,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.ink.withValues(alpha: 0.32),
      shape: HisaabShapes.trayTop(),
      constraints: tabletop ? const BoxConstraints() : const BoxConstraints(maxWidth: AdaptiveSplit.readableWidth),
      showDragHandle: !tabletop,
      builder: (BuildContext _) => BlocProvider<AddEntryCubit>(create: (BuildContext _) => cubit, child: const AddEntryTray()),
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AddEntryCubit, AddEntryState>(
        listenWhen: (AddEntryState previous, AddEntryState current) => current is AddEntryFinished,
        listener: (BuildContext context, AddEntryState state) => Navigator.of(context).pop(),
        builder: (BuildContext context, AddEntryState state) => PopScope(
          canPop: state.form.step == AddEntryStep.amount,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              context.read<AddEntryCubit>().back();
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
