import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/hisaab_colors.dart';
import '../core/design/hisaab_theme.dart';
import '../core/layout/app_layout_scope.dart';
import '../home/home.dart';
import '../l10n/gen/app_localizations.dart';
import '../spends/spends.dart';
import 'app_shell.dart';
import 'widgets/startup_failure_view.dart';

/// The root widget: theme, localisation (en_IN), adaptive layout and the shell.
class HisaabApp extends StatelessWidget {
  /// Creates the app; [startupFailed] shows a recovery message instead of the shell.
  const HisaabApp({super.key, this.startupFailed = false});

  final bool startupFailed;

  static const Locale locale = Locale('en', 'IN');

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: HisaabTheme.light(),
        darkTheme: HisaabTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) => _EdgeToEdge(child: AppLayoutScope(child: child ?? const SizedBox())),
        home: startupFailed ? const StartupFailureView() : const AppShell(home: HomePage(), spends: SpendsPage()),
      );
}

/// Transparent system bars with icons that match the theme, for Android edge-to-edge.
class _EdgeToEdge extends StatelessWidget {
  const _EdgeToEdge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).extension<HisaabColors>() == HisaabColors.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
