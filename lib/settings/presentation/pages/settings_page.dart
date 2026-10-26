import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/widgets/screen_in_progress.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Settings (SPEC FR-SE): money, categories, look and data. A placeholder until its milestone.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: strings.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const AppIcon(AppIcons.back),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(top: false, child: ScreenInProgress(title: strings.settings)),
    );
  }
}
