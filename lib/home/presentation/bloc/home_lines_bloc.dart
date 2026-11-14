import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../habits/habits.dart';
import '../../../ledger/ledger.dart';
import 'home_lines_event.dart';
import 'home_lines_state.dart';

/// Owns the nudge slot's lowest item, the missed-log line (SPEC FR-HO-3, BR-17, D170 to D173).
///
/// The app adds [HomeLinesPointReached] at a cold start and a resume, and the page's driver adds
/// [HomeLinesEvaluated] once Home is ready; only that event can make a line appear. Every other
/// event, driven by the user's own acts, can only make it leave.
class HomeLinesBloc extends Bloc<HomeLinesEvent, HomeLinesState> {
  /// Writes `asked_on` through [_markAsked]; a tap ticks through [_haptics].
  HomeLinesBloc({required this._markAsked, required this._clock, required this._haptics, this._settings}) : super(const HomeLinesState()) {
    on<HomeLinesPointReached>(_onPointReached);
    on<HomeLinesEvaluated>(_onEvaluated);
    // why: the line is asked once however often it is reported; a second report while the write
    // is in flight must not write twice.
    on<HomeLinesShown>(_onShown, transformer: droppable());
    // why: a second tap while the first is working must not tick or open a second tray (AC-2).
    on<HomeLinesTapped>(_onTapped, transformer: droppable());
    on<HomeLinesTrayClosed>(_onTrayClosed);
    on<HomeLinesEntryLogged>((HomeLinesEntryLogged event, Emitter<HomeLinesState> emit) => _removeIf(event.categoryId, emit));
    on<HomeLinesGateClosed>((HomeLinesGateClosed event, Emitter<HomeLinesState> emit) => _removeIf(event.categoryId, emit));
    on<HomeLinesSlotTaken>((HomeLinesSlotTaken event, Emitter<HomeLinesState> emit) => _remove(emit));
    on<HomeLinesMidnight>(_onMidnight);
    // why: the seen flag is written once however often the line is reported.
    on<HomeLinesInstallShown>(_onInstallShown, transformer: droppable());
    // why: a second tap while the first is working must not tick or open a second sheet.
    on<HomeLinesInstallTapped>(_onInstallTapped, transformer: droppable());
    on<HomeLinesInstallConsumed>(_onInstallConsumed);
  }

  final MarkMissedLogAsked _markAsked;
  final Clock _clock;
  final Haptics _haptics;

  /// Where the install line's seen flag is written; none (older constructions) means no install line.
  final BudgetSettingsRepository? _settings;

  void _onPointReached(HomeLinesPointReached event, Emitter<HomeLinesState> emit) =>
      emit(state.copyWith(pointPending: true));

  // why: one latched point resolves once, at the first evaluation, so a later reload or a habits
  // load can never bring the line in mid-view (E106).
  void _onEvaluated(HomeLinesEvaluated event, Emitter<HomeLinesState> emit) {
    if (!state.pointPending) {
      return;
    }
    final bool install = _settings != null && _installFits(event.facts);
    final Option<MissedLog> decided =
        install || _askedAlready(event.facts) ? const Option<MissedLog>.none() : _decide(event.facts);
    emit(
      state.copyWith(
        missed: decided,
        install: install,
        installMarked: false,
        serial: state.serial + (decided.isSome() || install ? 1 : 0),
        asked: false,
        tapped: false,
        pointPending: false,
      ),
    );
  }

  // why: the one slot goes to a bill line first, then the install line, then the missed-log line; an
  // over state or *No income* shows none of them (FR-HO-3, E107, E108).
  static bool _installFits(HomeLinesFacts facts) =>
      facts.installDue && !facts.noIncome && !facts.overState && !facts.billLineShowing;

  // why: the habit index is not reloaded when asked_on is written, so one question a day is also
  // kept here (L3).
  bool _askedAlready(HomeLinesFacts facts) =>
      state.askedOn.match(() => false, (CalendarDate day) => day == CalendarDate.fromDateTime(facts.now));

  static Option<MissedLog> _decide(HomeLinesFacts facts) {
    final HabitIndex? index = facts.index;
    if (index == null || facts.noIncome || facts.overState || facts.billLineShowing) {
      return const Option<MissedLog>.none();
    }
    return MissedLogDetector.suggest(index, now: facts.now, categories: facts.categories);
  }

  Future<void> _onShown(HomeLinesShown event, Emitter<HomeLinesState> emit) async {
    final MissedLog? line = state.missed.toNullable();
    if (line == null || state.asked) {
      return;
    }
    await _ask(line, emit);
  }

  Future<void> _onTapped(HomeLinesTapped event, Emitter<HomeLinesState> emit) async {
    final MissedLog? line = state.missed.toNullable();
    if (line == null || state.tapped) {
      return;
    }
    emit(state.copyWith(tapped: true));
    unawaited(_haptics.tick());
    if (!state.asked) {
      await _ask(line, emit);
    }
  }

  Future<void> _ask(MissedLog line, Emitter<HomeLinesState> emit) async {
    final Either<Failure, Unit> written = await _markAsked(line.category.id).run();
    written.match(_logFailure, (Unit _) => emit(state.copyWith(asked: true, askedOn: Option<CalendarDate>.of(_clock.today()))));
  }

  void _onTrayClosed(HomeLinesTrayClosed event, Emitter<HomeLinesState> emit) {
    if (state.tapped) {
      _remove(emit);
    }
  }

  Future<void> _onInstallShown(HomeLinesInstallShown event, Emitter<HomeLinesState> emit) async {
    if (state.install && !state.installMarked) {
      await _markInstallSeen(emit);
    }
  }

  Future<void> _onInstallTapped(HomeLinesInstallTapped event, Emitter<HomeLinesState> emit) async {
    if (!state.install || state.tapped) {
      return;
    }
    emit(state.copyWith(tapped: true));
    unawaited(_haptics.tick());
    if (!state.installMarked) {
      await _markInstallSeen(emit);
    }
  }

  Future<void> _markInstallSeen(Emitter<HomeLinesState> emit) async {
    final BudgetSettingsRepository? settings = _settings;
    if (settings == null) {
      return;
    }
    final Either<Failure, Unit> written = await settings.markInstallLineSeen().run();
    written.match(_logFailure, (Unit _) => emit(state.copyWith(installMarked: true)));
  }

  // why: a fix uses the line up (C11), but one already on screen stays until the next point, so a
  // reload after its own write never pulls it out from under the user.
  void _onInstallConsumed(HomeLinesInstallConsumed event, Emitter<HomeLinesState> emit) {
    if (state.install && !state.installMarked) {
      _remove(emit);
    }
  }

  void _removeIf(int categoryId, Emitter<HomeLinesState> emit) {
    if (state.missed.match(() => false, (MissedLog line) => line.category.id == categoryId)) {
      _remove(emit);
    }
  }

  void _remove(Emitter<HomeLinesState> emit) {
    if (state.missed.isSome() || state.install) {
      emit(state.copyWith(missed: const Option<MissedLog>.none(), install: false, installMarked: false, asked: false, tapped: false));
    }
  }

  void _onMidnight(HomeLinesMidnight event, Emitter<HomeLinesState> emit) =>
      emit(state.copyWith(missed: const Option<MissedLog>.none(), install: false, installMarked: false, asked: false, tapped: false, pointPending: false));

  // why: the type only. A failure's message can carry a row's text, and nothing about a habit
  // may reach the log (NFR-3, BR-17).
  static void _logFailure(Failure failure) =>
      AppLogger.log(tag: 'home_lines.asked_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
}
