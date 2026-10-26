import 'package:flutter/material.dart';

import '../design/hisaab_dimensions.dart';
import '../extensions/build_context_extensions.dart';
import '../layout/app_layout.dart';
import '../layout/window_class.dart';
import 'pane.dart';

/// Places a screen's [header] (question, amount) and [controls] (keypad, keys) for the window
/// (UI_DESIGN §13).
///
/// - Tabletop posture: header above the fold, controls below it.
/// - Book posture or a wide window: header and controls side by side, split at the fold.
/// - Short windows (phone landscape): side by side.
/// - Otherwise: header on top, controls at the bottom, at most 560dp wide.
///
/// The fold-aware arrangements need window coordinates, so they apply only when [fullWindow]
/// is true (the widget fills the app window). The header scrolls if it doesn't fit.
class AdaptiveSplit extends StatelessWidget {
  const AdaptiveSplit({super.key, required this.header, required this.controls, this.fullWindow = true});

  final Widget header;
  final Widget controls;
  final bool fullWindow;

  static const double readableWidth = 560;
  static const EdgeInsetsDirectional _padding = EdgeInsetsDirectional.fromSTEB(
    HisaabSpacing.gutter,
    HisaabSpacing.l,
    HisaabSpacing.gutter,
    HisaabSpacing.xl,
  );

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = context.layout;
    final PaneArrangement panes = layout.panes;
    if (fullWindow && panes is TabletopPanes) {
      return _inPanes(context, panes.top, panes.bottom);
    }
    if (fullWindow && panes is SideBySidePanes) {
      return _inPanes(context, panes.primary, panes.secondary);
    }
    if (layout.heightClass == HeightClass.compact) {
      return SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(child: _scrolling(header)),
            Expanded(child: _scrolling(controls)),
          ],
        ),
      );
    }
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: readableWidth),
          child: Column(
            children: <Widget>[
              Expanded(child: _scrolling(header)),
              Padding(padding: _padding.copyWith(top: 0), child: controls),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inPanes(BuildContext context, Rect first, Rect second) {
    final Size window = MediaQuery.sizeOf(context);
    return Stack(
      children: <Widget>[
        Pane(rect: first, windowSize: window, child: _scrolling(header)),
        Pane(
          rect: second,
          windowSize: window,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _scrolling(ConstrainedBox(constraints: const BoxConstraints(maxWidth: readableWidth), child: controls)),
          ),
        ),
      ],
    );
  }

  static Widget _scrolling(Widget child) => SingleChildScrollView(padding: _padding, child: child);
}
