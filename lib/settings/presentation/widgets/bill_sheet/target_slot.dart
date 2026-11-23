import 'package:material_ui/material_ui.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/polite_preview_slot.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/bill_sheet_state.dart';
import '../saving_target_copy.dart';

/// The two lines under the *Saving up to* question (AC-T3): what the typed amount means at the
/// saving's monthly amount, then "Your daily number doesn't change.".
///
/// Each line with figures is read as its spoken twin (B3, B4). Typing is announced politely
/// (FR-KS-4); the blank line, which has no figures, is not a live region, so opening the question
/// announces nothing but its title (AC-T12).
class TargetSlot extends StatelessWidget {
  const TargetSlot({super.key, required this.state});

  final BillSheetReady state;

  static _SlotClass _classOf(Option<TargetProgress> progress) => switch (progress.toNullable()) {
        null => _SlotClass.blank,
        TargetReached() => _SlotClass.reached,
        TargetEstimate() => _SlotClass.estimate,
        TargetFar() => _SlotClass.far,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    final Option<TargetProgress> progress = state.typedProgress;
    final SpokenLine line = progress
        .map((TargetProgress typed) => context.targetLiveLine(progress: typed, saving: state.rule, today: state.today))
        .getOrElse(() => (shown: strings.savingTargetBlank, spoken: strings.savingTargetBlank));
    final Widget lines = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(line.shown, key: const ValueKey<String>('target-slot-line-1'), semanticsLabel: line.spoken, style: style),
        Text(strings.savingUsedSame, key: const ValueKey<String>('target-slot-line-2'), style: style),
      ],
    );
    final _SlotClass kind = _classOf(progress);
    if (kind == _SlotClass.blank) {
      return KeyedSubtree(key: const ValueKey<String>('target-slot'), child: lines);
    }
    return PolitePreviewSlot(
      key: const ValueKey<String>('target-slot'),
      stateClass: kind,
      liveText: strings.spokenPair(line.spoken, strings.savingUsedSame),
      child: lines,
    );
  }
}

/// The kind of line 1; a change is spoken at once.
enum _SlotClass { blank, reached, estimate, far }
