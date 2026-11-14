import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/polite_preview_slot.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/fix_state.dart';
import '../fix_slot_copy.dart';

/// The two-line preview under the amount: line 1 anchors on hisaab's figure, line 2 says the gap and
/// its effect (SPEC FR-FX-3). Before the first digit it shows the helper.
///
/// Every state is drawn in place of the last: digit changes inside a state swap at once, and a change
/// of state crossfades in 150 ms in both motion modes. Only the visible state is in the semantics
/// tree. Under a screen reader the short [FixSlotLines.live] text is spoken 1.2 s after the last key
/// and at once on a change of state; the guard's question and the count-only notice are plain
/// focusable text instead, read once (FR-FX-4 AC-3, AC-6).
///
/// [focusNode] takes focus on the guard question or the count-only notice. [period] is `week` for a
/// weekly cycle, otherwise `month`.
class FixPreviewSlot extends StatelessWidget {
  const FixPreviewSlot({
    super.key,
    required this.state,
    required this.period,
    required this.onRetry,
    this.focusNode,
    this.debounce = PolitePreviewSlot.defaultDebounce,
  });

  final FixState state;
  final String period;

  /// *Try again* on a failed read.
  final VoidCallback onRetry;
  final FocusNode? focusNode;

  /// How long the live text must stay unchanged before it is spoken; tests pass [Duration.zero].
  final Duration debounce;

  static const int _slotLines = 2;
  static const double _fallbackLineHeight = 1.4;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return switch (state) {
      FixFailed() => _failed(context, strings),
      FixDone() => const SizedBox.shrink(),
      FixReady() => _lines(context, FixSlotCopy.of(strings, state as FixReady, period: period, amount: _shown(context)), strings),
      FixLoading() => _lines(context, FixSlotLines(stateClass: FixSlotIdle.helper, line1: strings.fixHelper(period)), strings),
    };
  }

  static String Function(Money) _shown(BuildContext context) => context.money.format;

  String Function(Money) _spoken(BuildContext context, AppLocalizations strings) =>
      (Money money) => strings.spokenAmount(context.money.digits(money));

  Widget _lines(BuildContext context, FixSlotLines shown, AppLocalizations strings) {
    final FixSlotLines spoken = state is FixReady
        ? FixSlotCopy.of(strings, state as FixReady, period: period, amount: _spoken(context, strings))
        : shown;
    final Widget slot = AnimatedSwitcher(
      duration: HisaabMotion.reducedCrossfade,
      child: KeyedSubtree(key: ValueKey<Object>(shown.stateClass), child: _text(context, shown, spoken.sentence)),
    );
    // why: the guard question and the count-only notice are read once, on focus, and are not also a live region.
    final bool readOnFocus = shown.stateClass == 'guard' || shown.stateClass == FixSlotIdle.countOnly;
    return readOnFocus
        ? slot
        : PolitePreviewSlot(stateClass: shown.stateClass, liveText: spoken.live, debounce: debounce, child: slot);
  }

  Widget _text(BuildContext context, FixSlotLines lines, String spokenSentence) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? body = text.bodyMedium;
    final double lineHeight = MediaQuery.textScalerOf(context).scale((body?.fontSize ?? 16) * (body?.height ?? _fallbackLineHeight));
    final String? line1 = lines.line1;
    final String? line2 = lines.line2;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: lineHeight * _slotLines),
      child: Focus(
        focusNode: focusNode,
        child: Semantics(
          label: spokenSentence,
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (line1 != null) Text(line1, style: body?.copyWith(color: context.colors.ink2)),
              if (line2 != null && line2.isNotEmpty) Text(line2, style: text.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _failed(BuildContext context, AppLocalizations strings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.fixLoadFailed, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2)),
          const SizedBox(height: HisaabSpacing.s),
          HisaabChip(label: strings.tryAgain, onPressed: onRetry),
        ],
      );
}
