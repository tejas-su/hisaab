import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/hisaab_back_button.dart';
import '../bloc/bill_editor_bloc.dart';
import '../bloc/bill_editor_event.dart';
import '../bloc/bill_editor_state.dart';
import '../widgets/bill_amount_step.dart';
import '../widgets/bill_day_step.dart';
import '../widgets/bill_name_step.dart';

/// Adds or changes one fixed bill in three questions: name, amount, day (SPEC FR-SE-1).
///
/// Needs a [BillEditorBloc] above it. Back steps back through the questions, then closes the
/// page; saving closes it too. [onDelete], given when changing a bill, offers Delete.
class BillEditorPage extends StatelessWidget {
  const BillEditorPage({super.key, this.onDelete});

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => BlocConsumer<BillEditorBloc, BillEditorState>(
        listenWhen: (BillEditorState previous, BillEditorState current) => current is BillEditorSaved,
        listener: (BuildContext context, BillEditorState _) => Navigator.of(context).pop(),
        builder: (BuildContext context, BillEditorState state) => PopScope(
          canPop: _canLeave(state),
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              context.read<BillEditorBloc>().add(const BillEditorBackPressed());
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leadingWidth: HisaabBackButton.leadingWidth,
              leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: _step(state),
          ),
        ),
      );

  static bool _canLeave(BillEditorState state) => switch (state) {
        BillEditorInProgress(:final BillEditorStage stage, :final bool saving) => stage == BillEditorStage.name && !saving,
        BillEditorSaved() => true,
      };

  Widget _step(BillEditorState state) => switch (state) {
        BillEditorSaved() => const SizedBox.expand(),
        BillEditorInProgress(stage: BillEditorStage.name) => BillNameStep(form: state, onDelete: onDelete),
        BillEditorInProgress(stage: BillEditorStage.amount) => BillAmountStep(form: state),
        BillEditorInProgress(stage: BillEditorStage.day) => BillDayStep(form: state),
      };
}
