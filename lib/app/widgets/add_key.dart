import 'package:material_ui/material_ui.dart';

import '../../core/design/app_icons.dart';
import '../../core/widgets/signal_key.dart';
import '../../l10n/gen/app_localizations.dart';

/// The marigold "+ Add" key that opens the Add tray (UI_DESIGN §4): the app's main act.
class AddKey extends StatelessWidget {
  const AddKey({super.key, required this.onAdd});

  final VoidCallback onAdd;

  /// The key's widest size; it shrinks on narrow windows.
  static const double maxWidth = 136;

  @override
  // why: heightFactor keeps the key its own height when the dock gets a loose constraint, as in
  // the tabletop pane's centred dock; a plain Center would stretch the dock to the pane's height.
  Widget build(BuildContext context) => Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: SignalKey(
            key: const ValueKey<String>('add-key'),
            label: AppLocalizations.of(context).add,
            icon: AppIcons.add,
            height: 56,
            onPressed: onAdd,
          ),
        ),
      );
}
