import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';

/// Which way a big buy can be paid for (SPEC BR-24).
enum AffordVerdict {
  /// `need = 0`: the saved money covers it.
  fromSavings,

  /// `need <= spare`: savings, then the rest on the card, paid in full.
  withCard,

  /// `need > spare > 0`: save `spare` a month.
  saveUp,

  /// `spare = 0`: the usual days already use the monthly money.
  daysFull,

  /// No usable history and `need > 0`: ask again after payday.
  tooEarly,
}

/// The answer to *Can I afford it?* (SPEC BR-24, D217 to D221).
final class AffordAnswer extends Equatable {
  const AffordAnswer({
    required this.verdict,
    required this.need,
    required this.floor,
    required this.spare,
    required this.normalPerDay,
    required this.cardPerDay,
    required this.savingPerDay,
    required this.putIns,
  });

  final AffordVerdict verdict;

  /// What is still missing: `max(0, price - have)`.
  final Money need;

  /// The breathing space a day; [Money.zero] when [AffordVerdict.tooEarly].
  final Money floor;

  /// The most that can be asked a month; [Money.zero] when [AffordVerdict.tooEarly].
  final Money spare;

  /// Next cycle's day amount with nothing set aside.
  final Money normalPerDay;

  /// Day amount if [need] goes on the card; set for every verdict when there is history and
  /// `need > 0`, even when the card path is not the suggested one.
  final Option<Money> cardPerDay;

  /// Day amount while saving [spare] a month; set when `spare > 0`.
  final Option<Money> savingPerDay;

  /// Put-ins to reach [need] at [spare] a month; set for [AffordVerdict.saveUp].
  final Option<int> putIns;

  @override
  List<Object?> get props => <Object?>[
    verdict,
    need,
    floor,
    spare,
    normalPerDay,
    cardPerDay,
    savingPerDay,
    putIns,
  ];
}
