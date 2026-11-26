import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/reached_line.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_lines_bloc.dart';
import '../bloc/home_lines_event.dart';
import '../bloc/home_lines_state.dart';
import '../bloc/home_state.dart';
import 'missed_log_probe.dart';
import 'reached_line_row.dart';

/// The nudge slot's reached item: "Insurance reached ₹12,000." when [HomeLinesBloc] holds it, else
/// nothing (SPEC FR-HO-3, BR-23). Needs a [HomeLinesBloc] and a [HomeBloc] above it.
///
/// Once on screen with nothing over Home it is written as shown (AC-R2). A tap calls [onOpenBill]
/// with the saving as Home last loaded it, so the sheet opens on its current name and columns; the
/// line stays (AC-R5). The slot collapses over the `resize` token; with reduced motion the line
/// fades in 150 ms and the height follows at once.
class ReachedLineSlot extends StatelessWidget {
  const ReachedLineSlot({super.key, required this.onOpenBill});

  /// Opens the saving's sheet over Home.
  final ValueChanged<RecurringRule> onOpenBill;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = HisaabMotion.reduceMotion(context);
    return BlocBuilder<HomeLinesBloc, HomeLinesState>(
      buildWhen: (HomeLinesState previous, HomeLinesState current) =>
          previous.reached != current.reached || previous.serial != current.serial,
      builder: (BuildContext context, HomeLinesState state) {
        final Widget line = AnimatedSwitcher(
          duration: reduceMotion ? HisaabMotion.reducedCrossfade : Duration.zero,
          child: state.reached.match(
            () => const SizedBox(width: double.infinity),
            (ReachedLine reached) => Padding(
              key: ValueKey<int>(state.serial),
              padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
              child: MissedLogProbe(
                key: ValueKey<int>(state.serial),
                event: const HomeLinesReachedShown(),
                child: BlocSelector<HomeBloc, HomeState, RecurringRule>(
                  selector: (HomeState home) => _current(home, reached.saving),
                  builder: (BuildContext context, RecurringRule saving) =>
                      ReachedLineRow(saving: saving, target: reached.target, onTap: () => _tap(context, saving)),
                ),
              ),
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

  // why: the line keeps the rule from its evaluation point; Home's latest load has its current name
  // (A8) and the columns the line itself wrote, which the sheet must not write back stale.
  static RecurringRule _current(HomeState home, RecurringRule decided) => switch (home) {
        HomeReady(:final Option<ReachedLine> reachedLine) => reachedLine
            .filter((ReachedLine latest) => latest.saving.id == decided.id)
            .map((ReachedLine latest) => latest.saving)
            .getOrElse(() => decided),
        HomeLoading() || HomeFailed() => decided,
      };

  void _tap(BuildContext context, RecurringRule saving) {
    context.read<HomeLinesBloc>().add(const HomeLinesReachedTapped());
    onOpenBill(saving);
  }
}
