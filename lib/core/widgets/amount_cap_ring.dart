import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../design/hisaab_dimensions.dart';
import '../extensions/build_context_extensions.dart';

/// Holds a 2dp ring round a typed amount, and says why, after the keypad refused a digit at the
/// 9-digit cap (SPEC FR-AD-2, E13).
///
/// The shake is skipped under reduced motion and the reject haptic may be off, so the ring stays
/// until the next accepted key (when [amount] changes) and a polite live region says "That's the
/// most you can type." once. The ring takes the amount's own colour, so it has the same contrast.
class AmountCapRing extends StatefulWidget {
  const AmountCapRing({super.key, required this.rejections, required this.amount, required this.child});

  /// Counts refused keys; a rise raises the ring.
  final int rejections;

  /// What is typed; any change means a key was accepted, which lowers the ring.
  final Object amount;
  final Widget child;

  @override
  State<AmountCapRing> createState() => _AmountCapRingState();
}

class _AmountCapRingState extends State<AmountCapRing> {
  static const double _width = 2;
  static const EdgeInsets _outset = EdgeInsets.symmetric(horizontal: HisaabSpacing.s, vertical: HisaabSpacing.xs);

  bool _held = false;

  @override
  void didUpdateWidget(AmountCapRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rejections > oldWidget.rejections) {
      _held = true;
    } else if (widget.amount != oldWidget.amount) {
      _held = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color ring = Theme.of(context).textTheme.displayMedium?.color ?? DefaultTextStyle.of(context).style.color ?? context.colors.ink;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        widget.child,
        if (_held) ...<Widget>[
          Positioned.fill(
            left: -_outset.left,
            right: -_outset.right,
            top: -_outset.top,
            bottom: -_outset.bottom,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey<String>('amount-cap-ring'),
                decoration: BoxDecoration(
                  border: Border.all(color: ring, width: _width),
                  borderRadius: BorderRadius.circular(HisaabRadii.chip),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Semantics(liveRegion: true, label: AppLocalizations.of(context).amountCap, child: const SizedBox.shrink()),
          ),
        ],
      ],
    );
  }
}
