import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../domain/entities/onboarding_step.dart';
import 'progress_dots.dart';

/// The top of an onboarding step: progress, the question, a quiet hint and the step's own
/// content (an amount, a preview).
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step, required this.question, this.hint, this.children = const <Widget>[]});

  final OnboardingStep step;
  final String question;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? quiet = hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(child: ProgressDots(step: step)),
        const SizedBox(height: HisaabSpacing.xl),
        Semantics(header: true, child: Text(question, style: text.headlineSmall?.copyWith(fontSize: 30, height: 34 / 30))),
        if (quiet != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(quiet, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
        ],
        ...children,
      ],
    );
  }
}
