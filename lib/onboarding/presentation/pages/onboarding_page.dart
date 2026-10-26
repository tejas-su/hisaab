import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/onboarding_step.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/bill_editor_view.dart';
import '../widgets/bills_step.dart';
import '../widgets/income_step.dart';
import '../widgets/payday_step.dart';

/// Onboarding: three questions, then Home (SPEC FR-ON). Needs an [OnboardingCubit] above it.
///
/// Back steps back through the questions; on the first one it leaves the app. [onFinished]
/// runs once everything is saved.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) => BlocConsumer<OnboardingCubit, OnboardingState>(
        listenWhen: (OnboardingState previous, OnboardingState current) => current is OnboardingDone,
        listener: (BuildContext context, OnboardingState state) => onFinished(),
        builder: (BuildContext context, OnboardingState state) => PopScope(
          canPop: _canLeave(state),
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              context.read<OnboardingCubit>().back();
            }
          },
          child: Scaffold(body: _body(state)),
        ),
      );

  static bool _canLeave(OnboardingState state) =>
      state is OnboardingInProgress &&
      state.draft.step == OnboardingStep.income &&
      state.picker == PaydayPicker.none &&
      state.billEditor.isNone();

  static Widget _body(OnboardingState state) => switch (state) {
        OnboardingLoading() || OnboardingDone() => const SizedBox.expand(),
        OnboardingFinishing(:final draft) => BillsStep(draft: draft, busy: true),
        OnboardingInProgress() => _step(state),
      };

  static Widget _step(OnboardingInProgress state) => state.billEditor.match(
        () => switch (state.draft.step) {
          OnboardingStep.income => IncomeStep(state: state),
          OnboardingStep.payday => PaydayStep(state: state),
          OnboardingStep.bills => BillsStep(draft: state.draft, saveFailed: state.saveFailed),
        },
        (BillEditor editor) => BillEditorView(editor: editor, draft: state.draft, rejections: state.rejections),
      );
}
