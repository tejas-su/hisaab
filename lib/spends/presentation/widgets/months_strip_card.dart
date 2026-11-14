import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/cycle_bar.dart';
import '../month_story_copy.dart';
import '../spends_graph_copy.dart';
import 'month_strip_slot.dart';
import 'spends_card.dart';

/// The months strip, the last card on Spends (SPEC FR-SP-8): a title and count, a bar per cycle
/// (5, or 6 when the card is 288dp inside), "Money in" and the key, then the picked cycle read out
/// with *Open*. At 1.5× text and above the bars become rows.
class MonthsStripCard extends StatefulWidget {
  const MonthsStripCard({super.key, required this.strip, required this.copy, required this.shownCyclesBack, required this.onOpen});

  final MonthsStrip strip;
  final SpendsGraphCopy copy;

  /// The cycle Spends shows; *Open* is left out when it is the one picked.
  final int shownCyclesBack;

  /// Shows a cycle by how far back it is.
  final ValueChanged<int> onOpen;

  /// Six slots need this much width inside the card, so each stays a 48dp target.
  static const double sixSlotsWidth = 288;
  static const int _phoneSlots = 5;
  static const int _wideSlots = 6;
  static const double _rowsFrom = 1.5;

  @override
  State<MonthsStripCard> createState() => _MonthsStripCardState();
}

class _MonthsStripCardState extends State<MonthsStripCard> {
  int? _picked;

  @override
  Widget build(BuildContext context) => SpendsCard(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final int slots = box.maxWidth >= MonthsStripCard.sixSlotsWidth ? MonthsStripCard._wideSlots : MonthsStripCard._phoneSlots;
            final List<CycleBar> bars = widget.strip.bars.sublist(math.max(0, widget.strip.bars.length - slots));
            return _content(context, bars);
          },
        ),
      );

  Widget _content(BuildContext context, List<CycleBar> bars) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final (String title, String? count) = widget.copy.stripHeading(MonthsStrip(bars), bars.length);
    final CycleBar picked = bars.firstWhere((CycleBar b) => b.cyclesBack == (_picked ?? _defaultPick(bars)), orElse: () => bars.last);
    final int scale = bars.fold(0, (int top, CycleBar b) => math.max(top, math.max((b.spent + b.saved).amountMinor, b.income.amountMinor)));
    final bool rows = MediaQuery.textScalerOf(context).scale(1) >= MonthsStripCard._rowsFrom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(header: true, child: Text(title, style: type.titleLarge)),
        if (count != null) Text(count, style: type.bodyMedium?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.l),
        if (rows)
          for (final CycleBar bar in bars) _slot(bar, picked, scale, horizontal: true)
        else
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[for (final CycleBar bar in bars) Expanded(child: _slot(bar, picked, scale))]),
        const SizedBox(height: HisaabSpacing.s),
        Text(strings.spendsStripMoneyIn(context.money.format(bars.last.income)), style: type.bodySmall?.copyWith(color: context.colors.ink2)),
        Text(strings.spendsStripKey, style: type.bodySmall?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.s),
        _readOut(context, strings, picked),
      ],
    );
  }

  Widget _slot(CycleBar bar, CycleBar picked, int scale, {bool horizontal = false}) => MonthStripSlot(
        key: ValueKey<int>(bar.cyclesBack),
        bar: bar,
        scale: scale,
        label: widget.copy.barLabel(bar.cycle),
        spoken: widget.copy.readOut(bar, MonthStoryCopy.spoken(AppLocalizations.of(context), context.money)),
        picked: bar.cyclesBack == picked.cyclesBack,
        horizontal: horizontal,
        onPressed: () => setState(() => _picked = bar.cyclesBack),
      );

  Widget _readOut(BuildContext context, AppLocalizations strings, CycleBar picked) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                widget.copy.readOut(picked, MonthStoryCopy.shown(context.money)),
                key: const ValueKey<String>('strip-read-out'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          if (picked.cyclesBack != widget.shownCyclesBack)
            TextButton(
              key: const ValueKey<String>('strip-open'),
              style: TextButton.styleFrom(minimumSize: const Size(HisaabSizes.minTouchTarget, HisaabSizes.minTouchTarget)),
              onPressed: () => widget.onOpen(picked.cyclesBack),
              child: Text(strings.spendsStripOpen, style: Theme.of(context).textTheme.labelLarge),
            ),
        ],
      );

  // why: a finished cycle shown is picked; on the running cycle, the last finished one (FR-SP-8).
  static int _defaultPick(List<CycleBar> bars) =>
      bars.lastWhere((CycleBar b) => !b.isRunning, orElse: () => bars.last).cyclesBack;
}
