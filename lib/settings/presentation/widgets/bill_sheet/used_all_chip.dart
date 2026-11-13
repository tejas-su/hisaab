import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// *All of it* beside the amount on the *Used* keypad (AC-Y6): fills everything that is set aside,
/// and a second tap clears it. It is [selected] while the amount equals the set-aside amount,
/// which a screen reader hears as "All of it, button, selected" (AC-Y11).
///
/// A null [onPressed] turns it off, when nothing is set aside to use.
class UsedAllChip extends StatelessWidget {
  const UsedAllChip({super.key, required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => HisaabChip(
        label: AppLocalizations.of(context).savingUsedAll,
        selected: selected,
        onSurface: true,
        onPressed: onPressed,
      );
}
