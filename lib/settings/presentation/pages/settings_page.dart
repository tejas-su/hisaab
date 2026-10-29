import 'package:flutter/material.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../widgets/settings_row.dart';

/// Settings (SPEC FR-SE), one level deep. Today it holds the Money group's Fixed bills, which
/// [onOpenBills] opens; the other groups arrive with their milestones.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onOpenBills});

  final VoidCallback onOpenBills;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: HisaabBackButton.leadingWidth,
        leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
        titleSpacing: HisaabSpacing.s,
        title: Text(strings.settings),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.xl),
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, bottom: HisaabSpacing.s),
              child: Semantics(header: true, child: Text(strings.settingsMoney, style: text.titleLarge)),
            ),
            Material(
              color: context.colors.surface,
              shape: HisaabShapes.squircle(HisaabRadii.card),
              clipBehavior: Clip.antiAlias,
              child: SettingsRow(
                key: const ValueKey<String>('open-bills'),
                icon: AppIcons.recurring,
                label: strings.fixedBills,
                onTap: onOpenBills,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
