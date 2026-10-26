import 'package:flutter/material.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/hisaab_dimensions.dart';
import '../../core/extensions/build_context_extensions.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shell_destination.dart';
import 'add_key.dart';
import 'dock_item.dart';

/// The floating bottom dock: Home · Add · Spends (UI_DESIGN §4), used when one pane is visible.
///
/// Positions never change (DECISIONS D13). The marigold Add key opens the Add tray.
class HisaabDock extends StatelessWidget {
  const HisaabDock({super.key, required this.selected, required this.onSelected, required this.onAdd});

  final ShellDestination selected;
  final ValueChanged<ShellDestination> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: HisaabSizes.dockHeight),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.colors.hairline),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: DockItem(
              icon: AppIcons.home,
              label: strings.navHome,
              selected: selected == ShellDestination.home,
              onPressed: () => onSelected(ShellDestination.home),
            ),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(flex: 3, child: AddKey(onAdd: onAdd)),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(
            flex: 2,
            child: DockItem(
              icon: AppIcons.spends,
              label: strings.navSpends,
              selected: selected == ShellDestination.spends,
              onPressed: () => onSelected(ShellDestination.spends),
            ),
          ),
        ],
      ),
    );
  }
}
