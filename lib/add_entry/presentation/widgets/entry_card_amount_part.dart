import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';

/// The entry card's keypad (SPEC FR-AD-8 AC-3). The first digit replaces the old amount; the key
/// under it reads "Keep ₹250", then "Change to ₹350", and is disabled at ₹0.
///
/// [withKeepKey] is false on the board, where moving on keeps the amount (AC-12).
class EntryCardAmountPart extends StatelessWidget {
  const EntryCardAmountPart({super.key, required this.form, this.withKeepKey = true});

  final EntryCardForm form;
  final bool withKeepKey;

  @override
  Widget build(BuildContext context) {
    final EntryCardBloc bloc = context.read<EntryCardBloc>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Keypad(
          keyHeight: HisaabSizes.minTouchTarget,
          onKey: (String key) => bloc.add(EntryCardKeyPressed(key)),
          onBackspace: () => bloc.add(const EntryCardBackspacePressed()),
          onClear: () => bloc.add(const EntryCardCleared()),
        ),
        if (withKeepKey) ...<Widget>[
          const SizedBox(height: HisaabSpacing.s),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('entry-card-keep'),
              label: _label(context),
              onPressed: form.shownRupees > 0 ? () => bloc.add(const EntryCardAmountKept()) : null,
            ),
          ),
        ],
      ],
    );
  }

  String _label(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final int shown = form.shownRupees;
    if (shown == 0) {
      return strings.entryCardTypeAmount;
    }
    final String amount = context.money.format(Money.fromMajor(shown));
    return shown == form.rupees ? strings.entryCardKeep(amount) : strings.entryCardChangeTo(amount);
  }
}
