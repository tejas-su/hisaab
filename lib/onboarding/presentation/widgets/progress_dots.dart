import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_motion.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/onboarding_step.dart';

/// Three bars showing which onboarding question this is; the current one is long and ink.
class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final int total = OnboardingStep.values.length;
    return Semantics(
      label: AppLocalizations.of(context).onboardingProgress(step.index + 1, total),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final OnboardingStep each in OnboardingStep.values)
            AnimatedContainer(
              duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.press * 2,
              curve: HisaabMotion.easeOut,
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 3),
              width: each == step ? 28 : 12,
              height: 6,
              decoration: BoxDecoration(
                color: each == step ? context.colors.ink : context.colors.hairline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
