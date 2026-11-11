import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
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
///
/// [note] is a small caption with a lock between the keypad and Next: the income question's
/// "It stays on this phone" (D116).
class AmountControls extends StatelessWidget {
  const AmountControls({super.key, required this.bloc, required this.canContinue, this.note});

  final OnboardingBloc bloc;
  final bool canContinue;
  final String? note;

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
        if (note case final String note) ...<Widget>[
          _PrivacyNote(note),
          const SizedBox(height: HisaabSpacing.m),
        ],
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

/// A lock and one quiet line, centred above Next.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    return Row(
      key: const ValueKey<String>('privacy-note'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppIcon(AppIcons.privacy, size: 18, color: context.colors.ink2),
        const SizedBox(width: HisaabSpacing.s),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
