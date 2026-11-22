import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../design/hisaab_dimensions.dart';
import '../extensions/build_context_extensions.dart';
import '../layout/app_layout.dart';
import '../layout/window_class.dart';
import 'no_intrinsic_height.dart';
import 'pane.dart';

/// Places a screen's [header] (question, amount) and [controls] (keypad, keys) for the window
/// (UI_DESIGN §13).
///
/// - Tabletop posture: header above the fold, controls below it.
/// - Book posture or a wide window: header and controls side by side, split at the fold.
/// - Short windows (phone landscape), or when [sideBySide] asks for it: side by side.
/// - Otherwise: header on top, controls at the bottom, at most 560dp wide.
///
/// The fold-aware arrangements need window coordinates, so they apply only when [fullWindow]
/// is true (the widget fills the app window). The header scrolls if it doesn't fit.
class AdaptiveSplit extends StatelessWidget {
  const AdaptiveSplit({
    super.key,
    required this.header,
    required this.controls,
    this.art,
    this.fullWindow = true,
    this.sideBySide = false,
    this.headerFillsPane = false,
  });

  final Widget header;
  final Widget controls;

  /// A picture for the gap between [header] and [controls], given only the space left over in
  /// the header-on-top arrangement and left out of the others (UI_DESIGN §5.1). It must size
  /// itself to the space it gets, including none.
  final Widget? art;

  final bool fullWindow;

  /// Put header and controls side by side even in a tall window, e.g. in a short, wide tray.
  final bool sideBySide;

  /// In the header-on-top arrangement, makes [header] at least as tall as the space above
  /// [controls], so a header that spreads its children (a `Column` with
  /// `MainAxisAlignment.spaceBetween`) shares out the spare height. A taller header still scrolls.
  final bool headerFillsPane;

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
    if (sideBySide || layout.heightClass == HeightClass.compact) {
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
              Expanded(child: _onTop(header)),
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

  Widget _onTop(Widget header) {
    final Widget? picture = art;
    if (picture != null) {
      return _withArt(header, picture);
    }
    return headerFillsPane ? _filling(header) : _scrolling(header);
  }

  // why: a min height, not intrinsics, so headers holding a LayoutBuilder (the usual pill, the
  // chips) can fill the pane; a Column under a min height spreads its spare space by its alignment.
  static Widget _filling(Widget header) => LayoutBuilder(
        builder: (BuildContext _, BoxConstraints pane) => _scrolling(
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(0, pane.maxHeight - _padding.vertical)),
            child: header,
          ),
        ),
      );

  // why: the header keeps its natural height and still scrolls when it can't fit (large text);
  // the art takes only what is left below it.
  static Widget _withArt(Widget header, Widget art) => CustomScrollView(
        slivers: <Widget>[
          SliverPadding(padding: _padding.copyWith(bottom: 0), sliver: SliverToBoxAdapter(child: header)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: _padding.copyWith(top: HisaabSpacing.l),
              child: NoIntrinsicHeight(child: art),
            ),
          ),
        ],
      );
}
