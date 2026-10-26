import 'package:flutter/material.dart';

import '../core/design/hisaab_dimensions.dart';
import '../core/extensions/build_context_extensions.dart';
import '../core/layout/app_layout.dart';
import 'shell_destination.dart';
import 'widgets/add_key.dart';
import 'widgets/hisaab_dock.dart';
import '../core/widgets/pane.dart';

/// The adaptive frame around Home and Spends (UI_DESIGN §13).
///
/// - One pane (phones, folded, split-screen): one screen at a time with the dock.
/// - Two panes (tablets, landscape, book posture): Home beside Spends, split at the hinge
///   when there is one, and no dock; the Add key sits at the bottom of the Home pane.
/// - Tabletop posture: the screen above the fold, the dock below it.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.home, required this.spends, required this.onAdd});

  final Widget home;
  final Widget spends;

  /// Opens the Add tray.
  final VoidCallback onAdd;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ShellDestination _selected = ShellDestination.home;

  Widget get _selectedScreen => switch (_selected) {
        ShellDestination.home => widget.home,
        ShellDestination.spends => widget.spends,
      };

  void _select(ShellDestination destination) => setState(() => _selected = destination);

  @override
  Widget build(BuildContext context) {
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
        Pane(rect: secondary, windowSize: window, child: widget.spends),
        if (showDivider)
          Positioned(
            left: primary.right,
            top: 0,
            bottom: 0,
            child: VerticalDivider(width: 1, color: context.colors.hairline),
          ),
      ];

  List<Widget> _tabletop(Rect top, Rect bottom, Size window) => <Widget>[
        Pane(rect: top, windowSize: window, child: _selectedScreen),
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
