import 'package:material_ui/material_ui.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_motion.dart';
import '../extensions/build_context_extensions.dart';
import 'no_intrinsic_height.dart';

/// A screen's pinned top [bar] over a scrolling list of [children] (UI_DESIGN §3.5, D84). Used by
/// Home and Spends.
///
/// The bar is solid background and reaches behind the status bar, so its host `Pane` passes
/// `insetTop: false`. Once content scrolls under it, a hairline fades in along its bottom edge,
/// as Material 3's top app bar marks scrolled content. The bar is a pinned sliver, so focus and
/// screen-reader scrolling stop content below it, not under it.
///
/// The list's bottom edge fades into the background over [bottomFade], so content dissolves above
/// the dock rather than being cut off (D82); the fade lets taps through, and high contrast drops it.
///
/// [bar] is laid out [barHeight] tall; whatever it holds must scale down to fit.
class TopBarScrollView extends StatelessWidget {
  const TopBarScrollView({super.key, required this.bar, required this.children, this.fill});

  final Widget bar;
  final List<Widget> children;

  /// Optional content, such as an empty state's picture, given only the height left under
  /// [children]; it never makes the list scroll, so it must cope with a small or zero height.
  final Widget? fill;

  /// The bar's row height: a tap target plus the cycle switcher's 2dp rim on each side.
  static const double barHeight = HisaabSizes.minTouchTarget + 4;

  /// How tall the fade at the list's bottom edge is.
  static const double bottomFade = HisaabSpacing.xxl;

  static const double _hairline = 1;

  // why: a smoothstep ramp, so neither end of the fade shows a band on the warm grey.
  static const List<double> _fadeStops = <double>[0, 0.25, 0.5, 0.75, 1];
  static const List<double> _fadeAlphas = <double>[0, 0.16, 0.5, 0.84, 1];

  // why: content starts 14dp below the bar's row, as it did before the bar was pinned.
  static const double _contentTop = 14 - HisaabSpacing.s;

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      _list(context),
      if (!MediaQuery.highContrastOf(context))
        PositionedDirectional(start: 0, end: 0, bottom: 0, height: bottomFade, child: _fade(context)),
    ],
  );

  Widget _fade(BuildContext context) {
    final Color background = context.colors.background;
    return IgnorePointer(
      key: const ValueKey<String>('bottom-fade'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[for (final double alpha in _fadeAlphas) background.withValues(alpha: alpha)],
            stops: _fadeStops,
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    // why: the last card, or the fill under it, comes to rest just above the fade, fully visible.
    final double bottom = bottomFade + MediaQuery.paddingOf(context).bottom;
    final Widget? filler = fill;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _TopBarDelegate(bar: bar, statusBar: MediaQuery.paddingOf(context).top),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, _contentTop, HisaabSpacing.gutter, filler == null ? bottom : 0),
          sliver: SliverList.list(children: children),
        ),
        if (filler != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.l, HisaabSpacing.gutter, bottom),
              child: NoIntrinsicHeight(child: filler),
            ),
          ),
      ],
    );
  }
}

class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  const _TopBarDelegate({required this.bar, required this.statusBar});

  final Widget bar;
  final double statusBar;

  double get _extent => statusBar + HisaabSpacing.m + TopBarScrollView.barHeight + HisaabSpacing.s;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  bool shouldRebuild(_TopBarDelegate oldDelegate) => oldDelegate.bar != bar || oldDelegate.statusBar != statusBar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: shrinkOffset > 0 ? 1 : 0),
    duration: HisaabMotion.reduceMotion(context) ? HisaabMotion.reducedCrossfade : HisaabMotion.scrollEdge,
    curve: HisaabMotion.easeOut,
    builder: _surface,
    child: Padding(
      padding: EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, statusBar + HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.s),
      child: SizedBox(height: TopBarScrollView.barHeight, child: bar),
    ),
  );

  /// The solid bar with its hairline at [scrolledUnder] (0 at rest, 1 once content is beneath).
  Widget _surface(BuildContext context, double scrolledUnder, Widget? row) {
    final Color hairline = context.colors.hairline;
    return DecoratedBox(
      key: const ValueKey<String>('top-bar'),
      decoration: BoxDecoration(
        color: context.colors.background,
        // why: drawn inside the bottom padding and transparent at rest, so the bar never changes height.
        border: Border(
          bottom: BorderSide(color: hairline.withValues(alpha: hairline.a * scrolledUnder), width: TopBarScrollView._hairline),
        ),
      ),
      child: row,
    );
  }
}
