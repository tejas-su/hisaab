import 'package:equatable/equatable.dart';

import 'entry.dart';
import 'recurring_rule.dart';

/// What a *Used some of it* save produced (BR-19): the *Used* [entry] and the [saving] it was paid
/// from, so the screen that opened the saving's sheet can name it in the Undo snackbar.
final class UsedOutcome extends Equatable {
  const UsedOutcome({required this.entry, required this.saving});

  final Entry entry;
  final RecurringRule saving;

  @override
  List<Object?> get props => <Object?>[entry, saving];
}
