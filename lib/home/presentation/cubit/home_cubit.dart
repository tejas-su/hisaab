import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'home_state.dart';

/// Owns Home's summary and Today list (SPEC FR-HO). Driven by [load] (start, resume) and by
/// every ledger write through [LedgerRepository.changes]; the page calls [delete] and [undo].
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._getCycleSummary,
    required this._postDueRecurring,
    required this._ledger,
    required this._categories,
    required this._deleteEntry,
    required this._restoreEntry,
    required this._haptics,
  }) : super(const HomeLoading()) {
    _changes = _ledger.changes.listen((void _) => load());
  }

  /// Most rows the Today list shows (FR-HO-4).
  static const int todayListLimit = 5;

  final GetCycleSummary _getCycleSummary;
  final PostDueRecurring _postDueRecurring;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final DeleteEntry _deleteEntry;
  final RestoreEntry _restoreEntry;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;

  /// Posts any due recurring entries, then works out today's summary and list (BR-8).
  Future<void> load() async {
    final Either<Failure, int> posted = await _postDueRecurring(const NoParams()).run();
    posted.mapLeft(_logFailure('home.post_due_failed'));
    final Either<Failure, HomeReady> loaded = await _getCycleSummary(const NoParams())
        .flatMap(
          (CycleSummary summary) => _categories.all().flatMap(
                (List<Category> categories) => _ledger.entriesBetween(summary.today, summary.today).map(
                      (List<Entry> entries) => HomeReady(
                        summary: summary,
                        todayEntries: entries.take(todayListLimit).toList(),
                        categories: <int, Category>{for (final Category c in categories) c.id: c},
                      ),
                    ),
              ),
        )
        .run();
    if (isClosed) {
      return;
    }
    emit(loaded.match((Failure failure) {
      _logFailure('home.load_failed')(failure);
      return HomeFailed(failure);
    }, (HomeReady ready) => ready));
  }

  /// Deletes [entry] at once (the row disappears synchronously) and then offers Undo.
  Future<void> delete(Entry entry) async {
    final HomeState current = state;
    if (current is! HomeReady) {
      return;
    }
    emit(current.copyWith(todayEntries: current.todayEntries.where((Entry e) => e.id != entry.id).toList()));
    final Either<Failure, Entry> deleted = await _deleteEntry(entry.id).run();
    if (isClosed) {
      return;
    }
    final HomeState latest = state;
    await deleted.match(
      (Failure failure) {
        _logFailure('home.delete_failed')(failure);
        return load();
      },
      (Entry removed) async {
        if (latest is HomeReady) {
          emit(latest.copyWith(undo: Option<Entry>.of(removed)));
        }
      },
    );
  }

  /// Puts a deleted [entry] back; the ledger's change stream reloads Home.
  Future<void> undo(Entry entry) async {
    final Either<Failure, Entry> restored = await _restoreEntry(entry).run();
    restored.mapLeft(_logFailure('home.undo_failed'));
  }

  /// A row's swipe crossed the delete threshold.
  void swipeThresholdReached() => unawaited(_haptics.threshold());

  static void Function(Failure) _logFailure(String tag) =>
      (Failure failure) => AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
