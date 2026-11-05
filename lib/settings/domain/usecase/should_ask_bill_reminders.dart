import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../repository/app_preferences_repository.dart';

/// Whether to ask "Remind you on the day it's due?" now: only once a changing or card bill
/// exists, and only if it was never answered (spec §5, D126).
final class ShouldAskBillReminders implements UseCase<bool, NoParams> {
  const ShouldAskBillReminders({required this._preferences, required this._recurring});

  final AppPreferencesRepository _preferences;
  final RecurringRepository _recurring;

  /// Returns [Right] with true when it should ask, or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, bool> call(NoParams params) => _preferences.billRemindersChoice().flatMap(
        (Option<bool> answered) => answered.isSome()
            ? TaskEither<Failure, bool>.right(false)
            : _recurring.activeRules().map(
                (List<RecurringRule> rules) =>
                    rules.any((RecurringRule r) => r.kind == EntryKind.spent && r.amountMode != AmountMode.fixed),
              ),
      );
}
