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

/// Step 1 of the bill editor: type a name, or tap a common bill under the field to fill it in; Next moves on.
///
/// The text field's controller is this widget's own leaf state.
class BillNameStep extends StatefulWidget {
  const BillNameStep({super.key, required this.form});

  final BillEditorInProgress form;

  @override
  State<BillNameStep> createState() => _BillNameStepState();
}

class _BillNameStepState extends State<BillNameStep> {
  static const double _baseFontSize = 14;
  static const double _oneColumnScale = 1.3;

  late final TextEditingController _controller = TextEditingController(text: widget.form.label);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fills the field with [label] and closes the keyboard, so Next is in view.
  void _pick(BillKind kind, String label) {
    _controller.text = label;
    FocusScope.of(context).unfocus();
    context.read<BillEditorBloc>().add(BillEditorKindPicked(kind, label));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillEditorBloc bloc = context.read<BillEditorBloc>();
    // why: two equal columns line up with the field and the key; at large text the labels wrap
    // unevenly, so one column keeps every pill the same height.
    final int columns = MediaQuery.textScalerOf(context).scale(_baseFontSize) > _baseFontSize * _oneColumnScale ? 1 : 2;
    final String typed = widget.form.label.trim().toLowerCase();
    final bool namesABill = BillKind.values.any((BillKind kind) => strings.billName(kind.name).toLowerCase() == typed);
    // why: a pill replaces the name, so with a name typed only the bills it could still become are offered. A
    // picked bill (shown again after Back) or a name typed in full keeps all of them.
    final List<BillKind> kinds = <BillKind>[
      for (final BillKind kind in BillKind.values)
        if (widget.form.kind.isSome() || namesABill || strings.billName(kind.name).toLowerCase().startsWith(typed))
          kind,
    ];
    final bool showPills = kinds.isNotEmpty;
    return AdaptiveSplit(
      // why: the step sits under the editor's app bar, so window-coordinate panes would push Next off-screen.
      fullWindow: false,
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
            ),
          ),
          // why: right under the field, the pills read as ways to fill it in, not as more buttons beside Next.
          if (showPills) ...<Widget>[
            const SizedBox(height: HisaabSpacing.l),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = (constraints.maxWidth - HisaabSpacing.s * (columns - 1)) / columns;
                return Wrap(
                  spacing: HisaabSpacing.s,
                  runSpacing: HisaabSpacing.s,
                  children: <Widget>[
                    for (final BillKind kind in kinds)
                      SizedBox(
                        width: width,
                        child: HisaabChip(
                          key: ValueKey<String>('bill-${kind.name}'),
                          label: strings.billName(kind.name),
                          expand: true,
                          selected:
                              widget.form.kind == Option<BillKind>.of(kind) ||
                              (namesABill && typed == strings.billName(kind.name).toLowerCase()),
                          onPressed: () => _pick(kind, strings.billName(kind.name)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      controls: SizedBox(
        width: double.infinity,
        child: SignalKey(
          key: const ValueKey<String>('bill-next'),
          label: strings.next,
          icon: AppIcons.next,
          onPressed: widget.form.label.trim().isEmpty ? null : () => bloc.add(const BillEditorNextPressed()),
        ),
      ),
    );
  }
}
