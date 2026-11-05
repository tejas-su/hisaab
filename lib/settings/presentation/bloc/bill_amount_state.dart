import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';

/// What the bill amount sheet shows (D123).
sealed class BillAmountState extends Equatable {
  const BillAmountState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Reading what was entered last time; the keypad waits.
final class BillAmountLoading extends BillAmountState {
  const BillAmountLoading();
}

/// The bill was entered or skipped; the sheet closes with [outcome].
final class BillAmountDone extends BillAmountState {
  const BillAmountDone(this.outcome);

  final BillAmountOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// The keypad for [occurrence], prefilled with its estimate.
final class BillAmountEditing extends BillAmountState {
  const BillAmountEditing({
    required this.occurrence,
    required this.rupees,
    this.lastTime = const Option<Money>.none(),
    this.fresh = true,
    this.rejections = 0,
    this.saving = false,
    this.saveFailed = false,
  });

  final Occurrence occurrence;
  final int rupees;

  /// The amount entered last time; none before the first time, when the caption says what was
  /// guessed at setup instead.
  final Option<Money> lastTime;

  /// True while the prefilled estimate is untouched, so the first key replaces it.
  final bool fresh;

  /// Counts refused keys, so the amount can shake each time.
  final int rejections;
  final bool saving;
  final bool saveFailed;

  /// Returns a copy with the given fields replaced; [saveFailed] resets unless passed.
  BillAmountEditing copyWith({int? rupees, bool? fresh, int? rejections, bool? saving, bool saveFailed = false}) => BillAmountEditing(
        occurrence: occurrence,
        rupees: rupees ?? this.rupees,
        lastTime: lastTime,
        fresh: fresh ?? this.fresh,
        rejections: rejections ?? this.rejections,
        saving: saving ?? this.saving,
        saveFailed: saveFailed,
      );

  @override
  List<Object?> get props => <Object?>[occurrence, rupees, lastTime, fresh, rejections, saving, saveFailed];
}
