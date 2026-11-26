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
import '../../domain/entities/reached_line.dart';
import 'home_lines_event.dart';
import 'home_lines_state.dart';

/// Owns the nudge slot's items below a bill line: the reached line, the install line and the
/// missed-log line (SPEC FR-HO-3, BR-17, BR-23, D170 to D173).
///
/// The app adds [HomeLinesPointReached] at a cold start and a resume, and the page's driver adds
/// [HomeLinesEvaluated] once Home is ready; only that event can make a line appear. Every other
/// event, driven by the user's own acts, can only make it leave.
class HomeLinesBloc extends Bloc<HomeLinesEvent, HomeLinesState> {
  /// Writes `asked_on` through [_markAsked], the install line's seen flag through [_settings] and the
  /// reached line's shown columns through [_recurring]; a tap ticks through [_haptics].
  HomeLinesBloc({required this._markAsked, required this._clock, required this._haptics, this._settings, this._recurring})
      : super(const HomeLinesState()) {
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
    // why: the reached line is written once per target however often it is reported.
    on<HomeLinesReachedShown>(_onReachedShown, transformer: droppable());
    // why: no tapped guard and no transformer: the tap only ticks, and the line stays when the sheet
    // closes (AC-R5).
    on<HomeLinesReachedTapped>(_onReachedTapped);
    on<HomeLinesReachedGone>((HomeLinesReachedGone event, Emitter<HomeLinesState> emit) => _remove(emit));
  }

  final MarkMissedLogAsked _markAsked;
  final Clock _clock;
  final Haptics _haptics;

  /// Where the install line's seen flag is written; none (older constructions) means no install line.
  final BudgetSettingsRepository? _settings;

  /// Where the reached line is written as shown; none (older constructions) means no reached line.
  final RecurringRepository? _recurring;

  void _onPointReached(HomeLinesPointReached event, Emitter<HomeLinesState> emit) =>
      emit(state.copyWith(pointPending: true));

  // why: one latched point resolves once, at the first evaluation, so a later reload or a habits
  // load can never bring the line in mid-view (E106).
  void _onEvaluated(HomeLinesEvaluated event, Emitter<HomeLinesState> emit) {
    if (!state.pointPending) {
      return;
    }
    final Option<ReachedLine> reached = _recurring != null && _slotFree(event.facts) ? event.facts.reached : const Option<ReachedLine>.none();
    final bool install = _settings != null && reached.isNone() && _installFits(event.facts);
    final Option<MissedLog> decided =
        install || reached.isSome() || _askedAlready(event.facts) ? const Option<MissedLog>.none() : _decide(event.facts);
    emit(
      state.copyWith(
        missed: decided,
        install: install,
        installMarked: false,
        reached: reached,
        reachedMarked: false,
        serial: state.serial + (decided.isSome() || install || reached.isSome() ? 1 : 0),
        asked: false,
        tapped: false,
        pointPending: false,
      ),
    );
  }

  // why: the one slot goes to a bill line first, then the reached line, the install line and the
  // missed-log line; an over state or *No income* shows none of them (FR-HO-3, E107, E108, E149).
  static bool _slotFree(HomeLinesFacts facts) => !facts.noIncome && !facts.overState && !facts.billLineShowing;

  static bool _installFits(HomeLinesFacts facts) => facts.installDue && _slotFree(facts);

  // why: the habit index is not reloaded when asked_on is written, so one question a day is also
  // kept here (L3).
  bool _askedAlready(HomeLinesFacts facts) =>
      state.askedOn.match(() => false, (CalendarDate day) => day == CalendarDate.fromDateTime(facts.now));

  static Option<MissedLog> _decide(HomeLinesFacts facts) {
    final HabitIndex? index = facts.index;
    if (index == null || !_slotFree(facts)) {
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

  Future<void> _onReachedShown(HomeLinesReachedShown event, Emitter<HomeLinesState> emit) async {
    final ReachedLine? line = state.reached.toNullable();
    if (line != null && line.pending && !state.reachedMarked) {
      await _markReached(line, emit);
    }
  }

  // why: a tap writes nothing (AC-R5): the line's rule is from its evaluation point, and writing it
  // could revert the user's own edit since. An unwritten line stays pending for the next point.
  void _onReachedTapped(HomeLinesReachedTapped event, Emitter<HomeLinesState> emit) {
    if (state.reached.isNone()) {
      return;
    }
    // why: tapped only lets focus go to the "Today" heading if the line then leaves; it guards nothing.
    emit(state.copyWith(tapped: true));
    unawaited(_haptics.tick());
  }

  // why: only the two reached columns are written: the line's rule is from its evaluation point, so
  // writing it whole could undo an edit since or move next_due back.
  Future<void> _markReached(ReachedLine line, Emitter<HomeLinesState> emit) async {
    final RecurringRepository? recurring = _recurring;
    if (recurring == null) {
      return;
    }
    final Either<Failure, Unit> written = await recurring.markTargetReached(line.saving.id, line.target, _clock.today()).run();
    written.match(_logReachedFailure, (Unit _) => emit(state.copyWith(reachedMarked: true)));
  }

  void _removeIf(int categoryId, Emitter<HomeLinesState> emit) {
    if (state.missed.match(() => false, (MissedLog line) => line.category.id == categoryId)) {
      _remove(emit);
    }
  }

  void _remove(Emitter<HomeLinesState> emit) {
    if (state.missed.isSome() || state.install || state.reached.isSome()) {
      emit(_cleared());
    }
  }

  void _onMidnight(HomeLinesMidnight event, Emitter<HomeLinesState> emit) => emit(_cleared().copyWith(pointPending: false));

  HomeLinesState _cleared() => state.copyWith(
        missed: const Option<MissedLog>.none(),
        install: false,
        installMarked: false,
        reached: const Option<ReachedLine>.none(),
        reachedMarked: false,
        asked: false,
        tapped: false,
      );

  // why: the type only. A failure's message can carry a row's text, and nothing about a habit
  // may reach the log (NFR-3, BR-17).
  static void _logFailure(Failure failure) =>
      AppLogger.log(tag: 'home_lines.asked_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});

  static void _logReachedFailure(Failure failure) =>
      AppLogger.log(tag: 'home_lines.reached_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
}
