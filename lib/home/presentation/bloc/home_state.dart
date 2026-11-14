import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../ledger/ledger.dart';

/// What Home shows.
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load; the hero card shows without a number.
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// The hero for [summary] (whose state may be `NoIncome`), the due-soon nudge and today's
/// latest entries.
///
/// [undo] holds an entry just deleted, so the page can offer Undo once (SPEC BR-10); [billUndo]
/// does the same for a bill deleted from its sheet (D118), and [amountUndo] for a waiting bill
/// just entered or skipped (D123), [usedUndo] for a *Used* save (AC-Y9) and [fixUndo] for a fix (FR-FX-5). [billUndoKeepsHistory]
/// says the saving in [billUndo] has had a put-in, so its Undo bar says what stays (AC-Y10).
/// [showWeek] puts the hero on *This week* instead of *Today* (FR-HO-2).
/// [billNames] names each bill rule by id, so a row a bill posted says which bill it is.
final class HomeReady extends HomeState {
  const HomeReady({
    required this.summary,
    required this.todayEntries,
    required this.categories,
    this.todaySpends = const <Entry>[],
    this.dueSoon = const Option<DueSoonBill>.none(),
    this.undo = const Option<Entry>.none(),
    this.billUndo = const Option<RecurringRule>.none(),
    this.amountUndo = const Option<BillAmountOutcome>.none(),
    this.usedUndo = const Option<UsedOutcome>.none(),
    this.fixUndo = const Option<FixOutcome>.none(),
    this.justFixed = const Option<int>.none(),
    this.installDue = false,
    this.billUndoKeepsHistory = false,
    this.showWeek = false,
    this.billNames = const <int, String>{},
  });

  final CycleSummary summary;

  /// At most [HomeBloc.todayListLimit] entries dated today, newest first (FR-HO-4).
  final List<Entry> todayEntries;

  /// Every *Spent* entry dated today, oldest first, for the hero's bites (BR-6).
  final List<Entry> todaySpends;

  /// Every category by id, to label the rows.
  final Map<int, Category> categories;

  /// The soonest bill going out within 5 days, if any (FR-HO-3).
  final Option<DueSoonBill> dueSoon;
  final Option<Entry> undo;
  final Option<RecurringRule> billUndo;
  final Option<BillAmountOutcome> amountUndo;
  final Option<UsedOutcome> usedUndo;

  /// A fix just written from Home; the page offers Undo for it once (FR-FX-5 AC-3).
  final Option<FixOutcome> fixUndo;

  /// The id of a fix's entry that just appeared in [todayEntries]: its row grows in after the hero
  /// has rolled (FR-FX-5 AC-2).
  final Option<int> justFixed;

  /// Whether the one-time install line is due: the app was installed in the middle of this cycle and
  /// the line has not been seen or used up by a fix (FR-HO-3).
  final bool installDue;
  final bool billUndoKeepsHistory;
  final bool showWeek;
  final Map<int, String> billNames;

  /// Returns a copy with the given fields replaced; [undo], [billUndo], [amountUndo], [usedUndo], [fixUndo] and
  /// [billUndoKeepsHistory] reset unless passed.
  HomeReady copyWith({
    List<Entry>? todayEntries,
    Option<Entry> undo = const Option<Entry>.none(),
    Option<RecurringRule> billUndo = const Option<RecurringRule>.none(),
    Option<BillAmountOutcome> amountUndo = const Option<BillAmountOutcome>.none(),
    Option<UsedOutcome> usedUndo = const Option<UsedOutcome>.none(),
    Option<FixOutcome> fixUndo = const Option<FixOutcome>.none(),
    Option<int>? justFixed,
    bool? installDue,
    bool billUndoKeepsHistory = false,
    bool? showWeek,
  }) =>
      HomeReady(
        summary: summary,
        todayEntries: todayEntries ?? this.todayEntries,
        categories: categories,
        todaySpends: todaySpends,
        dueSoon: dueSoon,
        undo: undo,
        billUndo: billUndo,
        amountUndo: amountUndo,
        usedUndo: usedUndo,
        fixUndo: fixUndo,
        justFixed: justFixed ?? this.justFixed,
        installDue: installDue ?? this.installDue,
        billUndoKeepsHistory: billUndoKeepsHistory,
        showWeek: showWeek ?? this.showWeek,
        billNames: billNames,
      );

  @override
  List<Object?> get props => <Object?>[summary, todayEntries, categories, todaySpends, dueSoon, undo, billUndo, amountUndo, usedUndo, fixUndo, justFixed, installDue, billUndoKeepsHistory, showWeek, billNames];
}

/// Loading failed; a quiet message with Try again.
final class HomeFailed extends HomeState {
  const HomeFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
