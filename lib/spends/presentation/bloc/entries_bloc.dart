import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../ledger/ledger.dart';
import 'entries_event.dart';
import 'entries_state.dart';

/// Owns *Every entry* for one [PayCycle] (SPEC FR-SP-6). Driven by [EntriesLoadRequested] and
/// every ledger write; the page adds [EntriesFilterChanged], [EntriesDeleteRequested] and
/// [EntriesUndoRequested].
class EntriesBloc extends Bloc<EntriesEvent, EntriesState> {
  EntriesBloc({
    required this._cycle,
    required this._ledger,
    required this._categories,
    required this._deleteEntry,
    required this._restoreEntry,
    required this._haptics,
    this._filter = const Option<int>.none(),
  }) : super(const EntriesLoading()) {
    // why: a newer load cancels an older one still reading, so a stale list never lands last.
    on<EntriesLoadRequested>((EntriesLoadRequested event, Emitter<EntriesState> emit) => _load(emit), transformer: restartable());
    on<EntriesFilterChanged>(_onFilterChanged);
    on<EntriesDeleteRequested>(_onDeleteRequested);
    on<EntriesUndoRequested>(_onUndoRequested);
    on<EntriesSwipeThresholdReached>(
      (EntriesSwipeThresholdReached event, Emitter<EntriesState> emit) => unawaited(_haptics.threshold()),
    );
    _changes = _ledger.changes.listen((void _) => add(const EntriesLoadRequested()));
  }

  final PayCycle _cycle;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final DeleteEntry _deleteEntry;
  final RestoreEntry _restoreEntry;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;
  Option<int> _filter;

  /// Loads the cycle's entries and the categories.
  Future<void> _load(Emitter<EntriesState> emit) async {
    final Either<Failure, EntriesReady> loaded = await _categories
        .all()
        .flatMap(
          (List<Category> categories) => _ledger.entriesBetween(_cycle.start, _cycle.end).map(
                (List<Entry> entries) => EntriesReady(
                  entries: entries,
                  categories: <int, Category>{for (final Category c in categories) c.id: c},
                  filter: _filter,
                ),
              ),
        )
        .run();
    emit(loaded.match((Failure failure) {
      _log('entries.load_failed', failure);
      return EntriesFailed(failure);
    }, (EntriesReady ready) => ready));
  }

  /// Shows only the chosen category's entries, or all of them with [None].
  void _onFilterChanged(EntriesFilterChanged event, Emitter<EntriesState> emit) {
    final EntriesState current = state;
    if (current is! EntriesReady || current.filter == event.categoryId) {
      return;
    }
    _filter = event.categoryId;
    emit(current.copyWith(filter: event.categoryId));
    unawaited(_haptics.tick());
  }

  // why: the row leaves the list in the first emit, before the delete is written, so the
  // Dismissible that was swiped away is gone from the tree by the next frame.
  Future<void> _onDeleteRequested(EntriesDeleteRequested event, Emitter<EntriesState> emit) async {
    final EntriesState current = state;
    if (current is! EntriesReady) {
      return;
    }
    final Entry entry = event.entry;
    emit(current.copyWith(entries: current.entries.where((Entry e) => e.id != entry.id).toList()));
    final Either<Failure, Entry> deleted = await _deleteEntry(entry.id).run();
    final EntriesState latest = state;
    await deleted.match(
      (Failure failure) {
        _log('entries.delete_failed', failure);
        return _load(emit);
      },
      (Entry removed) async {
        if (latest is EntriesReady) {
          emit(latest.copyWith(undo: Option<Entry>.of(removed)));
        }
      },
    );
  }

  /// Puts a deleted entry back; the ledger's change stream reloads the list.
  Future<void> _onUndoRequested(EntriesUndoRequested event, Emitter<EntriesState> emit) async {
    final Either<Failure, Entry> restored = await _restoreEntry(event.entry).run();
    restored.mapLeft((Failure failure) => _log('entries.undo_failed', failure));
  }

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
