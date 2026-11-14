import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../habits/habits.dart';
import '../bloc/home_lines_bloc.dart';
import '../bloc/home_lines_event.dart';
import '../bloc/home_lines_state.dart';
import 'missed_log_probe.dart';
import 'missed_log_row.dart';

/// The nudge slot's lowest item: the missed-log line when [HomeLinesBloc] holds one, else
/// nothing (SPEC FR-HO-3). Needs a [HomeLinesBloc] and a `HomeBloc` above it.
///
/// A tap calls [onTap] with the habit; the bloc guards a second tap. The slot collapses over the
/// `resize` token; with reduced motion the line fades in 150 ms and the height follows at once.
class MissedLogSlot extends StatelessWidget {
  /// Creates the slot; [onTap] opens the Add tray carrying the habit.
  const MissedLogSlot({super.key, required this.onTap});

  final ValueChanged<MissedLog> onTap;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = HisaabMotion.reduceMotion(context);
    return BlocBuilder<HomeLinesBloc, HomeLinesState>(
      buildWhen: (HomeLinesState previous, HomeLinesState current) =>
          previous.missed != current.missed || previous.serial != current.serial,
      builder: (BuildContext context, HomeLinesState state) {
        final Widget line = AnimatedSwitcher(
          duration: reduceMotion ? HisaabMotion.reducedCrossfade : Duration.zero,
          child: state.missed.match(
            () => const SizedBox(width: double.infinity),
            (MissedLog line) => Padding(
              key: ValueKey<int>(state.serial),
              padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
              child: MissedLogProbe(key: ValueKey<int>(state.serial), child: MissedLogRow(line: line, onTap: () => _tap(context, line))),
            ),
          ),
        );
        // why: AnimatedSize asserts with a zero duration, and reduced motion wants the height at once.
        return reduceMotion
            ? line
            : AnimatedSize(alignment: AlignmentDirectional.topStart, duration: HisaabMotion.resize, curve: HisaabMotion.easeOut, child: line);
      },
    );
  }

  void _tap(BuildContext context, MissedLog line) {
    final HomeLinesBloc bloc = context.read<HomeLinesBloc>();
    if (bloc.state.tapped) {
      return;
    }
    bloc.add(const HomeLinesTapped());
    onTap(line);
  }
}
