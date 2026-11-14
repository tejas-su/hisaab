import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../ledger/ledger.dart';

/// What the *Fix my number* sheet shows.
sealed class FixState extends Equatable {
  const FixState();

  @override
  List<Object?> get props => <Object?>[];
}

/// hisaab's figure is being read: the helper shows and *Fix it* is off.
final class FixLoading extends FixState {
  const FixLoading();
}

/// hisaab's figure could not be read: "Couldn't check your number." with Try again.
final class FixFailed extends FixState {
  const FixFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

/// *Fix it* wrote the entry; the sheet closes and the caller offers Undo.
final class FixDone extends FixState {
  const FixDone(this.outcome);

  final FixOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// A line shown in the slot until the next key (FR-FX-3).
enum FixNotice {
  /// Nothing extra.
  none,

  /// "Things changed. Check the new amount." (the save was refused, or the ledger moved).
  changed,

  /// "Count only this month's money." after the guard's *No*.
  countOnly,

  /// "Couldn't save. Try again."
  saveFailed,
}

/// The question the guard is asking, with when it opened and the gap it showed.
final class FixGuard extends Equatable {
  const FixGuard({required this.openedAt, required this.seenGapRupees});

  /// When the guard panel appeared; its keys ignore input for 300 ms after (E85).
  final DateTime openedAt;

  /// The signed whole rupees the panel asked about; *Yes* posts only if it is still this (FR-FX-4 AC-5).
  final int seenGapRupees;

  @override
  List<Object?> get props => <Object?>[openedAt, seenGapRupees];
}

/// The keypad (or the guard) over hisaab's figure.
final class FixReady extends FixState {
  const FixReady({
    required this.summary,
    this.typed = const Option<int>.none(),
    this.guard = const Option<FixGuard>.none(),
    this.notice = FixNotice.none,
    this.rejections = 0,
    this.saving = false,
  });

  final CycleSummary summary;

  /// `T`: none while empty, so a typed 0 ("I have none left") is a different state (E74).
  final Option<int> typed;

  /// Some while the guard question replaces the keypad (FR-FX-4).
  final Option<FixGuard> guard;
  final FixNotice notice;

  /// Counts refused 10th digits, for the shake and the held ring (FR-KS-2).
  final int rejections;
  final bool saving;

  /// The comparison of [typed] with hisaab's figure; derived, never stored (BR-18).
  FixPreview get preview => FixMyNumber.preview(summary, typed);

  FixReady copyWith({
    CycleSummary? summary,
    Option<int>? typed,
    Option<FixGuard>? guard,
    FixNotice? notice,
    int? rejections,
    bool? saving,
  }) =>
      FixReady(
        summary: summary ?? this.summary,
        typed: typed ?? this.typed,
        guard: guard ?? this.guard,
        notice: notice ?? this.notice,
        rejections: rejections ?? this.rejections,
        saving: saving ?? this.saving,
      );

  @override
  List<Object?> get props => <Object?>[summary, typed, guard, notice, rejections, saving];
}
