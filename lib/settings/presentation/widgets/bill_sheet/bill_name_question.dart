import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../../../ledger/presentation/rule_glyph.dart';
import '../../../../ledger/presentation/rule_words.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_question_frame.dart';
import 'bill_sheet_copy.dart';

/// The name question: the name field (no pills), a line saying whether the icon follows the
/// name, and *Save* (SPEC FR-SE-1 AC-3, BR-9 bill icon).
class BillNameQuestion extends StatefulWidget {
  const BillNameQuestion({super.key, required this.state});

  final BillSheetReady state;

  @override
  State<BillNameQuestion> createState() => _BillNameQuestionState();
}

class _BillNameQuestionState extends State<BillNameQuestion> {
  late final TextEditingController _controller = TextEditingController(text: widget.state.draftName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillSheetBloc bloc = context.read<BillSheetBloc>();
    final BillSheetReady state = widget.state;
    final BillIcon icon = state.rule.icon.getOrElse(() => BillIcon.forName(state.draftName));
    // why: a saving always shows the piggy bank, so its name never moves an icon (D120).
    final bool isSaving = state.rule.kind == EntryKind.saved;
    final bool canSave = state.draftName.trim().isNotEmpty && !state.saving;
    return BillQuestionFrame(
      question: strings.ruleNameQuestion(state.rule.kind),
      name: state.draftName,
      glyph: isSaving ? state.rule.glyph : icon.glyph,
      figure: AmountText(state.rule.amount, roll: false, style: Theme.of(context).textTheme.displaySmall),
      caption: strings.billEveryMonth(state.rule.schedule.anchor.day),
      saveFailed: state.saveFailed,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('bill-sheet-name'),
            controller: _controller,
            autofocus: true,
            maxLength: BillValidator.maxLabelLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (String name) => bloc.add(BillSheetNameChanged(name)),
            onSubmitted: (String _) => bloc.add(const BillSheetNameSaved()),
            onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(labelText: strings.billNameLabel, counterText: ''),
          ),
          if (!isSaving) ...<Widget>[
            const SizedBox(height: HisaabSpacing.s),
            Row(
              children: <Widget>[
                AppIcon(icon.glyph, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_iconLine(context, state), style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ],
          const SizedBox(height: HisaabSpacing.l),
          SignalKey(
            key: const ValueKey<String>('bill-sheet-save'),
            label: strings.save,
            onPressed: canSave ? () => bloc.add(const BillSheetNameSaved()) : null,
          ),
        ],
      ),
    );
  }

  String _iconLine(BuildContext context, BillSheetReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return state.rule.icon.match(
      () {
        final BillIcon suggested = BillIcon.forName(state.draftName);
        return suggested == BillIcon.bill ? strings.billIconNoMatch : strings.billNameIconFollows(context.iconName(suggested));
      },
      (BillIcon picked) => strings.billNameIconKept(context.iconName(picked)),
    );
  }
}
