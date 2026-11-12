import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'suggestion_state.dart';

/// A *Forget* that can still be undone: the category and what its state was before (SPEC
/// FR-SE-2 AC-6, E68).
final class ForgottenUsual extends Equatable {
  /// Records that category [categoryId] was forgotten while its state was [previous].
  const ForgottenUsual({required this.categoryId, required this.previous});

  /// The category whose usual was forgotten.
  final int categoryId;

  /// The state Undo puts back; [None] when the category had none, so Undo removes it again.
  final Option<SuggestionState> previous;

  @override
  List<Object?> get props => <Object?>[categoryId, previous];
}
