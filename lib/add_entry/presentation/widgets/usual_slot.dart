import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../habits/habits.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'spend_preview_line.dart';
import 'usual_pill.dart';

/// The slot under the amount on step 1: the *your usual* pill at ₹0, the preview after any
/// input, never both (SPEC FR-AD-1, FR-AD-3, FR-AD-10; UI_DESIGN §5.3).
///
/// It is at least [height] tall whatever it holds, so the pill coming or going moves nothing;
/// only a preview that wraps at large text makes it taller. A tap on the pill adds
/// [AddEntryUsualPicked] to the [AddEntryBloc] above it.
class UsualSlot extends StatelessWidget {
  /// Shows what [state] offers: its form's usual, else its preview.
  const UsualSlot({super.key, required this.state});

  /// The tray's state; the pill is `ink` while it saves and says so when the save failed.
  final AddEntryState state;

  /// The slot's least height, which is also the pill's tap target.
  static const double height = HisaabSizes.minTouchTarget;

  @override
  Widget build(BuildContext context) {
    final AddEntryState current = state;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: Center(
        heightFactor: 1,
        // why: FR-AD-10 AC-3 names a 150ms crossfade, which is also the reduced-motion
        // transition, so one duration serves both.
        child: AnimatedSwitcher(
          duration: HisaabMotion.reducedCrossfade,
          child: current.form.usual.match(
            () => SpendPreviewLine(key: const ValueKey<String>('usual-slot-preview'), preview: current.form.preview),
            (UsualSpend usual) => UsualPill(
              key: const ValueKey<String>('usual-pill'),
              usual: usual,
              filled: current is AddEntrySaving || current is AddEntryFinished,
              failed: current is AddEntryEditing && current.failed,
              onPressed: () => context.read<AddEntryBloc>().add(const AddEntryUsualPicked()),
            ),
          ),
        ),
      ),
    );
  }
}
