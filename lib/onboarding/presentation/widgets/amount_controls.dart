import 'package:flutter/material.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';

/// The keypad and Next key shared by the income question and the bill amount.
class AmountControls extends StatelessWidget {
  const AmountControls({super.key, required this.bloc, required this.canContinue});

  final OnboardingBloc bloc;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final bool short = context.layout.heightClass == HeightClass.compact;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Keypad(
          keyHeight: short ? HisaabSizes.minTouchTarget : 60,
          onKey: (String key) => bloc.add(OnboardingKeyPressed(key)),
          onBackspace: () => bloc.add(const OnboardingBackspacePressed()),
          onClear: () => bloc.add(const OnboardingCleared()),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SignalKey(
            label: AppLocalizations.of(context).next,
            icon: AppIcons.next,
            onPressed: canContinue ? () => bloc.add(const OnboardingNextPressed()) : null,
          ),
        ),
      ],
    );
  }
}
