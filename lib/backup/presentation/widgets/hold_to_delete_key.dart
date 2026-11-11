import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/haptics.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'hold_fill_clipper.dart';

/// The *Delete everything* key (SPEC FR-SE-4 AC-6, AC-7; UI_DESIGN §5.6, §6).
///
/// Pressed, a `danger` fill sweeps across it evenly over [holdFor]; let go when full, it calls
/// [onConfirmed]. Letting go early, or sliding off, drains it and changes nothing. With TalkBack,
/// Switch Access or a keyboard it is arm-then-confirm instead: a first activation arms it for
/// [armedFor] and a second confirms. [busy] shows it working and disables it.
class HoldToDeleteKey extends StatefulWidget {
  const HoldToDeleteKey({super.key, required this.onConfirmed, required this.haptics, this.busy = false});

  final VoidCallback onConfirmed;
  final Haptics haptics;
  final bool busy;

  /// How long the finger stays down before a release deletes.
  static const Duration holdFor = Duration(milliseconds: 1500);

  /// How long an assistive first activation stays armed.
  static const Duration armedFor = Duration(seconds: 10);

  /// The key's height, the same as a keypad key.
  static const double height = HisaabSizes.keypadKeyHeight;

  static const double _edge = 2;

  // why: with reduced motion the fill steps in quarters on the same clock (UI_DESIGN §6).
  static const int _reducedSteps = 4;

  @override
  State<HoldToDeleteKey> createState() => _HoldToDeleteKeyState();
}

class _HoldToDeleteKeyState extends State<HoldToDeleteKey> with SingleTickerProviderStateMixin {
  // why: preserve, not the default: with "Remove animations" on, Flutter would otherwise finish the
  // fill almost at once, and a short tap would delete everything. The 1.5 s is the guard, not a look.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: HoldToDeleteKey.holdFor,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onFillStatus);
  bool _letGoEarly = false;
  bool _armed = false;
  Timer? _disarm;

  @override
  void dispose() {
    _disarm?.cancel();
    _fill.dispose();
    super.dispose();
  }

  void _onFillStatus(AnimationStatus status) {
    if (status.isCompleted) {
      widget.haptics.threshold();
    }
  }

  void _onDown(TapDownDetails _) {
    widget.haptics.tick();
    setState(() => _letGoEarly = false);
    _fill.forward(from: 0);
  }

  void _onUp(TapUpDetails _) {
    if (_fill.isCompleted) {
      widget.onConfirmed();
      return;
    }
    setState(() => _letGoEarly = true);
    _drain();
  }

  void _drain() {
    if (HisaabMotion.reduceMotion(context)) {
      _fill.value = 0;
      return;
    }
    _fill.animateBackWith(SpringSimulation(HisaabMotion.snap, _fill.value, 0, 0, snapToEnd: true));
  }

  void _activate() {
    if (_armed) {
      _disarm?.cancel();
      setState(() => _armed = false);
      widget.onConfirmed();
      return;
    }
    widget.haptics.tick();
    setState(() => _armed = true);
    _disarm = Timer(HoldToDeleteKey.armedFor, () => setState(() => _armed = false));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool enabled = !widget.busy;
    // why: a screen reader, switch or keyboard user can't feel a timed hold, so those paths arm
    // and confirm instead (FR-SE-4 AC-7).
    final bool assistive = MediaQuery.accessibleNavigationOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          enabled: enabled,
          label: _armed ? strings.deleteAllHoldArmed : strings.deleteAllHoldSpoken,
          hint: strings.deleteAllHoldHint,
          onTap: enabled ? _activate : null,
          excludeSemantics: true,
          child: FocusableActionDetector(
            enabled: enabled,
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (ActivateIntent _) => _activate()),
            },
            child: GestureDetector(
              key: const ValueKey<String>('hold-to-delete'),
              behavior: HitTestBehavior.opaque,
              onTap: enabled && assistive ? _activate : null,
              onTapDown: enabled && !assistive ? _onDown : null,
              onTapUp: enabled && !assistive ? _onUp : null,
              onTapCancel: enabled && !assistive ? _drain : null,
              child: AnimatedBuilder(animation: _fill, builder: (BuildContext context, Widget? _) => _key(context, strings)),
            ),
          ),
        ),
        const SizedBox(height: HisaabSpacing.s),
        ExcludeSemantics(child: _caption(context, strings)),
      ],
    );
  }

  double get _shown {
    final double value = _fill.value;
    if (!HisaabMotion.reduceMotion(context) || value >= 1) {
      return value;
    }
    return (value * HoldToDeleteKey._reducedSteps).floor() / HoldToDeleteKey._reducedSteps;
  }

  String _label(AppLocalizations strings) {
    if (widget.busy) {
      return strings.deleteAllWorking;
    }
    if (_armed) {
      return strings.deleteAllHoldArmed;
    }
    return _fill.isCompleted ? strings.deleteAllHoldFull : strings.deleteAllHold;
  }

  Widget _key(BuildContext context, AppLocalizations strings) {
    final String label = _label(strings);
    final double filled = _armed || widget.busy ? 1 : _shown;
    return Container(
      height: HoldToDeleteKey.height,
      decoration: ShapeDecoration(
        shape: HisaabShapes.squircle(
          HisaabRadii.key,
          side: BorderSide(color: context.colors.danger, width: HoldToDeleteKey._edge),
        ),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: HisaabShapes.squircle(HisaabRadii.key)),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _face(context, label, foreground: context.colors.danger),
            ClipRect(
              clipper: HoldFillClipper(fraction: filled, textDirection: Directionality.of(context)),
              child: ColoredBox(color: context.colors.danger, child: _face(context, label, foreground: context.colors.background)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _face(BuildContext context, String label, {required Color foreground}) => Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppIcon(widget.busy ? AppIcons.busy : AppIcons.delete, color: foreground),
            const SizedBox(width: HisaabSpacing.s),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      );

  Widget _caption(BuildContext context, AppLocalizations strings) {
    final TextTheme text = Theme.of(context).textTheme;
    if (_letGoEarly && !_fill.isCompleted) {
      return Text(
        strings.deleteAllHoldShort,
        textAlign: TextAlign.center,
        style: text.bodyMedium?.copyWith(color: context.colors.ink, fontWeight: FontWeight.w600),
      );
    }
    return Text(
      strings.deleteAllHoldCaption(HoldToDeleteKey.holdFor.inMilliseconds / Duration.millisecondsPerSecond),
      textAlign: TextAlign.center,
      style: text.bodyMedium?.copyWith(color: context.colors.ink2),
    );
  }
}
