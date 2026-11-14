import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:material_ui/material_ui.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../habits/habits.dart';
import '../../../ledger/ledger.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_lines_bloc.dart';
import '../bloc/home_lines_event.dart';
import '../bloc/home_lines_state.dart';
import '../bloc/home_state.dart';
import 'home_heading_focus.dart';
import 'over_card.dart';

/// Feeds [HomeLinesBloc] from Home and the habits, which Blocs may not do between themselves
/// (SPEC FR-HO-3, D170). Needs a [HomeBloc], a [HabitsBloc] and a [HomeLinesBloc] above it.
///
/// - **Evaluation:** when a point is latched and Home is ready, once, at the first moment both
///   hold: the bloc reads the habits synchronously then, so habits that load later never produce
///   a line that open (E106).
/// - **Removals:** an entry in the line's category, a gate that closed, or a bill line taking
///   the slot. These only ever make the line leave.
/// - **Focus:** when a line the user tapped is removed, focus goes to Home's "Today" heading, the
///   node now in its place, never to the top of the page.
class HomeLinesDriver extends StatefulWidget {
  /// Wraps [child]; [clock] supplies "now" for the evaluation.
  const HomeLinesDriver({super.key, required this.clock, required this.child});

  final Clock clock;
  final Widget child;

  @override
  State<HomeLinesDriver> createState() => _HomeLinesDriverState();
}

class _HomeLinesDriverState extends State<HomeLinesDriver> {
  final FocusNode _headingFocus = FocusNode(debugLabel: 'Today heading');

  @override
  void dispose() {
    _headingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeHeadingFocus(
        node: _headingFocus,
        child: MultiBlocListener(
          listeners: <BlocListener<dynamic, dynamic>>[
            BlocListener<HomeLinesBloc, HomeLinesState>(
              listenWhen: (HomeLinesState previous, HomeLinesState current) => !previous.pointPending && current.pointPending,
              listener: (BuildContext context, HomeLinesState _) => _evaluateIfReady(context),
            ),
            BlocListener<HomeLinesBloc, HomeLinesState>(
              listenWhen: (HomeLinesState previous, HomeLinesState current) =>
                  (previous.missed.isSome() || previous.install) && previous.tapped && current.missed.isNone() && !current.install,
              // why: after the frame that collapses the slot, so the heading has taken its place.
              listener: (BuildContext context, HomeLinesState _) =>
                  WidgetsBinding.instance.addPostFrameCallback((Duration _) => _headingFocus.requestFocus()),
            ),
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (HomeState previous, HomeState current) => current is HomeReady,
              listener: _onHomeReady,
            ),
            BlocListener<HabitsBloc, HabitsState>(
              listenWhen: (HabitsState previous, HabitsState current) => current is HabitsReady,
              listener: _onHabitsReady,
            ),
          ],
          child: widget.child,
        ),
      );

  void _evaluateIfReady(BuildContext context) {
    final HomeState home = context.read<HomeBloc>().state;
    if (home is HomeReady) {
      context.read<HomeLinesBloc>().add(HomeLinesEvaluated(_facts(context, home)));
    }
  }

  void _onHomeReady(BuildContext context, HomeState home) {
    if (home is! HomeReady) {
      return;
    }
    final HomeLinesBloc lines = context.read<HomeLinesBloc>();
    if (lines.state.pointPending) {
      lines.add(HomeLinesEvaluated(_facts(context, home)));
      return;
    }
    if ((lines.state.missed.isSome() || lines.state.install) && _billLineShowing(home)) {
      lines.add(const HomeLinesSlotTaken());
    }
    // why: a fix uses the install line up; the bloc keeps one already on screen (C11).
    if (lines.state.install && !home.installDue) {
      lines.add(const HomeLinesInstallConsumed());
    }
  }

  void _onHabitsReady(BuildContext context, HabitsState habits) {
    if (habits is! HabitsReady) {
      return;
    }
    final HomeLinesBloc lines = context.read<HomeLinesBloc>();
    final CalendarDate today = widget.clock.today();
    lines.state.missed.map((MissedLog line) {
      final int categoryId = line.category.id;
      final GateStatus status = SuggestionGate.statusOf(
        Option<SuggestionState>.fromNullable(habits.index.states[categoryId]),
        today: today,
      );
      if (status != GateStatus.open) {
        lines.add(HomeLinesGateClosed(categoryId));
      } else if (habits.index.loggedToday.contains(categoryId)) {
        lines.add(HomeLinesEntryLogged(categoryId));
      }
    });
  }

  HomeLinesFacts _facts(BuildContext context, HomeReady home) {
    final HabitsState habits = context.read<HabitsBloc>().state;
    return HomeLinesFacts(
      index: habits is HabitsReady ? habits.index : null,
      categories: home.categories.values.toList(),
      now: widget.clock.now(),
      noIncome: home.summary.state is NoIncome,
      overState: OverCard.appliesTo(home.summary),
      billLineShowing: _billLineShowing(home),
      installDue: home.installDue,
    );
  }

  static bool _billLineShowing(HomeReady home) => home.summary.waitingBills.isNotEmpty || home.dueSoon.isSome();
}
