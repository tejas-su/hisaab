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
/// [undo] holds an entry just deleted, so the page can offer Undo once (SPEC BR-10).
/// [showWeek] puts the hero on *This week* instead of *Today* (FR-HO-2).
final class HomeReady extends HomeState {
  const HomeReady({
    required this.summary,
    required this.todayEntries,
    required this.categories,
    this.dueSoon = const Option<DueSoonBill>.none(),
    this.undo = const Option<Entry>.none(),
    this.showWeek = false,
  });

  final CycleSummary summary;

  /// At most [HomeCubit.todayListLimit] entries dated today, newest first (FR-HO-4).
  final List<Entry> todayEntries;

  /// Every category by id, to label the rows.
  final Map<int, Category> categories;

  /// The soonest bill going out within 5 days, if any (FR-HO-3).
  final Option<DueSoonBill> dueSoon;
  final Option<Entry> undo;
  final bool showWeek;

  /// Returns a copy with the given fields replaced; [undo] resets unless passed.
  HomeReady copyWith({List<Entry>? todayEntries, Option<Entry> undo = const Option<Entry>.none(), bool? showWeek}) =>
      HomeReady(
        summary: summary,
        todayEntries: todayEntries ?? this.todayEntries,
        categories: categories,
        dueSoon: dueSoon,
        undo: undo,
        showWeek: showWeek ?? this.showWeek,
      );

  @override
  List<Object?> get props => <Object?>[summary, todayEntries, categories, dueSoon, undo, showWeek];
}

/// Loading failed; a quiet message with Try again.
final class HomeFailed extends HomeState {
  const HomeFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
