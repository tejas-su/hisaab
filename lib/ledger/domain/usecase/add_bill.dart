import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../bill_validator.dart';
import '../entities/amount_mode.dart';
import '../entities/bill_input.dart';
import '../entities/bill_kind.dart';
import '../entities/category.dart';
import '../entities/entry_kind.dart';
import '../entities/frequency.dart';
import '../entities/recurring_draft.dart';
import '../entities/recurring_rule.dart';
import '../entities/schedule.dart';
import '../recurring_schedule.dart';
import '../repository/category_repository.dart';
import '../repository/recurring_repository.dart';

/// A new bill or saving from Settings; [kind] is the bill chip it started from, if any (it picks
/// the category), and [entryKind] says whether it is a bill (*Spent*) or a saving (*Saved*, D120).
final class AddBillParams extends Equatable {
  const AddBillParams({
    required this.input,
    this.kind = const Option<BillKind>.none(),
    this.entryKind = EntryKind.spent,
  });

  final BillInput input;
  final Option<BillKind> kind;
  final EntryKind entryKind;

  @override
  List<Object?> get props => <Object?>[input, kind, entryKind];
}

/// Saves a new fixed monthly bill, or a monthly saving, from Settings (SPEC FR-SE-1, D120).
///
/// It first goes out on its next due date from today; dates already past this cycle are not
/// back-posted, since the user may have logged them by hand (DECISIONS D33).
final class AddBill implements UseCase<RecurringRule, AddBillParams> {
  const AddBill({required this._recurring, required this._categories, required this._clock});

  final RecurringRepository _recurring;
  final CategoryRepository _categories;
  final Clock _clock;

  /// Returns [Right] with the saved rule, or [Left] with a `BillValidator` failure (nothing
  /// saved), `InvalidDataFailure` when the seed category is missing, or `DatabaseFailure`.
  @override
  TaskEither<Failure, RecurringRule> call(AddBillParams params) {
    final CalendarDate today = _clock.today();
    return TaskEither<Failure, BillInput>.fromEither(BillValidator.validate(params.input)).flatMap(
      (BillInput input) => _categories
          .idOf(_categoryKey(params))
          .flatMap((int categoryId) => _recurring.add(_draft(input, (categoryId: categoryId, kind: params.entryKind, mode: _modeOf(params)), today))),
    );
  }

  static String _categoryKey(AddBillParams params) => params.entryKind == EntryKind.saved
      ? CategoryKeys.saved
      : params.kind.match(() => CategoryKeys.bills, (BillKind kind) => kind.categoryKey);

  // why: a saving always goes in by itself; a bill's chip says whether its amount changes (D123).
  static AmountMode _modeOf(AddBillParams params) => params.entryKind == EntryKind.saved
      ? AmountMode.fixed
      : params.kind.match(() => AmountMode.fixed, (BillKind kind) => kind.amountMode);

  static RecurringDraft _draft(BillInput input, ({int categoryId, EntryKind kind, AmountMode mode}) filed, CalendarDate today) {
    final Schedule schedule =
        Schedule(frequency: Frequency.monthly, anchor: RecurringSchedule.monthlyAnchor(input.dueDay, near: today));
    return RecurringDraft(
      label: input.label,
      amount: input.amount,
      kind: filed.kind,
      categoryId: filed.categoryId,
      schedule: schedule,
      nextDue: RecurringSchedule.firstOnOrAfter(schedule, today),
      icon: input.icon,
      amountMode: filed.mode,
    );
  }
}
