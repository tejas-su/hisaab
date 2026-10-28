import 'package:flutter/material.dart';

import '../core/design/hisaab_dimensions.dart';
import '../core/extensions/build_context_extensions.dart';
import '../core/layout/app_layout.dart';
import 'shell_destination.dart';
import 'widgets/add_key.dart';
import 'widgets/hisaab_dock.dart';
import '../core/widgets/pane.dart';

/// The adaptive frame around Home and Spends (UI_DESIGN §13). Both draw their own translucent
/// top bar behind the status bar, so no pane insets the top. Their lists fade out above the
/// dock; content never sits behind it (D82).
///
/// - One pane (phones, folded, split-screen): one screen at a time with the dock.
/// - Two panes (tablets, landscape, book posture): Home beside Spends, split at the hinge
///   when there is one, and no dock; the Add key sits at the bottom of the Home pane.
/// - Tabletop posture: the screen above the fold, the dock below it.
///
/// [destination], when given, lets the caller switch screens too (Home's *See where it went*).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.home, required this.spends, required this.onAdd, this.destination});

  final Widget home;
  final Widget spends;
  final ValueNotifier<ShellDestination>? destination;

  /// Opens the Add tray.
  final VoidCallback onAdd;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ValueNotifier<ShellDestination>? _own;

  ValueNotifier<ShellDestination> get _destination =>
      widget.destination ?? (_own ??= ValueNotifier<ShellDestination>(ShellDestination.home));

  ShellDestination get _selected => _destination.value;

  Widget get _selectedScreen => switch (_selected) {
        ShellDestination.home => widget.home,
        ShellDestination.spends => widget.spends,
      };

  void _select(ShellDestination destination) => _destination.value = destination;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ShellDestination>(
        valueListenable: _destination,
        builder: (BuildContext context, ShellDestination _, Widget? _) => _frame(context),
      );

  Widget _frame(BuildContext context) {
    final Size window = MediaQuery.sizeOf(context);
    return ColoredBox(
      color: context.colors.background,
      child: Stack(
        children: switch (context.layout.panes) {
          SinglePane(:final Rect content) => _single(content, window),
          SideBySidePanes(:final Rect primary, :final Rect secondary, :final bool splitByHinge) =>
            _sideBySide(primary, secondary, window, showDivider: !splitByHinge),
          TabletopPanes(:final Rect top, :final Rect bottom) => _tabletop(top, bottom, window),
        },
      ),
    );
  }

  List<Widget> _single(Rect content, Size window) => <Widget>[
        Pane(
          rect: content,
          windowSize: window,
          insetTop: false,
          child: Column(
            children: <Widget>[
              Expanded(child: KeyedSubtree(key: ValueKey<ShellDestination>(_selected), child: _selectedScreen)),
              _dock(),
            ],
          ),
        ),
      ];

  List<Widget> _sideBySide(Rect primary, Rect secondary, Size window, {required bool showDivider}) => <Widget>[
        Pane(
          rect: primary,
          windowSize: window,
          insetTop: false,
          child: Column(
            children: <Widget>[
              Expanded(child: widget.home),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.l),
                child: AddKey(onAdd: widget.onAdd),
              ),
            ],
          ),
        ),
        Pane(rect: secondary, windowSize: window, insetTop: false, child: widget.spends),
        if (showDivider)
          Positioned(
            left: primary.right,
            top: 0,
            bottom: 0,
            child: VerticalDivider(width: 1, color: context.colors.hairline),
          ),
      ];

  List<Widget> _tabletop(Rect top, Rect bottom, Size window) => <Widget>[
        Pane(rect: top, windowSize: window, insetTop: false, child: _selectedScreen),
        Pane(rect: bottom, windowSize: window, child: Center(child: _dock())),
      ];

  Widget _dock() => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          HisaabSpacing.gutter,
          HisaabSpacing.s,
          HisaabSpacing.gutter,
          HisaabSpacing.xl,
        ),
        child: HisaabDock(selected: _selected, onSelected: _select, onAdd: widget.onAdd),
      );
}
