import 'dart:async';
import 'dart:math' as math;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Owns Home's summary, due-soon nudge and Today list (SPEC FR-HO). Driven by
/// [HomeLoadRequested] (start, resume, midnight) and by every write through
/// [LedgerRepository.changes] and [RecurringRepository.changes]; the page adds
/// [HomeDeleteRequested], [HomeUndoRequested], [HomeBillAmountUndoRequested] and [HomeWeekToggled]. The app adds
/// [HomeTrayOpened] and [HomeTrayClosed] around the Add tray, and reloads wait in between.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getCycleSummary,
    required this._postDueRecurring,
    required this._getDueSoonBill,
    required this._ledger,
    required this._recurring,
    required this._categories,
    required this._deleteEntry,
    required this._restoreEntry,
    required this._deleteBill,
    required this._restoreBill,
    required this._undoBillAmount,
    required this._unskipBill,
    required this._haptics,
    this._settings,
  }) : super(const HomeLoading()) {
    // why: every write reloads Home; a newer load cancels an older one still reading, so stale
    // numbers never land last.
    on<HomeLoadRequested>(_onLoadRequested, transformer: restartable());
    on<HomeTrayOpened>((HomeTrayOpened event, Emitter<HomeState> emit) => _holds++);
    on<HomeTrayClosed>(_onTrayClosed);
    on<HomeWeekToggled>(_onWeekToggled);
    on<HomeDeleteRequested>(_onDeleteRequested);
    on<HomeUndoRequested>(_onUndoRequested);
    // why: a second Delete bill while the first is being written must not delete twice.
    on<HomeBillDeleteRequested>(_onBillDeleteRequested, transformer: droppable());
    on<HomeBillUndoRequested>(_onBillUndoRequested);
    on<HomeBillAmountDone>(_onBillAmountDone);
    on<HomeBillAmountUndoRequested>(_onBillAmountUndoRequested);
    on<HomeFixDone>(_onFixDone);
    on<HomeFixUndoRequested>(_onFixUndoRequested);
    on<HomeUsedDone>(_onUsedDone);
    on<HomeUsedUndoRequested>(_onUsedUndoRequested);
    on<HomeSwipeThresholdReached>((HomeSwipeThresholdReached event, Emitter<HomeState> emit) => unawaited(_haptics.threshold()));
    _changes = _ledger.changes.listen((void _) => add(const HomeLoadRequested()));
    _ruleChanges = _recurring.changes.listen((void _) => add(const HomeLoadRequested()));
  }

  /// Most rows the Today list shows (FR-HO-4).
  static const int todayListLimit = 5;

  final GetCycleSummary _getCycleSummary;
  final PostDueRecurring _postDueRecurring;
  final GetDueSoonBill _getDueSoonBill;
  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
  final CategoryRepository _categories;
  final DeleteEntry _deleteEntry;
  final RestoreEntry _restoreEntry;
  final DeleteBill _deleteBill;
  final RestoreBill _restoreBill;
  final UndoBillAmount _undoBillAmount;
  final UnskipBillOccurrence _unskipBill;
  final Haptics _haptics;

  /// Where the install line's seen flag is read; none (older constructions) means no install line.
  final BudgetSettingsRepository? _settings;
  late final StreamSubscription<void> _changes;
  late final StreamSubscription<void> _ruleChanges;

  // why: a drain behind the closing tray's scrim teaches nothing, so while the tray covers Home
  // a reload waits for the tray to go (FR-AD-5, D91). A count, not a flag: a sheet opened as
  // another closes (a reminder or launch pops, then opens) must not release Home early.
  int _holds = 0;
  bool _reloadWhenTrayCloses = false;

  /// Whether a tray or sheet is over Home right now (the hold count of [HomeTrayOpened]).
  bool get isCovered => _holds > 0;

  // why: an amount entered while Home couldn't show (still loading, or a failed reload) would
  // lose its Undo; it waits here for the next load that succeeds.
  Option<BillAmountOutcome> _pendingAmountUndo = const Option<BillAmountOutcome>.none();

  // why: the same for a *Used* save, whose Undo would otherwise be lost while Home can't show.
  Option<UsedOutcome> _pendingUsedUndo = const Option<UsedOutcome>.none();

  // why: the same for a fix, whose Undo would otherwise be lost while Home can't show (D127).
  Option<FixOutcome> _pendingFixUndo = const Option<FixOutcome>.none();

  // why: the fix's row is marked for the load that first lists it, so it can grow in after the hero.
  Option<int> _pendingJustFixed = const Option<int>.none();

  Future<void> _onLoadRequested(HomeLoadRequested event, Emitter<HomeState> emit) async {
    if (_holds > 0) {
      _reloadWhenTrayCloses = true;
      return;
    }
    await _load(emit);
  }

  // why: the reload joins the restartable load queue rather than running here, so it can't
  // race a load already in flight.
  void _onTrayClosed(HomeTrayClosed event, Emitter<HomeState> emit) {
    _holds = math.max(0, _holds - 1);
    if (_holds == 0 && _reloadWhenTrayCloses) {
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
                (List<Category> categories) => _recurring.activeRules().flatMap(
                      (List<RecurringRule> rules) => _ledger.entriesBetween(summary.today, summary.today).map(
                            (List<Entry> entries) => HomeReady(
                              summary: summary,
                              todayEntries: entries.take(todayListLimit).toList(),
                              categories: <int, Category>{for (final Category c in categories) c.id: c},
                              // why: a bill or a fix posted today sits in the pool, not today's bar (D119, BR-18).
                              todaySpends: entries.reversed.where((Entry e) => e.kind == EntryKind.spent && e.recurringId == null && !e.isNotLogged).toList(),
                              dueSoon: dueSoon,
                              billNames: <int, String>{for (final RecurringRule rule in rules) rule.id: rule.label},
                            ),
                          ),
                    ),
              ),
        )
        .run();
    final bool installDue = await loaded.match((Failure _) async => false, (HomeReady ready) => _installDue(ready.summary));
    emit(loaded.match((Failure failure) {
      _logFailure('home.load_failed')(failure);
      return HomeFailed(failure);
    }, (HomeReady ready) => _shown(ready.copyWith(installDue: installDue))));
  }

  // why: the install day is the day the earliest entry was saved (C1: the income rule has no created
  // time). The line is for an install in the middle of this cycle, so a start-of-cycle or earlier
  // install never gets it (FR-HO-3, E109). A read that fails just leaves the line out.
  Future<bool> _installDue(CycleSummary summary) async {
    final BudgetSettingsRepository? settings = _settings;
    if (settings == null) {
      return false;
    }
    final Either<Failure, bool> seen = await settings.installLineSeen().run();
    final Either<Failure, Option<CalendarDate>> installed = await _ledger.firstLoggedOn().run();
    seen.mapLeft(_logFailure('home.install_seen_failed'));
    installed.mapLeft(_logFailure('home.install_day_failed'));
    final bool unseen = seen.match((Failure _) => false, (bool value) => !value);
    return unseen &&
        installed.match(
          (Failure _) => false,
          (Option<CalendarDate> day) => day.match(
            () => false,
            (CalendarDate installDay) => summary.cycle.contains(installDay) && summary.cycle.start.isBefore(installDay),
          ),
        );
  }

  HomeReady _shown(HomeReady ready) {
    final Option<BillAmountOutcome> pending = _pendingAmountUndo;
    final Option<UsedOutcome> pendingUsed = _pendingUsedUndo;
    final Option<FixOutcome> pendingFix = _pendingFixUndo;
    _pendingAmountUndo = const Option<BillAmountOutcome>.none();
    _pendingUsedUndo = const Option<UsedOutcome>.none();
    _pendingFixUndo = const Option<FixOutcome>.none();
    final Option<int> justFixed = _pendingJustFixed.filter((int id) => ready.todayEntries.any((Entry e) => e.id == id));
    if (justFixed.isSome()) {
      _pendingJustFixed = const Option<int>.none();
    }
    return ready.copyWith(showWeek: _showingWeek, amountUndo: pending, usedUndo: pendingUsed, fixUndo: pendingFix, justFixed: justFixed);
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
    final bool keepsHistory = await _hadPutIn(event.rule);
    final Either<Failure, Unit> deleted = await _deleteBill(event.rule.id).run();
    final HomeState latest = state;
    deleted.match(_logFailure('home.bill_delete_failed'), (Unit _) {
      if (latest is HomeReady) {
        emit(latest.copyWith(billUndo: Option<RecurringRule>.of(event.rule), billUndoKeepsHistory: keepsHistory));
      }
    });
  }

  // why: AC-Y10 says what stays only for a saving that has had a put-in; read before the delete,
  // since the reload that follows it no longer lists the rule.
  Future<bool> _hadPutIn(RecurringRule rule) async {
    if (rule.kind != EntryKind.saved) {
      return false;
    }
    final Either<Failure, SavingTotals> totals = await _ledger.savingTotals().run();
    return totals.match((Failure _) => false, (SavingTotals t) => (t.bySaving[rule.id]?.putIn ?? Money.zero) > Money.zero);
  }

  /// Brings a deleted bill back; the rules' change stream reloads Home.
  Future<void> _onBillUndoRequested(HomeBillUndoRequested event, Emitter<HomeState> emit) async {
    final Either<Failure, Unit> restored = await _restoreBill(event.rule.id).run();
    restored.mapLeft(_logFailure('home.bill_undo_failed'));
  }

  void _onBillAmountDone(HomeBillAmountDone event, Emitter<HomeState> emit) {
    final HomeState current = state;
    if (current is! HomeReady) {
      _pendingAmountUndo = Option<BillAmountOutcome>.of(event.outcome);
      return;
    }
    emit(current.copyWith(amountUndo: Option<BillAmountOutcome>.of(event.outcome)));
  }

  void _onUsedDone(HomeUsedDone event, Emitter<HomeState> emit) {
    final HomeState current = state;
    if (current is! HomeReady) {
      _pendingUsedUndo = Option<UsedOutcome>.of(event.outcome);
      return;
    }
    emit(current.copyWith(usedUndo: Option<UsedOutcome>.of(event.outcome)));
  }

  // why: success fires here, once the sheet has closed and Home is back in view, so it lands as the
  // hero rolls rather than as the sheet leaves (FR-FX-5 AC-2).
  void _onFixDone(HomeFixDone event, Emitter<HomeState> emit) {
    unawaited(_haptics.success());
    _pendingJustFixed = Option<int>.of(event.outcome.entry.id);
    final HomeState current = state;
    if (current is! HomeReady) {
      _pendingFixUndo = Option<FixOutcome>.of(event.outcome);
      return;
    }
    emit(current.copyWith(fixUndo: Option<FixOutcome>.of(event.outcome)));
  }

  /// Deletes the fix's entry, so the number reverts exactly (it was computed, never stored); the
  /// ledger's change stream reloads Home.
  Future<void> _onFixUndoRequested(HomeFixUndoRequested event, Emitter<HomeState> emit) async {
    final Either<Failure, Entry> deleted = await _deleteEntry(event.entry.id).run();
    deleted.match(_logFailure('home.fix_undo_failed'), (Entry _) => unawaited(_haptics.tick()));
  }

  /// Deletes the *Used* entry, so the money is set aside again; the ledger's change stream reloads Home.
  Future<void> _onUsedUndoRequested(HomeUsedUndoRequested event, Emitter<HomeState> emit) async {
    final Either<Failure, Entry> deleted = await _deleteEntry(event.entry.id).run();
    deleted.mapLeft(_logFailure('home.used_undo_failed'));
  }

  /// Puts an entered or skipped bill back to waiting; the change streams reload Home (E-e).
  Future<void> _onBillAmountUndoRequested(HomeBillAmountUndoRequested event, Emitter<HomeState> emit) async {
    final Either<Failure, Unit> undone = await switch (event.outcome) {
      BillAmountWasEntered(:final BillAmountEntered entered) => _undoBillAmount(entered).run(),
      BillAmountWasSkipped(:final BillSkip skip) => _unskipBill(skip).run(),
    };
    undone.mapLeft(_logFailure('home.bill_amount_undo_failed'));
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
