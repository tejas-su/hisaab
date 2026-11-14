import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'fix_event.dart';
import 'fix_state.dart';

/// Owns the *Fix my number* sheet: hisaab's figure, what the user typed, the guard question and the
/// write (SPEC FR-FX). Driven by the sheet's keys and by [LedgerRepository.changes], which reloads
/// `H` behind the digits.
///
/// [successOnSave] fires the `success` haptic as the write lands. The Settings door wants that (the
/// sheet exits and no hero rolls); the Home door leaves it to Home, which fires it as the hero rolls
/// (FR-FX-5 AC-2, AC-5).
class FixBloc extends Bloc<FixEvent, FixState> {
  FixBloc({
    required this._getCycleSummary,
    required this._fix,
    required this._ledger,
    required this._clock,
    required this._haptics,
    this.successOnSave = true,
  }) : super(const FixLoading()) {
    // why: a reload (open, Try again, a write elsewhere) cancels one still reading, so an older,
    // slower read can't land last.
    on<FixLoadRequested>(_onLoadRequested, transformer: restartable());
    on<FixKeyPressed>(_onKeyPressed);
    on<FixBackspacePressed>(_onBackspacePressed);
    on<FixCleared>(_onCleared);
    // why: a second tap while the write is in flight must not post twice (E85).
    on<FixSavePressed>(_onSavePressed, transformer: droppable());
    // why: droppable too, so Yes tapped twice is one entry; the 300 ms ignore below covers the
    // different case of a late tap landing on the keys that replaced *Fix it*.
    on<FixGuardAnswered>(_onGuardAnswered, transformer: droppable());
    on<FixBackPressed>(_onBackPressed);
    _changes = _ledger.changes.listen((void _) => add(const FixLoadRequested()));
  }

  /// How long the guard keys ignore input after they appear (FR-FX-4 AC-2).
  static const Duration guardIgnoreWindow = Duration(milliseconds: 300);

  final GetCycleSummary _getCycleSummary;
  final FixMyNumberUseCase _fix;
  final LedgerRepository _ledger;
  final Clock _clock;
  final Haptics _haptics;

  /// Whether the bloc itself fires `success` when the write lands.
  final bool successOnSave;
  late final StreamSubscription<void> _changes;

  Future<void> _onLoadRequested(FixLoadRequested event, Emitter<FixState> emit) async {
    final FixState current = state;
    if (current is FixDone || (current is FixReady && current.saving)) {
      return;
    }
    if (current is FixFailed) {
      emit(const FixLoading());
    }
    final Either<Failure, CycleSummary> loaded = await _getCycleSummary(const NoParams()).run();
    loaded.match(
      (Failure failure) => _onLoadFailed(failure, emit),
      (CycleSummary summary) => emit(_withSummary(state, summary)),
    );
  }

  void _onLoadFailed(Failure failure, Emitter<FixState> emit) {
    _log('fix.load_failed', failure);
    // why: a failed refresh behind typed digits keeps the sheet usable; the write re-checks anyway.
    if (state is! FixReady) {
      emit(FixFailed(failure));
    }
  }

  // why: a reload keeps the digits and the guard; the notice says things changed only when the
  // figure moved and a gap remains (E84).
  FixReady _withSummary(FixState current, CycleSummary summary) {
    if (current is! FixReady) {
      return FixReady(summary: summary);
    }
    final bool held = FixMyNumber.held(summary) == FixMyNumber.held(current.summary);
    final FixReady next = current.copyWith(summary: summary);
    return !held && current.typed.isSome() && next.preview is FixChange ? next.copyWith(notice: FixNotice.changed) : next;
  }

  void _onKeyPressed(FixKeyPressed event, Emitter<FixState> emit) => _edit(
        emit,
        (Option<int> typed) => AmountInput.append(typed.getOrElse(() => 0), event.key).map(Option<int>.of),
      );

  void _onBackspacePressed(FixBackspacePressed event, Emitter<FixState> emit) => _edit(
        emit,
        (Option<int> typed) => Option<Option<int>>.of(_dropDigit(typed)),
      );

  void _onCleared(FixCleared event, Emitter<FixState> emit) {
    final FixState current = state;
    if (current is FixReady && current.guard.isNone() && !current.saving) {
      emit(current.copyWith(typed: const Option<int>.none(), notice: FixNotice.none));
    }
  }

  // why: the last digit leaves the amount empty, not 0, because empty and a typed 0 are different (E74).
  static Option<int> _dropDigit(Option<int> typed) =>
      typed.flatMap((int rupees) => rupees < 10 ? const Option<int>.none() : Option<int>.of(AmountInput.backspace(rupees)));

  // [change] answers none for a refused key, or the new amount, which is itself none when emptied.
  void _edit(Emitter<FixState> emit, Option<Option<int>> Function(Option<int> typed) change) {
    final FixState current = state;
    if (current is! FixReady || current.guard.isSome() || current.saving) {
      return;
    }
    change(current.typed).match(
      () {
        unawaited(_haptics.reject());
        emit(current.copyWith(rejections: current.rejections + 1));
      },
      (Option<int> typed) {
        unawaited(_haptics.tick());
        emit(current.copyWith(typed: typed, notice: FixNotice.none));
      },
    );
  }

  Future<void> _onSavePressed(FixSavePressed event, Emitter<FixState> emit) async {
    final FixState current = state;
    if (current is! FixReady || current.saving || current.guard.isSome()) {
      return;
    }
    final FixPreview preview = current.preview;
    if (preview is FixLarge) {
      emit(current.copyWith(guard: Option<FixGuard>.of(FixGuard(openedAt: _clock.now(), seenGapRupees: _seenGap(current))), notice: FixNotice.none));
      return;
    }
    if (preview is FixChange) {
      await _write(current, _seenGap(current), emit);
    }
  }

  Future<void> _onGuardAnswered(FixGuardAnswered event, Emitter<FixState> emit) async {
    final FixState current = state;
    final FixGuard? guard = current is FixReady ? current.guard.toNullable() : null;
    if (current is! FixReady || guard == null || current.saving || _tooSoon(guard)) {
      return;
    }
    if (!event.yes) {
      emit(_countOnlyThisMonth(current));
      return;
    }
    await _write(current, guard.seenGapRupees, emit);
  }

  bool _tooSoon(FixGuard guard) => _clock.now().difference(guard.openedAt) < guardIgnoreWindow;

  void _onBackPressed(FixBackPressed event, Emitter<FixState> emit) {
    final FixState current = state;
    if (current is FixReady && current.guard.isSome() && !current.saving) {
      emit(_countOnlyThisMonth(current));
    }
  }

  // why: nothing in the typed total is worth keeping, so the digits clear and the notice asks for this
  // month's money only (X11).
  static FixReady _countOnlyThisMonth(FixReady current) =>
      current.copyWith(typed: const Option<int>.none(), guard: const Option<FixGuard>.none(), notice: FixNotice.countOnly);

  int _seenGap(FixReady ready) => FixMyNumber.signedRupees(ready.summary, ready.typed.getOrElse(() => 0));

  Future<void> _write(FixReady current, int seenGap, Emitter<FixState> emit) async {
    final int typed = current.typed.getOrElse(() => 0);
    emit(current.copyWith(saving: true, notice: FixNotice.none));
    final Either<Failure, Entry> saved = await _fix(FixParams(typedRupees: typed, seenGapRupees: seenGap)).run();
    await saved.match(
      (Failure failure) => _onWriteFailed(failure, current, emit),
      (Entry entry) async => _onWritten(entry, current, emit),
    );
  }

  void _onWritten(Entry entry, FixReady before, Emitter<FixState> emit) {
    if (successOnSave) {
      unawaited(_haptics.success());
    }
    emit(FixDone(FixOutcome(entry: entry, safeToday: _heroAfter(before))));
  }

  // why: the hero never shows below ₹0, and a fix changes only the pool, never today's spending (BR-18).
  static Money _heroAfter(FixReady before) {
    final FixPreview preview = before.preview;
    final Money after = preview is FixChange ? preview.shareAfter - before.summary.spentToday : before.summary.safeToday;
    return after.isNegative ? Money.zero : after;
  }

  Future<void> _onWriteFailed(Failure failure, FixReady before, Emitter<FixState> emit) async {
    _log('fix.save_failed', failure);
    unawaited(_haptics.reject());
    final bool refused = failure is FixStaleFailure || failure is FixNothingToFixFailure;
    final FixReady reset = before.copyWith(
      saving: false,
      guard: const Option<FixGuard>.none(),
      notice: refused ? FixNotice.changed : FixNotice.saveFailed,
    );
    emit(reset);
    if (refused) {
      await _refresh(reset, emit);
    }
  }

  // why: a refused save shows the figure as it is now, so the next press compares with what is on screen.
  Future<void> _refresh(FixReady reset, Emitter<FixState> emit) async {
    final Either<Failure, CycleSummary> loaded = await _getCycleSummary(const NoParams()).run();
    loaded.match((Failure failure) => _log('fix.refresh_failed', failure), (CycleSummary summary) => emit(reset.copyWith(summary: summary)));
  }

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
