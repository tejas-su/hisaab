import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/time/clock.dart';
import '../../core/usecases/use_case.dart';
import '../../ledger/ledger.dart';
import '../../settings/settings.dart';
import '../../shortcuts/shortcuts.dart';
import 'shortcuts_event.dart';
import 'shortcuts_state.dart';

/// Keeps the home-screen widget's snapshot fresh and holds a widget, tile or shortcut tap until
/// the screen in view follows it (SPEC FR-WG-4 to FR-WG-7, widget spec §7–8).
///
/// Driven by [ShortcutsStarted] (the tap that started the app), [ShortcutsPublishRequested]
/// (every write through the ledger and rule change streams, plus the triggers the app root adds)
/// and the platform's taps.
class ShortcutsBloc extends Bloc<ShortcutsEvent, ShortcutsState> {
  ShortcutsBloc({
    required this._project,
    required this._preferences,
    required this._platform,
    required this._clock,
    required this._words,
    required LedgerRepository ledger,
    required RecurringRepository recurring,
  }) : super(const ShortcutsIdle()) {
    // why: a snapshot written to the system can't be taken back by a cancel; one at a time, in
    // order, so the newest data is always written last (widget spec §7).
    on<ShortcutsPublishRequested>(_onPublishRequested, transformer: sequential());
    on<ShortcutsStarted>(_onStarted);
    on<ShortcutsLaunched>((ShortcutsLaunched event, Emitter<ShortcutsState> emit) => emit(ShortcutsLaunchPending(event.action)));
    on<ShortcutsLaunchHandled>((ShortcutsLaunchHandled event, Emitter<ShortcutsState> emit) => emit(const ShortcutsIdle()));
    _launches = _platform.launches.listen((LaunchAction action) => add(ShortcutsLaunched(action)));
    _changes = ledger.changes.listen((void _) => add(const ShortcutsPublishRequested()));
    _ruleChanges = recurring.changes.listen((void _) => add(const ShortcutsPublishRequested()));
  }

  final ProjectWidgetDays _project;
  final AppPreferencesRepository _preferences;
  final ShortcutsPlatform _platform;
  final Clock _clock;
  final WidgetWords _words;
  late final StreamSubscription<LaunchAction> _launches;
  late final StreamSubscription<void> _changes;
  late final StreamSubscription<void> _ruleChanges;

  Future<void> _onStarted(ShortcutsStarted event, Emitter<ShortcutsState> emit) async =>
      (await _platform.launchAction()).map((LaunchAction action) => emit(ShortcutsLaunchPending(action)));

  Future<void> _onPublishRequested(ShortcutsPublishRequested event, Emitter<ShortcutsState> emit) async {
    final Either<Failure, WidgetSnapshot> snapshot = await _preferences
        .themeChoice()
        .flatMap(
          (ThemeChoice look) => _project(const NoParams()).map(
            (List<ProjectedDay> days) => WidgetSnapshotMapper.of(days, look: look, writtenAt: _clock.now(), words: _words),
          ),
        )
        .run();
    await snapshot.match(
      (Failure failure) async =>
          AppLogger.log(tag: 'shortcuts.project_failed', data: <String, Object?>{'type': failure.runtimeType.toString()}),
      _platform.publish,
    );
  }

  @override
  Future<void> close() async {
    await _launches.cancel();
    await _changes.cancel();
    await _ruleChanges.cancel();
    return super.close();
  }
}
