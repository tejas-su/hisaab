import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;

import '../core/extensions/build_context_extensions.dart';
import '../core/layout/app_layout.dart';
import '../core/time/clock.dart';
import '../core/time/pay_cycle.dart';
import '../core/widgets/hisaab_snackbar_host.dart';
import '../home/home.dart';
import '../ledger/ledger.dart';
import '../spends/spends.dart';
import 'app_shell.dart';
import 'shell_destination.dart';
import 'widgets/midnight_listener.dart';
import 'widgets/resume_listener.dart';

/// Home and Spends in the adaptive shell, both reloading on resume and at midnight (SPEC BR-8).
///
/// Needs a [HomeBloc] and a [SpendsBloc] above it. [clock] times midnight; the callbacks open
/// the Add tray, Settings, a bill's sheet and a cycle's entries.
class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.clock,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenSettings,
    required this.onOpenBill,
    required this.onEnterBill,
    required this.onSeeEntries,
    required this.onAskAi,
    this.assemble = false,
    this.wrapPrimary,
    this.missedLogSlot,
    this.onFixMyNumber,
    this.installLineSlot,
    this.reachedLineSlot,
    this.onOpenStory,
    this.onAfford,
    this.wrapSpends,
    this.destination,
  });

  final Clock clock;
  final ValueChanged<EntryKind> onAdd;
  final ValueChanged<Entry> onEdit;
  final VoidCallback onOpenSettings;

  /// Opens a bill's sheet from Home's due-soon row (D118).
  final ValueChanged<RecurringRule> onOpenBill;

  /// Opens the amount sheet of a bill waiting on Home (D123).
  final ValueChanged<Occurrence> onEnterBill;
  final void Function(PayCycle cycle, Option<int> categoryId) onSeeEntries;

  /// Opens Ask AI for the cycle Spends shows (SPEC FR-SP-2).
  final ValueChanged<PayCycle> onAskAi;
  final bool assemble;

  /// Wraps the one page a notice shows over: Home, or Spends when it is the screen in view and
  /// not a pane beside Home. The app uses it for the *your usual* Undo (SPEC BR-10); with none,
  /// the pages are built as they are.
  final Widget Function(Widget page)? wrapPrimary;

  /// Builds the missed-log line in Home's nudge slot (FR-HO-3); none when null.
  final WidgetBuilder? missedLogSlot;

  /// Opens *Fix my number* from Home's foot row (FR-HO-9); none leaves the row out.
  final VoidCallback? onFixMyNumber;

  /// Builds the install line in Home's nudge slot (FR-HO-3); none when null.
  final WidgetBuilder? installLineSlot;

  /// Builds the reached line in Home's nudge slot (FR-HO-3, BR-23); none when null.
  final WidgetBuilder? reachedLineSlot;

  /// Opens the month story of the cycle so many cycles back (SPEC FR-SP-7); none hides its way in.
  final ValueChanged<int>? onOpenStory;

  /// Opens *Can I afford it?* from Spends (SPEC FR-SP-9); none hides its card.
  final VoidCallback? onAfford;

  /// Wraps Spends wherever it is shown, inside the snackbar host over it; the app uses it for the
  /// *Start saving* Undo (FR-SP-9 AC-6). With none, Spends is built as it is.
  final Widget Function(Widget page)? wrapSpends;

  /// The screen in view, when the caller needs to switch it (the *Can I afford it?* shortcut,
  /// FR-WG-9); the caller owns it. With none, the screen keeps its own, starting on Home.
  final ValueNotifier<ShellDestination>? destination;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final ValueNotifier<ShellDestination> _destination = widget.destination ?? (_own = ValueNotifier<ShellDestination>(ShellDestination.home));
  ValueNotifier<ShellDestination>? _own;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<HomeBloc>().add(const HomeLoadRequested());
    context.read<SpendsBloc>().add(const SpendsLoadRequested());
  }

  Widget _primary(Widget page) => widget.wrapPrimary?.call(page) ?? page;

  @override
  Widget build(BuildContext context) {
    final bool spendsBeside = context.layout.panes is SideBySidePanes;
    final Widget page = SpendsPage(
      today: widget.clock.today(),
      onSeeEntries: widget.onSeeEntries,
      onAskAi: widget.onAskAi,
      onOpenStory: widget.onOpenStory,
      onAddIncome: widget.onOpenSettings,
      onAfford: widget.onAfford,
    );
    final Widget spends = widget.wrapSpends?.call(page) ?? page;
    return Scaffold(
      body: MidnightListener(
        clock: widget.clock,
        onNewDay: _reload,
        child: ResumeListener(
          onResume: _reload,
          child: AppShell(
            destination: _destination,
            home: _primary(
              HomePage(
                onAdd: widget.onAdd,
                onEdit: widget.onEdit,
                onOpenSettings: widget.onOpenSettings,
                onOpenBill: widget.onOpenBill,
                onEnterBill: widget.onEnterBill,
                onSeeAll: (PayCycle cycle) => widget.onSeeEntries(cycle, const Option<int>.none()),
                // why: beside Home in two panes, Spends is already on screen, so the step is hidden.
                onSeeWhereItWent: spendsBeside ? null : () => _destination.value = ShellDestination.spends,
                assemble: widget.assemble,
                missedLogSlot: widget.missedLogSlot,
                onFixMyNumber: widget.onFixMyNumber,
                installLineSlot: widget.installLineSlot,
                reachedLineSlot: widget.reachedLineSlot,
              ),
            ),
            // why: beside Home both pages are on screen, and one notice is enough; it shows over Home.
            // Spends' own notices (FR-SP-9 AC-6) need a host there, since Home's is in the other pane.
            spends: spendsBeside ? HisaabSnackbarHost(child: spends) : _primary(spends),
            onAdd: () => widget.onAdd(EntryKind.spent),
          ),
        ),
      ),
    );
  }
}
