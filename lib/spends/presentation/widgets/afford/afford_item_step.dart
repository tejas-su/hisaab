import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/pinned_keypad_body.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/afford_bloc.dart';
import '../../bloc/afford_event.dart';
import '../../bloc/afford_state.dart';
import 'afford_keypad_controls.dart';

/// Step 1, "What do you want to buy?": the item's name and its price on the keypad, and *Next*
/// once both are there (SPEC FR-SP-9 AC-2).
class AffordItemStepView extends StatefulWidget {
  const AffordItemStepView({super.key, required this.draft});

  final AffordDraft draft;

  /// The figure's height at 1x text: the amount and its caption.
  static const double figureExtent = 88;

  @override
  State<AffordItemStepView> createState() => _AffordItemStepState();
}

class _AffordItemStepState extends State<AffordItemStepView> {
  // why: built from the draft, so a rotate, a fold or Back from step 2 keeps the typed name (E165).
  late final TextEditingController _name = TextEditingController(text: widget.draft.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AffordBloc bloc = context.read<AffordBloc>();
    final TextTheme text = Theme.of(context).textTheme;
    return PinnedKeypadBody(
      figureExtent: AffordItemStepView.figureExtent,
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(header: true, child: Text(strings.affordItemQuestion, style: text.titleLarge)),
          const SizedBox(height: HisaabSpacing.s),
          TextField(
            key: const ValueKey<String>('afford-name'),
            controller: _name,
            // why: focus lands on the name when step 1 opens (AC-9).
            autofocus: true,
            maxLength: BillValidator.maxLabelLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (String name) => bloc.add(AffordNameChanged(name)),
            onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: strings.affordNameLabel,
              counterText: '',
              // why: the prefix slot is at least 48dp and HugeIcon stretches to fill it; centring
              // keeps the glyph at its 24dp size, as Material's Icon does.
              prefixIcon: Center(widthFactor: 1, heightFactor: 1, child: AppIcon(AppIcons.forKey('shopping'))),
            ),
          ),
          const SizedBox(height: HisaabSpacing.m),
        ],
      ),
      figure: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AmountDisplay(amount: widget.draft.priceMoney, rejections: widget.draft.rejections),
          Text(strings.affordPriceLabel, style: text.bodySmall?.copyWith(color: context.colors.ink2)),
        ],
      ),
      controls: (BuildContext context, double keyHeight) => AffordKeypadControls(
        keyHeight: keyHeight,
        label: strings.next,
        actionKey: const ValueKey<String>('afford-next'),
        action: widget.draft.canGoOn ? () => bloc.add(const AffordNextPressed()) : null,
      ),
    );
  }
}
