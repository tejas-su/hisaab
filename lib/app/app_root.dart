import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../core/extensions/build_context_extensions.dart';
import '../settings/settings.dart';
import 'cubit/launch_cubit.dart';
import 'cubit/launch_state.dart';
import 'routes.dart';
import 'widgets/startup_failure_view.dart';

/// Shows onboarding on first run and the app afterwards (SPEC FR-ON-1).
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, required this.getIt});

  final GetIt getIt;

  @override
  Widget build(BuildContext context) => BlocProvider<LaunchCubit>(
        create: (BuildContext _) => LaunchCubit(preferences: getIt<AppPreferencesRepository>())..start(),
        child: BlocBuilder<LaunchCubit, LaunchState>(
          builder: (BuildContext context, LaunchState state) => switch (state) {
            LaunchLoading() => ColoredBox(color: context.colors.background, child: const SizedBox.expand()),
            LaunchNeedsOnboarding() => AppRoutes.onboarding(getIt, onFinished: context.read<LaunchCubit>().onboardingFinished),
            LaunchReady(:final bool assemble) => AppRoutes.main(getIt, assemble: assemble),
            LaunchFailed() => const StartupFailureView(),
          },
        ),
      );
}
