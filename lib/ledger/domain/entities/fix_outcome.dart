import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import 'entry.dart';

/// What a *Fix it* produced (BR-18): the *Not logged* [entry] and the figure Home will show,
/// so whichever screen opened the sheet can say it in its Undo snackbar and delete [entry] on Undo.
final class FixOutcome extends Equatable {
  const FixOutcome({required this.entry, required this.safeToday});

  final Entry entry;

  /// Today's safe-to-spend figure after the fix, never below ₹0 (the hero's own title).
  final Money safeToday;

  @override
  List<Object?> get props => <Object?>[entry, safeToday];
}
