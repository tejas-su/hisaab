import 'package:flutter/material.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/hisaab_dimensions.dart';
import '../../core/extensions/build_context_extensions.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shell_destination.dart';
import 'dock_item.dart';

/// The floating bottom dock used when only one pane is visible (UI_DESIGN §4).
///
/// Positions never change (DECISIONS D13); the marigold Add key joins the centre in M1.
class HisaabDock extends StatelessWidget {
  const HisaabDock({super.key, required this.selected, required this.onSelected});

  final ShellDestination selected;
  final ValueChanged<ShellDestination> onSelected;

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
            child: DockItem(
              icon: AppIcons.home,
              label: strings.navHome,
              selected: selected == ShellDestination.home,
              onPressed: () => onSelected(ShellDestination.home),
            ),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(
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
