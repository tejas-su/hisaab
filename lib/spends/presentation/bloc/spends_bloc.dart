import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/spends_overview.dart';
import '../../domain/usecase/get_spends_overview.dart';
import 'spends_event.dart';
import 'spends_state.dart';

/// Owns the cycle Spends is showing (SPEC FR-SP-1). Driven by [SpendsLoadRequested] (start,
/// resume, midnight), by every ledger write through [LedgerRepository.changes], and by the
/// page's [SpendsEarlierPressed], [SpendsLaterPressed] and [SpendsLimitsAccepted].
class SpendsBloc extends Bloc<SpendsEvent, SpendsState> {
  SpendsBloc({
    required this._getOverview,
    required this._applyLimits,
    required LedgerRepository ledger,
    required this._haptics,
  }) : super(const SpendsLoading()) {
    // why: one restartable handler for load, ‹ and ›, so the newest request wins and quick taps
    // or a write mid-load never show an older cycle, or older numbers, last.
    on<SpendsCycleEvent>(_onCycleEvent, transformer: restartable());
    // why: a second tap on "Use these limits?" while the first save is in flight is dropped.
    on<SpendsLimitsAccepted>(_onLimitsAccepted, transformer: droppable());
    _changes = ledger.changes.listen((void _) => add(const SpendsLoadRequested()));
  }

  final GetSpendsOverview _getOverview;
  final ApplySuggestedLimits _applyLimits;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;
  int _cyclesBack = 0;

  Future<void> _onCycleEvent(SpendsCycleEvent event, Emitter<SpendsState> emit) async {
    final SpendsState current = state;
    switch (event) {
      case SpendsLoadRequested():
        await _show(emit, _cyclesBack);
      case SpendsEarlierPressed():
        if (current is SpendsReady && current.overview.canGoBack) {
          unawaited(_haptics.tick());
          await _show(emit, current.overview.cyclesBack + 1);
        }
      case SpendsLaterPressed():
        if (current is SpendsReady && !current.overview.isCurrent) {
          unawaited(_haptics.tick());
          await _show(emit, current.overview.cyclesBack - 1);
        }
    }
  }

  /// Accepts "Use these limits?" in one tap (BR-12).
  Future<void> _onLimitsAccepted(SpendsLimitsAccepted event, Emitter<SpendsState> emit) async {
    final SpendsState current = state;
    if (current is! SpendsReady || current.savingLimits) {
      return;
    }
    emit(SpendsReady(current.overview, savingLimits: true));
    final Either<Failure, Unit> saved = await _applyLimits(event.offer.limits).run();
    await saved.match(
      (Failure failure) async {
        AppLogger.log(tag: 'spends.limits_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        unawaited(_haptics.reject());
        emit(SpendsReady(current.overview, limitsFailed: true));
      },
      (Unit _) async {
        unawaited(_haptics.success());
        await _show(emit, _cyclesBack);
      },
    );
  }

  Future<void> _show(Emitter<SpendsState> emit, int cyclesBack) async {
    _cyclesBack = cyclesBack;
    final Either<Failure, SpendsOverview> loaded = await _getOverview(cyclesBack).run();
    emit(loaded.match((Failure failure) {
      AppLogger.log(tag: 'spends.load_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
      return SpendsFailed(failure);
    }, SpendsReady.new));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
