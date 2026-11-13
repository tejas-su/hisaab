import 'package:material_ui/material_ui.dart';

import '../design/hisaab_dimensions.dart';
import '../extensions/build_context_extensions.dart';
import '../layout/app_layout.dart';
import '../layout/window_class.dart';
import 'signal_key.dart';

/// The body of a keypad question in a bottom sheet: the typed [figure], the keypad and its action
/// key stay on screen, and only the [lead] (title, caption, slot) scrolls (SPEC FR-HO-8, FR-SE-1).
///
/// Stacked in a tall window. Side by side (the figure under the lead on one side, the controls on
/// the other) in a compact-height window, a tabletop, or when the stacked scroll region would be
/// under [minLeadRoom]. When even that can't fit (large text in a narrow window) everything
/// scrolls, so the keys stay reachable. Adds the bottom system inset under the action key.
class PinnedKeypadBody extends StatelessWidget {
  const PinnedKeypadBody({super.key, required this.lead, required this.figure, required this.controls, this.figureExtent = 64});

  /// Scrolls above the pinned figure: the title, caption and any preview line.
  final Widget lead;

  /// The typed amount; pinned above the keys.
  final Widget figure;

  /// Builds the keypad and the action key for a key height of `keyHeight`.
  final Widget Function(BuildContext context, double keyHeight) controls;

  /// The figure's height at 1x text, used to choose the arrangement before it is measured.
  final double figureExtent;

  /// The least the lead may be left with before the body goes side by side.
  static const double minLeadRoom = 96;
  static const double _stackedKeyHeight = 56;
  static const double _sideKeyHeight = HisaabSizes.minTouchTarget;
  static const double _sideBySideMinWidth = 360;
  static const double _keyGap = HisaabSpacing.s;
  static const double _actionExtent = SignalKey.minHeight + HisaabSpacing.m + 4;

  static double _controlsExtent(double keyHeight) => 4 * keyHeight + 3 * _keyGap + _actionExtent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final double bottom = HisaabSpacing.gutter + MediaQuery.paddingOf(context).bottom;
      final EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, bottom);
      if (!box.hasBoundedHeight) {
        return Padding(padding: padding, child: _column(context, _stackedKeyHeight, scrolling: false));
      }
      final double figureHeight = MediaQuery.textScalerOf(context).scale(figureExtent);
      final double room = box.maxHeight - bottom - figureHeight - _controlsExtent(_stackedKeyHeight);
      final AppLayout layout = context.layout;
      final bool sideBySide =
          box.maxWidth >= _sideBySideMinWidth &&
          (layout.panes is TabletopPanes || layout.heightClass == HeightClass.compact || room < minLeadRoom);
      if (sideBySide) {
        return Padding(padding: padding, child: _sideBySide(context));
      }
      if (room < 0) {
        return SingleChildScrollView(padding: padding, child: _column(context, _stackedKeyHeight, scrolling: false));
      }
      return Padding(padding: padding, child: _column(context, _stackedKeyHeight, scrolling: true));
    },
  );

  Widget _column(BuildContext context, double keyHeight, {required bool scrolling}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (scrolling) Flexible(child: SingleChildScrollView(child: lead)) else lead,
      figure,
      controls(context, keyHeight),
    ],
  );

  Widget _sideBySide(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(child: SingleChildScrollView(child: lead)),
            figure,
          ],
        ),
      ),
      const SizedBox(width: HisaabSpacing.gutter),
      Expanded(child: SingleChildScrollView(child: controls(context, _sideKeyHeight))),
    ],
  );
}
