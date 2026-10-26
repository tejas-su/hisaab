import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/bill_editor_bloc.dart';
import '../bloc/bill_editor_event.dart';
import '../bloc/bill_editor_state.dart';
import 'bill_question.dart';

/// Step 1 of the bill editor: type a name, or tap a common bill to name it and move on.
///
/// [onDelete] shows a Delete chip, when changing an existing bill. The text field's controller
/// is this widget's own leaf state.
class BillNameStep extends StatefulWidget {
  const BillNameStep({super.key, required this.form, this.onDelete});

  final BillEditorInProgress form;
  final VoidCallback? onDelete;

  @override
  State<BillNameStep> createState() => _BillNameStepState();
}

class _BillNameStepState extends State<BillNameStep> {
  late final TextEditingController _controller = TextEditingController(text: widget.form.label);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillEditorBloc bloc = context.read<BillEditorBloc>();
    final VoidCallback? delete = widget.onDelete;
    return AdaptiveSplit(
      header: BillQuestion(
        question: strings.billNameQuestion,
        children: <Widget>[
          const SizedBox(height: HisaabSpacing.l),
          TextField(
            key: const ValueKey<String>('bill-name'),
            controller: _controller,
            maxLength: BillValidator.maxLabelLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (String label) => bloc.add(BillEditorRenamed(label)),
            onSubmitted: (String _) => bloc.add(const BillEditorNextPressed()),
            onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: strings.billNameLabel,
              hintText: strings.billNameHint,
              counterText: '',
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(HisaabRadii.chip))),
            ),
          ),
          if (delete != null) ...<Widget>[
            const SizedBox(height: HisaabSpacing.l),
            HisaabChip(key: const ValueKey<String>('delete-bill'), label: strings.delete, icon: AppIcons.delete, onPressed: delete),
          ],
        ],
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: HisaabSpacing.s,
            runSpacing: HisaabSpacing.s,
            children: <Widget>[
              for (final BillKind kind in BillKind.values)
                HisaabChip(
                  key: ValueKey<String>('bill-${kind.name}'),
                  label: strings.billName(kind.name),
                  selected: widget.form.kind == Option<BillKind>.of(kind),
                  onPressed: () => bloc.add(BillEditorKindPicked(kind, strings.billName(kind.name))),
                ),
            ],
          ),
          const SizedBox(height: HisaabSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('bill-next'),
              label: strings.next,
              icon: AppIcons.next,
              onPressed: widget.form.label.trim().isEmpty ? null : () => bloc.add(const BillEditorNextPressed()),
            ),
          ),
        ],
      ),
    );
  }
}
