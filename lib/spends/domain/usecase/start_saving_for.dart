import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';

/// A saving to start for an item: its [name], what goes in each month, the [target] it needs, and
/// the [nextCycle] it starts in. [existing] is the active saving of the same name, if any (D221).
final class StartSavingParams extends Equatable {
  const StartSavingParams({
    required this.name,
    required this.monthly,
    required this.target,
    required this.nextCycle,
    required this.existing,
  });

  final String name;
  final Money monthly;
  final Money target;
  final PayCycle nextCycle;
  final Option<RecurringRule> existing;

  @override
  List<Object?> get props => <Object?>[
    name,
    monthly,
    target,
    nextCycle,
    existing,
  ];
}

/// Starts a monthly saving with a target, or re-uses the same-name one (SPEC BR-24, D220, D221).
///
/// A new saving goes in on the day after the next payday. An existing one keeps its id and day;
/// only its amount and target change, and a saving that had stopped at its old target restarts
/// from its own `next_due` (D213).
final class StartSavingFor
    implements UseCase<RecurringRule, StartSavingParams> {
  const StartSavingFor({
    required this._addBill,
    required this._editBill,
    required this._recurring,
  });

  final AddBill _addBill;
  final EditBill _editBill;
  final RecurringRepository _recurring;

  /// Returns [Right] with the saved rule, or [Left] with the failure from [AddBill], [EditBill]
  /// or the target update; the saving may then exist without its target.
  @override
  TaskEither<Failure, RecurringRule> call(StartSavingParams params) => params
      .existing
      .match(
        () => _create(params),
        (RecurringRule rule) => _change(rule, params),
      )
      .flatMap(
        (RecurringRule rule) => _recurring.update(
          rule.copyWith(target: Option<Money>.of(params.target)),
        ),
      );

  TaskEither<Failure, RecurringRule> _create(StartSavingParams params) =>
      _addBill(
        AddBillParams(
          input: BillInput(
            label: params.name,
            amount: params.monthly,
            dueDay: _putInDay(params.nextCycle),
          ),
          entryKind: EntryKind.saved,
        ),
      );

  TaskEither<Failure, RecurringRule> _change(
    RecurringRule rule,
    StartSavingParams params,
  ) => _editBill(
    EditBillParams(
      rule: rule,
      input: BillInput(
        label: rule.label,
        amount: params.monthly,
        dueDay: rule.schedule.anchor.day,
        icon: rule.icon,
      ),
    ),
  );

  // why: the day after payday, so a put-in never lands before the pay it comes from (D220).
  static int _putInDay(PayCycle cycle) => cycle.start.addDays(1).day;
}
