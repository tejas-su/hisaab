import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
import '../../../core/money/currency_spec.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/entities/entry_kind.dart';
import '../../domain/entities/frequency.dart';
import '../../domain/entities/recurring_draft.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/entities/schedule.dart';
import '../model/recurring_model.dart';
import 'entry_kind_mapper.dart';

/// Converts between [RecurringModel] rows and recurring rule entities.
abstract final class RecurringMapper {
  /// Returns [Right] with the rule, or [Left] with `InvalidDataFailure` for an unknown kind,
  /// frequency or currency, a bad date or a row without an id.
  static Either<Failure, RecurringRule> toEntity(RecurringModel model) => CurrencySpec.fromCode(model.currency).flatMap(
        (CurrencySpec currency) => EntryKindMapper.fromValue(model.kind).flatMap(
          (EntryKind kind) => _frequencyOf(model.frequency).flatMap(
            (Frequency frequency) => CalendarDate.parse(model.anchorDate).flatMap(
              (CalendarDate anchor) => CalendarDate.parse(model.nextDue).flatMap(
                (CalendarDate nextDue) => Option<int>.fromNullable(model.id)
                    .toEither<Failure>(() => const InvalidDataFailure('Recurring row without an id'))
                    .map(
                      (int id) => RecurringRule(
                        id: id,
                        label: model.label,
                        amount: Money(model.amountMinor, currency: currency),
                        kind: kind,
                        categoryId: model.categoryId,
                        schedule: Schedule(frequency: frequency, anchor: anchor, lastDayOfMonth: model.lastDayOfMonth),
                        nextDue: nextDue,
                        isIncomeSource: model.isIncomeSource,
                      ),
                    ),
              ),
            ),
          ),
        ),
      );

  /// The row for a new rule from [draft].
  static RecurringModel toModel(RecurringDraft draft) => RecurringModel(
        label: draft.label,
        amountMinor: draft.amount.amountMinor,
        currency: draft.amount.currency.code,
        kind: EntryKindMapper.toValue(draft.kind),
        categoryId: draft.categoryId,
        frequency: _valueOf(draft.schedule.frequency),
        anchorDate: draft.schedule.anchor.toIso(),
        lastDayOfMonth: draft.schedule.lastDayOfMonth,
        nextDue: draft.nextDue.toIso(),
        isIncomeSource: draft.isIncomeSource,
      );

  static String _valueOf(Frequency frequency) => switch (frequency) {
        Frequency.weekly => FrequencyValues.weekly,
        Frequency.biweekly => FrequencyValues.biweekly,
        Frequency.monthly => FrequencyValues.monthly,
        Frequency.yearly => FrequencyValues.yearly,
      };

  static Either<Failure, Frequency> _frequencyOf(String value) => Option<Frequency>.fromNullable(
        Frequency.values.where((Frequency frequency) => _valueOf(frequency) == value).firstOrNull,
      ).toEither<Failure>(() => InvalidDataFailure('Unknown frequency "$value"'));
}
