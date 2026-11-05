import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_motion.dart';
import 'hisaab_snackbar.dart';
import 'hisaab_snackbar_bar.dart';

/// Shows a [HisaabSnackbar] over the bottom of [child]: an `inverse` pill with the dock's side edges,
/// rising [rise] dp on the `standard` spring (UI_DESIGN §3.5, §6, D105).
///
/// Wrap a page's body in one and call [HisaabSnackbarHost.of] from below it; the bar lives and dies
/// with the page. [bottom] is the gap to the host's bottom edge: 0 where a dock or Add key sits
/// right below (their own top padding is the gap), otherwise `HisaabSpacing.xl`.
///
/// It closes after [visibleFor], swiped down, or when Undo is tapped. The timer restarts while the
/// bar is touched or focused. With TalkBack on, a bar with an action stays until dismissed
/// (WCAG 2.2.1); a newer message replaces the current one.
class HisaabSnackbarHost extends StatefulWidget {
  const HisaabSnackbarHost({super.key, required this.child, this.bottom = HisaabSpacing.xl});

  final Widget child;
  final double bottom;

  /// How long a bar stays without touch, focus or TalkBack (SPEC BR-10).
  static const Duration visibleFor = Duration(seconds: 4);

  /// How far the bar rises as it enters.
  static const double rise = 16;

  /// The nearest host above [context].
  static HisaabSnackbarHostState of(BuildContext context) {
    final HisaabSnackbarHostState? host = context.findAncestorStateOfType<HisaabSnackbarHostState>();
    // why: every page that shows a snackbar wraps its body in a host; a missing one is a wiring bug.
    return host!;
  }

  @override
  State<HisaabSnackbarHost> createState() => HisaabSnackbarHostState();
}

/// Shows and hides the host's one bar; reach it with [HisaabSnackbarHost.of].
class HisaabSnackbarHostState extends State<HisaabSnackbarHost> with SingleTickerProviderStateMixin {
  late final AnimationController _shown = AnimationController(vsync: this)..addStatusListener(_clearWhenGone);
  HisaabSnackbar? _current;
  Timer? _timer;

  /// Shows [snackbar] in place of any bar already showing, with a fresh timer.
  void show(HisaabSnackbar snackbar) {
    setState(() => _current = snackbar);
    _animate(shown: true, spring: HisaabMotion.standard);
    _startTimer();
  }

  /// Closes the bar, if one is showing.
  void hide() => _close(HisaabMotion.standard);

  void _close(SpringDescription spring) {
    _timer?.cancel();
    _animate(shown: false, spring: spring);
  }

  void _animate({required bool shown, required SpringDescription spring}) {
    if (HisaabMotion.reduceMotion(context)) {
      shown
          ? _shown.animateTo(1, duration: HisaabMotion.reducedCrossfade)
          : _shown.animateBack(0, duration: HisaabMotion.reducedCrossfade);
      return;
    }
    // why: animateBackWith marks the run as reverse, so its end reads as dismissed and clears the bar.
    shown
        ? _shown.animateWith(SpringSimulation(spring, _shown.value, 1, 0, snapToEnd: true))
        : _shown.animateBackWith(SpringSimulation(spring, _shown.value, 0, 0, snapToEnd: true));
  }

  void _clearWhenGone(AnimationStatus status) {
    if (status.isDismissed && _current != null) {
      setState(() => _current = null);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final bool waitsForUser = _current?.action != null && MediaQuery.accessibleNavigationOf(context);
    if (!waitsForUser) {
      _timer = Timer(HisaabSnackbarHost.visibleFor, hide);
    }
  }

  void _pauseTimer() => _timer?.cancel();

  void _runAction(HisaabSnackbarAction action) {
    // why: a second tap while the bar leaves would restore the item twice.
    if (_shown.status == AnimationStatus.reverse) {
      return;
    }
    _close(HisaabMotion.snap);
    action.onPressed();
  }

  void _swiped() {
    _timer?.cancel();
    _shown.value = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.child,
          if (_current case final HisaabSnackbar current)
            PositionedDirectional(
              start: HisaabSpacing.gutter,
              end: HisaabSpacing.gutter,
              bottom: widget.bottom,
              child: _animated(current),
            ),
        ],
      );

  Widget _animated(HisaabSnackbar current) {
    final bool reduceMotion = HisaabMotion.reduceMotion(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shown,
        builder: (BuildContext context, Widget? bar) => Transform.translate(
          offset: Offset(0, reduceMotion ? 0 : (1 - _shown.value) * HisaabSnackbarHost.rise),
          child: Opacity(opacity: _shown.value, child: bar),
        ),
        child: Dismissible(
          key: ObjectKey(current),
          direction: DismissDirection.down,
          resizeDuration: null,
          onDismissed: (DismissDirection _) => _swiped(),
          child: Listener(
            onPointerDown: (PointerDownEvent _) => _pauseTimer(),
            onPointerUp: (PointerUpEvent _) => _startTimer(),
            onPointerCancel: (PointerCancelEvent _) => _startTimer(),
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (bool focused) => focused ? _pauseTimer() : _startTimer(),
              child: Semantics(
                container: true,
                liveRegion: true,
                onDismiss: hide,
                child: HisaabSnackbarBar(snackbar: current, onAction: _runAction),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
