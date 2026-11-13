import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/shortcut_rows_bloc.dart';
import '../bloc/shortcut_rows_event.dart';
import '../bloc/shortcut_rows_state.dart';
import 'settings_row.dart';

/// Settings' *Shortcuts* group, heading included: *Add a widget* and *Add to quick settings*, each
/// opening Android's own dialog (SPEC FR-SE-6, mockup 38 §6). A row the phone can't do is left
/// out, and with neither the whole group is (AC-3); it never offers either unasked.
///
/// Needs a [ShortcutRowsBloc] above it.
class ShortcutsGroup extends StatelessWidget {
  const ShortcutsGroup({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ShortcutRowsBloc, ShortcutRowsState>(
        builder: (BuildContext context, ShortcutRowsState state) => switch (state) {
          ShortcutRowsReady() when state.any => _group(context, state),
          ShortcutRowsReady() || ShortcutRowsLoading() => const SizedBox.shrink(),
        },
      );

  Widget _group(BuildContext context, ShortcutRowsReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ShortcutRowsBloc bloc = context.read<ShortcutRowsBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
          child: Semantics(header: true, child: Text(strings.settingsShortcuts, style: Theme.of(context).textTheme.titleLarge)),
        ),
        Material(
          color: context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.card),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              if (state.canAddWidget)
                SettingsRow(
                  key: const ValueKey<String>('add-widget'),
                  icon: AppIcons.addWidget,
                  label: strings.settingsAddWidget,
                  detail: strings.settingsAddWidgetHint,
                  onTap: () => bloc.add(const ShortcutRowsWidgetTapped()),
                ),
              if (state.canAddWidget && state.canAddTile)
                Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline),
              if (state.canAddTile)
                SettingsRow(
                  key: const ValueKey<String>('add-tile'),
                  icon: AppIcons.addSpendTile,
                  label: strings.settingsAddTile,
                  detail: strings.settingsAddTileHint,
                  onTap: () => bloc.add(const ShortcutRowsTileTapped()),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
