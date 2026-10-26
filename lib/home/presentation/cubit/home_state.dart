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

/// The hero for [summary] (whose state may be `NoIncome`) and today's latest entries.
///
/// [undo] holds an entry just deleted, so the page can offer Undo once (SPEC BR-10).
final class HomeReady extends HomeState {
  const HomeReady({
    required this.summary,
    required this.todayEntries,
    required this.categories,
    this.undo = const Option<Entry>.none(),
  });

  final CycleSummary summary;

  /// At most [HomeCubit.todayListLimit] entries dated today, newest first (FR-HO-4).
  final List<Entry> todayEntries;

  /// Every category by id, to label the rows.
  final Map<int, Category> categories;
  final Option<Entry> undo;

  /// Returns a copy with the given fields replaced; [undo] resets unless passed.
  HomeReady copyWith({List<Entry>? todayEntries, Option<Entry> undo = const Option<Entry>.none()}) => HomeReady(
        summary: summary,
        todayEntries: todayEntries ?? this.todayEntries,
        categories: categories,
        undo: undo,
      );

  @override
  List<Object?> get props => <Object?>[summary, todayEntries, categories, undo];
}

/// Loading failed; a quiet message with Try again.
final class HomeFailed extends HomeState {
  const HomeFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
