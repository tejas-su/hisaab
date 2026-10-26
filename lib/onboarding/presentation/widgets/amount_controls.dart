import 'package:flutter/material.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../cubit/onboarding_cubit.dart';

/// The keypad and Next key shared by the income question and the bill amount.
class AmountControls extends StatelessWidget {
  const AmountControls({super.key, required this.cubit, required this.canContinue});

  final OnboardingCubit cubit;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final bool short = context.layout.heightClass == HeightClass.compact;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Keypad(
          keyHeight: short ? HisaabSizes.minTouchTarget : 60,
          onKey: cubit.pressKey,
          onBackspace: cubit.backspace,
          onClear: cubit.clear,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SignalKey(
            label: AppLocalizations.of(context).next,
            icon: AppIcons.next,
            onPressed: canContinue ? cubit.next : null,
          ),
        ),
      ],
    );
  }
}
