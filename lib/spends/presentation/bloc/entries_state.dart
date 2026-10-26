import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// What *Every entry* shows.
sealed class EntriesState extends Equatable {
  const EntriesState();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load.
final class EntriesLoading extends EntriesState {
  const EntriesLoading();
}

/// A cycle's [entries] (newest first), narrowed to one category by [filter] when set.
///
/// [undo] holds an entry just deleted, so the page can offer Undo once (SPEC BR-10).
final class EntriesReady extends EntriesState {
  const EntriesReady({
    required this.entries,
    required this.categories,
    this.filter = const Option<int>.none(),
    this.undo = const Option<Entry>.none(),
  });

  final List<Entry> entries;

  /// Every category by id, to label rows and chips.
  final Map<int, Category> categories;
  final Option<int> filter;
  final Option<Entry> undo;

  /// The entries the filter lets through, newest first.
  List<Entry> get shown => filter.match(
        () => entries,
        (int categoryId) => entries.where((Entry e) => e.categoryId == categoryId).toList(),
      );

  /// [shown] grouped by day, newest day first.
  List<(CalendarDate, List<Entry>)> get days => shown.fold(
        <(CalendarDate, List<Entry>)>[],
        (List<(CalendarDate, List<Entry>)> groups, Entry e) => groups.isNotEmpty && groups.last.$1 == e.date
            ? <(CalendarDate, List<Entry>)>[...groups.take(groups.length - 1), (e.date, <Entry>[...groups.last.$2, e])]
            : <(CalendarDate, List<Entry>)>[...groups, (e.date, <Entry>[e])],
      );

  /// The categories that have entries in the cycle, in the grid's order (*Spent* first).
  List<Category> get chips {
    final Set<int> used = entries.map((Entry e) => e.categoryId).toSet();
    return categories.values.where((Category c) => used.contains(c.id)).toList();
  }

  /// Returns a copy with the given fields replaced; [undo] resets unless passed.
  EntriesReady copyWith({List<Entry>? entries, Option<int>? filter, Option<Entry> undo = const Option<Entry>.none()}) =>
      EntriesReady(entries: entries ?? this.entries, categories: categories, filter: filter ?? this.filter, undo: undo);

  @override
  List<Object?> get props => <Object?>[entries, categories, filter, undo];
}

/// Loading failed; a quiet message with Try again.
final class EntriesFailed extends EntriesState {
  const EntriesFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
