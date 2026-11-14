import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'fix_guard_key.dart';

/// The answer panel that replaces the keypad and *Fix it* when a large higher gap asks "Is all of
/// it from this month?" (SPEC FR-FX-4): two stacked keys, *No* first, then *Yes, add {gap}*.
///
/// [gap] is the amount's text for the *Yes* key. Each press calls its callback; the 300 ms ignore
/// window after the swap lives in the bloc, on the injected clock (E85).
class FixGuardPanel extends StatelessWidget {
  const FixGuardPanel({super.key, required this.gap, required this.spokenGap, required this.onNo, required this.onYes});

  final String gap;

  /// The gap as spoken, for the *Yes* key's label.
  final String spokenGap;
  final VoidCallback onNo;
  final VoidCallback onYes;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FixGuardKey(key: const ValueKey<String>('fix-guard-no'), label: strings.fixGuardNo, onPressed: onNo),
        const SizedBox(height: HisaabSpacing.s),
        FixGuardKey(
          key: const ValueKey<String>('fix-guard-yes'),
          label: strings.fixGuardYes(gap),
          semanticLabel: strings.fixGuardYes(spokenGap),
          onPressed: onYes,
        ),
      ],
    );
  }
}
