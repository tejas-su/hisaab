import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_lines_bloc.dart';
import '../bloc/home_lines_event.dart';
import '../bloc/home_lines_state.dart';
import '../bloc/home_state.dart';
import 'install_line_row.dart';
import 'missed_log_probe.dart';

/// The nudge slot's install item: the one-time "Already spent some this month?" line when
/// [HomeLinesBloc] holds it, else nothing (SPEC FR-HO-3). Needs a [HomeLinesBloc] and a [HomeBloc]
/// above it.
///
/// A tap calls [onTap]; the bloc guards a second tap. The slot collapses over the `resize` token; with
/// reduced motion the line fades in 150 ms and the height follows at once.
class InstallLineSlot extends StatelessWidget {
  const InstallLineSlot({super.key, required this.onTap});

  /// Opens the *Fix my number* sheet.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = HisaabMotion.reduceMotion(context);
    return BlocBuilder<HomeLinesBloc, HomeLinesState>(
      buildWhen: (HomeLinesState previous, HomeLinesState current) =>
          previous.install != current.install || previous.serial != current.serial,
      builder: (BuildContext context, HomeLinesState state) {
        final Widget line = AnimatedSwitcher(
          duration: reduceMotion ? HisaabMotion.reducedCrossfade : Duration.zero,
          child: state.install
              ? Padding(
                  key: ValueKey<int>(state.serial),
                  padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
                  child: MissedLogProbe(
                    key: ValueKey<int>(state.serial),
                    event: const HomeLinesInstallShown(),
                    child: InstallLineRow(period: _period(context), onTap: () => _tap(context)),
                  ),
                )
              : const SizedBox(width: double.infinity),
        );
        // why: AnimatedSize asserts with a zero duration, and reduced motion wants the height at once.
        return reduceMotion
            ? line
            : AnimatedSize(alignment: AlignmentDirectional.topStart, duration: HisaabMotion.resize, curve: HisaabMotion.easeOut, child: line);
      },
    );
  }

  static String _period(BuildContext context) {
    final HomeState home = context.read<HomeBloc>().state;
    return home is HomeReady && home.summary.cycle.isWeek ? 'week' : 'month';
  }

  void _tap(BuildContext context) {
    final HomeLinesBloc bloc = context.read<HomeLinesBloc>();
    if (bloc.state.tapped) {
      return;
    }
    bloc.add(const HomeLinesInstallTapped());
    onTap();
  }
}
