import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../bill_validator.dart';
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

/// A new bill from Settings; [kind] is the chip it started from, if any (it picks the category).
final class AddBillParams extends Equatable {
  const AddBillParams({required this.input, this.kind = const Option<BillKind>.none()});

  final BillInput input;
  final Option<BillKind> kind;

  @override
  List<Object?> get props => <Object?>[input, kind];
}

/// Saves a new fixed monthly bill from Settings (SPEC FR-SE-1).
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
    final String categoryKey = params.kind.match(() => CategoryKeys.bills, (BillKind kind) => kind.categoryKey);
    return TaskEither<Failure, BillInput>.fromEither(BillValidator.validate(params.input)).flatMap(
      (BillInput input) => _categoryId(categoryKey).flatMap((int categoryId) => _recurring.add(_draft(input, categoryId, today))),
    );
  }

  TaskEither<Failure, int> _categoryId(String key) => _categories.all().flatMap(
        (List<Category> categories) => TaskEither<Failure, int>.fromOption(
          Option<Category>.fromNullable(categories.where((Category c) => c.key == key).firstOrNull).map((Category c) => c.id),
          () => InvalidDataFailure('No "$key" category'),
        ),
      );

  static RecurringDraft _draft(BillInput input, int categoryId, CalendarDate today) {
    final Schedule schedule =
        Schedule(frequency: Frequency.monthly, anchor: RecurringSchedule.monthlyAnchor(input.dueDay, near: today));
    return RecurringDraft(
      label: input.label,
      amount: input.amount,
      kind: EntryKind.spent,
      categoryId: categoryId,
      schedule: schedule,
      nextDue: RecurringSchedule.firstOnOrAfter(schedule, today),
    );
  }
}
