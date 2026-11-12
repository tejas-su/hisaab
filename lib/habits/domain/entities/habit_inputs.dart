import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';
import 'suggestion_state.dart';

/// What a `HabitIndex` is worked out from: the ledger's recent entries, the categories and the
/// stored quiet states.
final class HabitInputs extends Equatable {
  /// Groups the three reads a habit index needs.
  const HabitInputs({required this.entries, required this.categories, required this.states});

  /// The entries dated in the 56 days ending today; older or later ones are ignored.
  final List<Entry> entries;

  /// The categories that can have a habit, as `CategoryRepository.all()` returns them: the
  /// system-hidden rows are not among them.
  final List<Category> categories;

  /// The stored state of each category that has one, by category id.
  final Map<int, SuggestionState> states;

  @override
  List<Object?> get props => <Object?>[entries, categories, states];
}
