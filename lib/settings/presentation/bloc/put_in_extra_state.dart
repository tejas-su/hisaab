import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';

/// What the *Put in extra* sheet shows (D120).
sealed class PutInExtraState extends Equatable {
  const PutInExtraState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Today's summary is loading; the keypad waits.
final class PutInExtraLoading extends PutInExtraState {
  const PutInExtraLoading();
}

/// Today's summary couldn't be read; the sheet says so.
final class PutInExtraFailed extends PutInExtraState {
  const PutInExtraFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

/// The saving went in; the sheet closes.
final class PutInExtraDone extends PutInExtraState {
  const PutInExtraDone();
}

/// The keypad, with [rupees] typed against today's [summary].
final class PutInExtraReady extends PutInExtraState {
  const PutInExtraReady({
    required this.summary,
    this.rupees = 0,
    this.rejections = 0,
    this.saving = false,
    this.saveFailed = false,
  });

  final CycleSummary summary;
  final int rupees;

  /// Counts refused keys, so the amount can shake each time.
  final int rejections;
  final bool saving;
  final bool saveFailed;

  /// The most that can go in: what is left for the cycle, in whole rupees.
  int get roomRupees => math.max(0, summary.remaining.floorMajor);

  /// Nothing is left this cycle, so nothing can be put in.
  bool get nothingLeft => roomRupees == 0;

  /// What [rupees] does to the days left; [None] at ₹0.
  Option<PutInPreview> get preview =>
      rupees == 0 ? const Option<PutInPreview>.none() : Option<PutInPreview>.of(SafeToSpend.previewPutIn(summary, Money.fromMajor(rupees)));

  /// Returns a copy with the given fields replaced; [saveFailed] resets unless passed.
  PutInExtraReady copyWith({int? rupees, int? rejections, bool? saving, bool saveFailed = false}) => PutInExtraReady(
        summary: summary,
        rupees: rupees ?? this.rupees,
        rejections: rejections ?? this.rejections,
        saving: saving ?? this.saving,
        saveFailed: saveFailed,
      );

  @override
  List<Object?> get props => <Object?>[summary, rupees, rejections, saving, saveFailed];
}
