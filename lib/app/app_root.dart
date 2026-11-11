import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../core/extensions/build_context_extensions.dart';
import '../settings/settings.dart';
import 'bloc/launch_bloc.dart';
import 'bloc/launch_event.dart';
import 'bloc/launch_state.dart';
import 'routes.dart';
import 'widgets/startup_failure_view.dart';

/// Shows onboarding on first run and the app afterwards (SPEC FR-ON-1).
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, required this.getIt});

  final GetIt getIt;

  @override
  Widget build(BuildContext context) => BlocProvider<LaunchBloc>(
        create: (BuildContext _) => LaunchBloc(preferences: getIt<AppPreferencesRepository>())..add(const LaunchStarted()),
        child: BlocBuilder<LaunchBloc, LaunchState>(
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
        ),
      );

  /// Rebuilds the app on the data a restore, an undo or *Delete everything* left (D139).
  static void _reload(BuildContext context) {
    context.read<LaunchBloc>().add(const LaunchDataReplaced());
    context.read<ThemeBloc>().add(const ThemeLoadRequested());
  }
}
