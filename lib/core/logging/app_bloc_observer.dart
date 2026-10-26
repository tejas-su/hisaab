import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

/// Writes a log line for each [Bloc] transition: the bloc, the event and the from/to states.
///
/// Only type names are logged, never field values, so amounts and notes stay out of the log
/// (SPEC NFR-3). Installed once in `main` as [Bloc.observer].
class AppBlocObserver extends BlocObserver {
  /// [log] defaults to [AppLogger.log]; a test passes its own to read the lines.
  const AppBlocObserver({this.log = AppLogger.log});

  final void Function({required String tag, Map<String, Object?> data}) log;

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    log(
      tag: 'bloc.transition',
      data: <String, Object?>{
        'bloc': bloc.runtimeType.toString(),
        'event': transition.event.runtimeType.toString(),
        'from': transition.currentState.runtimeType.toString(),
        'to': transition.nextState.runtimeType.toString(),
      },
    );
  }
}
