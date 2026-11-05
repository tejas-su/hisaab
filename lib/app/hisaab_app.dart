import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../core/design/hisaab_colors.dart';
import '../core/design/hisaab_theme.dart';
import '../core/extensions/build_context_extensions.dart';
import '../core/layout/app_layout_scope.dart';
import '../l10n/gen/app_localizations.dart';
import '../settings/settings.dart';
import 'app_root.dart';
import 'widgets/startup_failure_view.dart';

/// The root widget: theme, localisation (en_IN), adaptive layout and the first screen.
class HisaabApp extends StatelessWidget {
  /// Creates the app with its registered services in [getIt].
  const HisaabApp({super.key, required GetIt this.getIt}) : startupFailed = false;

  /// Creates the app showing only a recovery message, for when the database can't be opened.
  const HisaabApp.startupFailed({super.key})
      : getIt = null,
        startupFailed = true;

  final GetIt? getIt;
  final bool startupFailed;

  static const Locale locale = Locale('en', 'IN');

  @override
  Widget build(BuildContext context) => switch (getIt) {
        final GetIt services when !startupFailed => BlocProvider<ThemeBloc>(
            create: (BuildContext _) =>
                ThemeBloc(preferences: services<AppPreferencesRepository>())..add(const ThemeLoadRequested()),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (BuildContext context, ThemeState state) => _app(
                themeMode: _themeModeFor(state.choice),
                home: AppRoot(getIt: services),
              ),
            ),
          ),
        _ => _app(themeMode: ThemeMode.system, home: const StartupFailureView()),
      };

  Widget _app({required ThemeMode themeMode, required Widget home}) => MaterialApp(
        onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: HisaabTheme.light(),
        darkTheme: HisaabTheme.dark(),
        themeMode: themeMode,
        // why: a picked look applies in one frame. A cross-fade would ignore reduced motion, and
        // mid-fade the theme matches neither HisaabColors instance, so _EdgeToEdge would pick
        // the wrong system-bar icons.
        themeAnimationDuration: Duration.zero,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) => _EdgeToEdge(child: AppLayoutScope(child: child ?? const SizedBox())),
        home: home,
      );

  static ThemeMode _themeModeFor(ThemeChoice choice) => switch (choice) {
        ThemeChoice.matchPhone => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
      };
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
        statusBarColor: context.colors.clear,
        systemNavigationBarColor: context.colors.clear,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
