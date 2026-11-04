import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Owns Home's summary, due-soon nudge and Today list (SPEC FR-HO). Driven by
/// [HomeLoadRequested] (start, resume, midnight) and by every write through
/// [LedgerRepository.changes] and [RecurringRepository.changes]; the page adds
/// [HomeDeleteRequested], [HomeUndoRequested] and [HomeWeekToggled]. The app adds
/// [HomeTrayOpened] and [HomeTrayClosed] around the Add tray, and reloads wait in between.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getCycleSummary,
    required this._postDueRecurring,
    required this._getDueSoonBill,
    required this._ledger,
    required RecurringRepository recurring,
    required this._categories,
    required this._deleteEntry,
    required this._restoreEntry,
    required this._deleteBill,
    required this._restoreBill,
    required this._haptics,
  }) : super(const HomeLoading()) {
    // why: every write reloads Home; a newer load cancels an older one still reading, so stale
    // numbers never land last.
    on<HomeLoadRequested>(_onLoadRequested, transformer: restartable());
    on<HomeTrayOpened>((HomeTrayOpened event, Emitter<HomeState> emit) => _trayOpen = true);
    on<HomeTrayClosed>(_onTrayClosed);
    on<HomeWeekToggled>(_onWeekToggled);
    on<HomeDeleteRequested>(_onDeleteRequested);
    on<HomeUndoRequested>(_onUndoRequested);
    // why: a second Delete bill while the first is being written must not delete twice.
    on<HomeBillDeleteRequested>(_onBillDeleteRequested, transformer: droppable());
    on<HomeBillUndoRequested>(_onBillUndoRequested);
    on<HomeSwipeThresholdReached>((HomeSwipeThresholdReached event, Emitter<HomeState> emit) => unawaited(_haptics.threshold()));
    _changes = _ledger.changes.listen((void _) => add(const HomeLoadRequested()));
    _ruleChanges = recurring.changes.listen((void _) => add(const HomeLoadRequested()));
  }

  /// Most rows the Today list shows (FR-HO-4).
  static const int todayListLimit = 5;

  final GetCycleSummary _getCycleSummary;
  final PostDueRecurring _postDueRecurring;
  final GetDueSoonBill _getDueSoonBill;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final DeleteEntry _deleteEntry;
  final RestoreEntry _restoreEntry;
  final DeleteBill _deleteBill;
  final RestoreBill _restoreBill;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;
  late final StreamSubscription<void> _ruleChanges;

  // why: a drain behind the closing tray's scrim teaches nothing, so while the tray covers Home
  // a reload waits for the tray to go (FR-AD-5, D91).
  bool _trayOpen = false;
  bool _reloadWhenTrayCloses = false;

  Future<void> _onLoadRequested(HomeLoadRequested event, Emitter<HomeState> emit) async {
    if (_trayOpen) {
      _reloadWhenTrayCloses = true;
      return;
    }
    await _load(emit);
  }

  // why: the reload joins the restartable load queue rather than running here, so it can't
  // race a load already in flight.
  void _onTrayClosed(HomeTrayClosed event, Emitter<HomeState> emit) {
    _trayOpen = false;
    if (_reloadWhenTrayCloses) {
      _reloadWhenTrayCloses = false;
      add(const HomeLoadRequested());
    }
  }

  /// Posts any due recurring entries, then works out today's summary, nudge and list (BR-8).
  Future<void> _load(Emitter<HomeState> emit) async {
    final Either<Failure, int> posted = await _postDueRecurring(const NoParams()).run();
    posted.mapLeft(_logFailure('home.post_due_failed'));
    final Option<DueSoonBill> dueSoon = (await _getDueSoonBill(const NoParams()).run()).match(
      (Failure failure) {
        _logFailure('home.due_soon_failed')(failure);
        return const Option<DueSoonBill>.none();
      },
      (Option<DueSoonBill> bill) => bill,
    );
    final Either<Failure, HomeReady> loaded = await _getCycleSummary(const NoParams())
        .flatMap(
          (CycleSummary summary) => _categories.all().flatMap(
                (List<Category> categories) => _ledger.entriesBetween(summary.today, summary.today).map(
                      (List<Entry> entries) => HomeReady(
                        summary: summary,
                        todayEntries: entries.take(todayListLimit).toList(),
                        categories: <int, Category>{for (final Category c in categories) c.id: c},
                        todaySpends: entries.reversed.where((Entry e) => e.kind == EntryKind.spent).toList(),
                        dueSoon: dueSoon,
                      ),
                    ),
              ),
        )
        .run();
    emit(loaded.match((Failure failure) {
      _logFailure('home.load_failed')(failure);
      return HomeFailed(failure);
    }, (HomeReady ready) => ready.copyWith(showWeek: _showingWeek)));
  }

  /// Flips the hero between *Today* and *This week*; the choice lasts for the session (FR-HO-2).
  void _onWeekToggled(HomeWeekToggled event, Emitter<HomeState> emit) {
    final HomeState current = state;
    if (current is! HomeReady) {
      return;
    }
    emit(current.copyWith(showWeek: !current.showWeek));
    unawaited(_haptics.tick());
  }

  bool get _showingWeek => switch (state) {
        HomeReady(:final bool showWeek) => showWeek,
        HomeLoading() || HomeFailed() => false,
      };

  // why: the row leaves the list in the first emit, before the delete is written, so the
  // Dismissible that was swiped away is gone from the tree by the next frame.
  Future<void> _onDeleteRequested(HomeDeleteRequested event, Emitter<HomeState> emit) async {
    final HomeState current = state;
    if (current is! HomeReady) {
      return;
    }
    final Entry entry = event.entry;
    emit(current.copyWith(todayEntries: current.todayEntries.where((Entry e) => e.id != entry.id).toList()));
    final Either<Failure, Entry> deleted = await _deleteEntry(entry.id).run();
    final HomeState latest = state;
    await deleted.match(
      (Failure failure) {
        _logFailure('home.delete_failed')(failure);
        return _load(emit);
      },
      (Entry removed) async {
        if (latest is HomeReady) {
          emit(latest.copyWith(undo: Option<Entry>.of(removed)));
        }
      },
    );
  }

  /// Puts a deleted entry back; the ledger's change stream reloads Home.
  Future<void> _onUndoRequested(HomeUndoRequested event, Emitter<HomeState> emit) async {
    final Either<Failure, Entry> restored = await _restoreEntry(event.entry).run();
    restored.mapLeft(_logFailure('home.undo_failed'));
  }

  /// Deletes a bill from its sheet and offers Undo; the rules' change stream reloads Home.
  Future<void> _onBillDeleteRequested(HomeBillDeleteRequested event, Emitter<HomeState> emit) async {
    if (state is! HomeReady) {
      return;
    }
    final Either<Failure, Unit> deleted = await _deleteBill(event.rule.id).run();
    final HomeState latest = state;
    deleted.match(_logFailure('home.bill_delete_failed'), (Unit _) {
      if (latest is HomeReady) {
        emit(latest.copyWith(billUndo: Option<RecurringRule>.of(event.rule)));
      }
    });
  }

  /// Brings a deleted bill back; the rules' change stream reloads Home.
  Future<void> _onBillUndoRequested(HomeBillUndoRequested event, Emitter<HomeState> emit) async {
    final Either<Failure, Unit> restored = await _restoreBill(event.rule.id).run();
    restored.mapLeft(_logFailure('home.bill_undo_failed'));
  }

  static void Function(Failure) _logFailure(String tag) =>
      (Failure failure) => AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    await _ruleChanges.cancel();
    return super.close();
  }
}
