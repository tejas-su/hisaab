import 'package:flutter/widgets.dart';

import '../../../core/design/app_icons.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/theme_choice.dart';

/// How a [ThemeChoice] is shown (SPEC FR-SE-3): its glyph, its words, and what TalkBack reads
/// when the words alone are unclear.
final class LookChoice {
  const LookChoice({required this.icon, required this.label, this.spoken});

  /// The glyph and words for [choice], in the app's language.
  factory LookChoice.of(BuildContext context, ThemeChoice choice) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return switch (choice) {
      ThemeChoice.matchPhone =>
        LookChoice(icon: AppIcons.themeMatchPhone, label: strings.lookMatchPhone, spoken: strings.lookMatchPhoneSemantics),
      ThemeChoice.light => LookChoice(icon: AppIcons.themeLight, label: strings.lookLight),
      ThemeChoice.dark => LookChoice(icon: AppIcons.themeDark, label: strings.lookDark),
    };
  }

  final AppIconData icon;
  final String label;
  final String? spoken;
}
