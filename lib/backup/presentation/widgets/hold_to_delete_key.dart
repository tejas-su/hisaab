import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

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
/// Pressed, a `danger` fill sweeps across it evenly over [holdFor]. Let go when full, it reads
/// *Undo* and the fill drains back over [undoFor] (D149); a tap in that time stops it, and when
/// the fill is empty it calls [onConfirmed]. Letting go early, or sliding off, drains it and
/// changes nothing. With TalkBack, Switch Access or a keyboard it is arm-then-confirm instead: a
/// first activation arms it for [armedFor], a second starts the same countdown, and a third undoes.
/// [busy] shows it working and disables it.
class HoldToDeleteKey extends StatefulWidget {
  const HoldToDeleteKey({super.key, required this.onConfirmed, required this.haptics, this.busy = false});

  final VoidCallback onConfirmed;
  final Haptics haptics;
  final bool busy;

  /// How long the finger stays down before a release deletes.
  static const Duration holdFor = Duration(milliseconds: 1500);

  /// How long the fill drains back after a full hold, while a tap still undoes it.
  static const Duration undoFor = Duration(seconds: 5);

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
    reverseDuration: HoldToDeleteKey.undoFor,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onFillStatus);
  bool _letGoEarly = false;
  bool _armed = false;
  bool _counting = false;
  bool _undone = false;
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
    if (status.isDismissed && _counting) {
      setState(() => _counting = false);
      widget.onConfirmed();
    }
  }

  void _onDown(TapDownDetails _) {
    if (_counting) {
      return;
    }
    widget.haptics.tick();
    setState(() {
      _letGoEarly = false;
      _undone = false;
    });
    _fill.forward(from: 0);
  }

  void _onUp(TapUpDetails _) {
    if (_counting) {
      _undo();
      return;
    }
    if (_fill.isCompleted) {
      _startCountdown();
      return;
    }
    setState(() => _letGoEarly = true);
    _drain();
  }

  void _onCancel() {
    // why: a press that slides off during the countdown is neither an Undo nor a new hold.
    if (!_counting) {
      _drain();
    }
  }

  void _startCountdown() {
    setState(() => _counting = true);
    _fill.reverse(from: 1);
    final AppLocalizations strings = AppLocalizations.of(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      strings.deleteAllUndoAnnounced(HoldToDeleteKey.undoFor.inSeconds),
      Directionality.of(context),
    );
  }

  void _undo() {
    widget.haptics.tick();
    setState(() {
      _counting = false;
      _undone = true;
    });
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
    if (_counting) {
      _undo();
      return;
    }
    if (_armed) {
      _disarm?.cancel();
      setState(() => _armed = false);
      _startCountdown();
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
          label: _spokenLabel(strings),
          hint: _counting ? null : strings.deleteAllHoldHint,
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
              onTapCancel: enabled && !assistive ? _onCancel : null,
              child: AnimatedBuilder(animation: _fill, builder: (BuildContext context, Widget? _) => _key(context, strings)),
            ),
          ),
        ),
        const SizedBox(height: HisaabSpacing.s),
        ExcludeSemantics(
          child: AnimatedBuilder(animation: _fill, builder: (BuildContext context, Widget? _) => _caption(context, strings)),
        ),
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

  String _spokenLabel(AppLocalizations strings) {
    if (_counting) {
      return strings.deleteAllUndoSpoken;
    }
    return _armed ? strings.deleteAllHoldArmed : strings.deleteAllHoldSpoken;
  }

  String _label(AppLocalizations strings) {
    if (widget.busy) {
      return strings.deleteAllWorking;
    }
    if (_counting) {
      return strings.deleteAllUndo;
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
            AppIcon(_glyph, color: foreground),
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

  AppIconData get _glyph {
    if (widget.busy) {
      return AppIcons.busy;
    }
    return _counting ? AppIcons.undoDelete : AppIcons.delete;
  }

  int get _secondsLeft => (_fill.value * HoldToDeleteKey.undoFor.inSeconds).ceil();

  Widget _caption(BuildContext context, AppLocalizations strings) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? loud = text.bodyMedium?.copyWith(color: context.colors.ink, fontWeight: FontWeight.w600);
    if (_counting) {
      return Text(strings.deleteAllUndoCaption(_secondsLeft), textAlign: TextAlign.center, style: loud);
    }
    if (_letGoEarly && !_fill.isCompleted) {
      return Text(strings.deleteAllHoldShort, textAlign: TextAlign.center, style: loud);
    }
    if (_undone) {
      return Text(strings.deleteAllUndone, textAlign: TextAlign.center, style: loud);
    }
    return Text(
      strings.deleteAllHoldCaption,
      textAlign: TextAlign.center,
      style: text.bodyMedium?.copyWith(color: context.colors.ink2),
    );
  }
}
