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
import '../../../ledger/presentation/rule_words.dart';
import '../bloc/bill_editor_bloc.dart';
import '../bloc/bill_editor_event.dart';
import '../bloc/bill_editor_state.dart';
import 'bill_question.dart';

/// Step 1 of the bill editor: type a name, or tap a common bill (or saving, D120) under the field to fill it in;
/// Next moves on.
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
  void _pick(BillEditorEvent picked, String label) {
    _controller.text = label;
    FocusScope.of(context).unfocus();
    context.read<BillEditorBloc>().add(picked);
  }

  /// The common bills, or for a saving the common savings, that the typed name could still become.
  List<_Pill> _pills(AppLocalizations strings, EntryKind kind) {
    final String typed = widget.form.label.trim().toLowerCase();
    final List<_Pill> all = kind == EntryKind.saved
        ? <_Pill>[
            for (final SavingKind saving in SavingKind.values)
              _Pill(key: 'saving-${saving.name}', label: strings.savingName(saving.name), event: BillEditorSavingPicked(saving, strings.savingName(saving.name))),
          ]
        : <_Pill>[
            for (final BillKind bill in BillKind.values)
              _Pill(
                key: 'bill-${bill.name}',
                label: strings.billName(bill.name),
                event: BillEditorKindPicked(bill, strings.billName(bill.name)),
                picked: widget.form.kind == Option<BillKind>.of(bill),
              ),
          ];
    final bool namesOne = all.any((_Pill pill) => pill.label.toLowerCase() == typed);
    // why: a pill replaces the name, so with a name typed only the ones it could still become are offered. A
    // picked bill (shown again after Back) or a name typed in full keeps all of them.
    final bool keepAll = widget.form.kind.isSome() || namesOne;
    return <_Pill>[
      for (final _Pill pill in all)
        if (keepAll || pill.label.toLowerCase().startsWith(typed))
          pill.copyWith(picked: pill.picked || (namesOne && typed == pill.label.toLowerCase())),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillEditorBloc bloc = context.read<BillEditorBloc>();
    // why: two equal columns line up with the field and the key; at large text the labels wrap
    // unevenly, so one column keeps every pill the same height.
    final int columns = MediaQuery.textScalerOf(context).scale(_baseFontSize) > _baseFontSize * _oneColumnScale ? 1 : 2;
    final List<_Pill> pills = _pills(strings, bloc.kind);
    final bool showPills = pills.isNotEmpty;
    return AdaptiveSplit(
      // why: the step sits under the editor's app bar, so window-coordinate panes would push Next off-screen.
      fullWindow: false,
      header: BillQuestion(
        question: strings.ruleNameQuestion(bloc.kind),
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
              hintText: strings.ruleNameHint(bloc.kind),
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
                    for (final _Pill pill in pills)
                      SizedBox(
                        width: width,
                        child: HisaabChip(
                          key: ValueKey<String>(pill.key),
                          label: pill.label,
                          expand: true,
                          selected: pill.picked,
                          onPressed: () => _pick(pill.event, pill.label),
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

/// One name pill: its test [key], its [label], the [event] a tap adds, and whether it shows [picked].
final class _Pill {
  const _Pill({required this.key, required this.label, required this.event, this.picked = false});

  final String key;
  final String label;
  final BillEditorEvent event;
  final bool picked;

  _Pill copyWith({required bool picked}) => _Pill(key: key, label: label, event: event, picked: picked);
}
