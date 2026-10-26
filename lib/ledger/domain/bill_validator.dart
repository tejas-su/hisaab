import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/money/money.dart';
import 'entities/bill_input.dart';
import 'entry_validator.dart';
import 'failures/ledger_failures.dart';

/// Checks a fixed bill before it is saved (SPEC FR-SE-1, BR-10 amounts).
abstract final class BillValidator {
  /// The longest bill name allowed, after trimming.
  static const int maxLabelLength = 40;

  static const int _lastDayOfMonth = 31;

  /// Validates [input]: a non-blank name of at most [maxLabelLength] characters, an amount of
  /// ₹1 to ₹99,99,99,999 and a due day of 1–31.
  ///
  /// Returns [Right] with the input, its name trimmed, or [Left] with [InvalidBillNameFailure],
  /// `InvalidAmountFailure` or [InvalidDataFailure] (due day).
  static Either<Failure, BillInput> validate(BillInput input) {
    final String label = input.label.trim();
    if (label.isEmpty || label.length > maxLabelLength) {
      return Either<Failure, BillInput>.left(InvalidBillNameFailure('Bill name has ${label.length} characters'));
    }
    if (input.dueDay < 1 || input.dueDay > _lastDayOfMonth) {
      return Either<Failure, BillInput>.left(InvalidDataFailure('Due day ${input.dueDay}'));
    }
    return EntryValidator.validateAmount(input.amount)
        .map((Money amount) => BillInput(label: label, amount: amount, dueDay: input.dueDay));
  }
}
