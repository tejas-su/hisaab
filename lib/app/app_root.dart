import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../core/extensions/build_context_extensions.dart';
import '../core/money/money_formatter.dart';
import '../core/time/clock.dart';
import '../l10n/gen/app_localizations.dart';
import '../ledger/ledger.dart';
import '../settings/settings.dart';
import '../shortcuts/shortcuts.dart';
import 'bloc/launch_bloc.dart';
import 'bloc/launch_event.dart';
import 'bloc/launch_state.dart';
import 'bloc/shortcuts_bloc.dart';
import 'bloc/shortcuts_event.dart';
import 'routes.dart';
import 'widgets/resume_listener.dart';
import 'widgets/startup_failure_view.dart';

/// Shows onboarding on first run and the app afterwards (SPEC FR-ON-1), and keeps the home-screen
/// widget's snapshot fresh across both (FR-WG-5).
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, required this.getIt});

  final GetIt getIt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: <BlocProvider<Object?>>[
        BlocProvider<LaunchBloc>(
          create: (BuildContext _) => LaunchBloc(preferences: getIt<AppPreferencesRepository>())..add(const LaunchStarted()),
        ),
        BlocProvider<ShortcutsBloc>(
          // why: not lazy, so the tap that started the app is read at once, before either root
          // screen asks for it.
          lazy: false,
          create: (BuildContext _) => ShortcutsBloc(
            project: getIt<ProjectWidgetDays>(),
            preferences: getIt<AppPreferencesRepository>(),
            platform: getIt<ShortcutsPlatform>(),
            clock: getIt<Clock>(),
            words: (strings: strings, money: getIt<MoneyFormatter>()),
            ledger: getIt<LedgerRepository>(),
            recurring: getIt<RecurringRepository>(),
          )..add(const ShortcutsStarted()),
        ),
      ],
      child: Builder(builder: _withSnapshotTriggers),
    );
  }

  // why: the snapshot is written whenever the root screen settles (start, onboarding finished, a
  // restore or *Delete everything*), the look changes, or the app comes back (widget spec §7).
  // Writes go through the ledger's streams, which the bloc hears itself.
  Widget _withSnapshotTriggers(BuildContext context) {
    void publish() => context.read<ShortcutsBloc>().add(const ShortcutsPublishRequested());
    return MultiBlocListener(
      listeners: <BlocListener<Object?, Object?>>[
        BlocListener<LaunchBloc, LaunchState>(
          listenWhen: (LaunchState _, LaunchState next) => next is LaunchReady || next is LaunchNeedsOnboarding,
          listener: (BuildContext _, LaunchState _) => publish(),
        ),
        BlocListener<ThemeBloc, ThemeState>(listener: (BuildContext _, ThemeState _) => publish()),
      ],
      child: ResumeListener(onResume: publish, child: _screen()),
    );
  }

  Widget _screen() => BlocBuilder<LaunchBloc, LaunchState>(
        builder: (BuildContext context, LaunchState state) => switch (state) {
          LaunchLoading() => ColoredBox(color: context.colors.background, child: const SizedBox.expand()),
          LaunchNeedsOnboarding() => AppRoutes.onboarding(
              getIt,
              onFinished: () => context.read<LaunchBloc>().add(const LaunchOnboardingFinished()),
              onRestored: () => _reload(context),
            ),
          LaunchReady(:final bool assemble, :final int generation) => KeyedSubtree(
              key: ValueKey<int>(generation),
              child: AppRoutes.main(getIt, assemble: assemble, onDataReplaced: () => _reload(context)),
            ),
          LaunchFailed() => const StartupFailureView(),
        },
      );

  /// Rebuilds the app on the data a restore, an undo or *Delete everything* left (D139).
  static void _reload(BuildContext context) {
    context.read<LaunchBloc>().add(const LaunchDataReplaced());
    context.read<ThemeBloc>().add(const ThemeLoadRequested());
  }
}
