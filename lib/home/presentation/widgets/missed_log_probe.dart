import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home_bloc.dart';
import '../bloc/home_lines_bloc.dart';
import '../bloc/home_lines_event.dart';

/// Reports once that the line it wraps is on screen: [HomeLinesShown] for the missed-log line, so
/// `asked_on` is written (SPEC FR-HO-3 AC-4), or another [event], such as the install line's, so its
/// seen flag is written.
///
/// After its first frame it sends [HomeLinesShown] only if Home is in view and nothing is over
/// it: the route is current, the tickers are on, and no tray or sheet holds Home. A line drawn
/// under a door-opened tray is therefore never asked, and one that was not reported in its first
/// frame is not reported later. Give it a key that changes with each new line.
class MissedLogProbe extends StatefulWidget {
  /// Wraps [child], the line's row.
  const MissedLogProbe({super.key, required this.child, this.event = const HomeLinesShown()});

  final Widget child;

  /// What to report; the missed-log line's by default.
  final HomeLinesEvent event;

  @override
  State<MissedLogProbe> createState() => _MissedLogProbeState();
}

class _MissedLogProbeState extends State<MissedLogProbe> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _report());
  }

  void _report() {
    if (!mounted) {
      return;
    }
    final bool inView = (ModalRoute.of(context)?.isCurrent ?? true) && TickerMode.valuesOf(context).enabled;
    if (inView && !context.read<HomeBloc>().isCovered) {
      context.read<HomeLinesBloc>().add(widget.event);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
