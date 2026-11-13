import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/polite_preview_slot.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/used_state.dart';

/// The two fixed lines under the *Used* question (AC-Y7, AC-Y8): what stays set aside, then
/// "Your daily number doesn't change.". A refused key replaces line 1 with why, until the next
/// accepted key; with nothing set aside it says so. A screen reader hears it as a polite live
/// region (FR-KS-4 AC-4).
class UsedSlot extends StatelessWidget {
  const UsedSlot({super.key, required this.state});

  final UsedReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    final (_SlotKind kind, String shown, String spoken) = _lineOne(context, strings);
    final String same = strings.savingUsedSame;
    return PolitePreviewSlot(
      key: const ValueKey<String>('used-slot'),
      stateClass: kind,
      liveText: kind == _SlotKind.nothing ? spoken : strings.spokenPair(spoken, same),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(shown, key: const ValueKey<String>('used-slot-line-1'), style: style),
          if (kind != _SlotKind.nothing) Text(same, key: const ValueKey<String>('used-slot-line-2'), style: style),
        ],
      ),
    );
  }

  (_SlotKind, String, String) _lineOne(BuildContext context, AppLocalizations strings) {
    if (state.nothingToUse) {
      return (_SlotKind.nothing, strings.savingUsedNothing, strings.savingUsedNothing);
    }
    if (state.capShown) {
      return (_SlotKind.cap, strings.savingUsedCap, strings.savingUsedCap);
    }
    final Money shownAmount = Money.fromMajor(state.rupees == 0 ? state.setAsideRupees : state.setAsideRupees - state.rupees);
    final String shown = context.money.format(shownAmount);
    final String spoken = strings.spokenAmount(context.money.digits(shownAmount));
    if (state.rupees == 0) {
      return (_SlotKind.preview, strings.savingUsedSetAside(shown), strings.savingUsedSetAside(spoken));
    }
    final int left = shownAmount.floorMajor;
    return (_SlotKind.preview, strings.savingUsedLeft(left, shown), strings.savingUsedLeft(left, spoken));
  }
}

enum _SlotKind { preview, cap, nothing }
