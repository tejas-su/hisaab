import 'package:equatable/equatable.dart';

import '../../../core/errors/failure.dart';
import '../../../ledger/ledger.dart';

/// What the *Used some of it* keypad shows (BR-19, AC-Y6 to AC-Y9).
sealed class UsedState extends Equatable {
  const UsedState();

  @override
  List<Object?> get props => <Object?>[];
}

/// What is set aside is being read; the keypad waits.
final class UsedLoading extends UsedState {
  const UsedLoading();
}

/// What is set aside couldn't be read; the question says so.
final class UsedFailed extends UsedState {
  const UsedFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

/// The use was saved; the sheet closes and the caller offers Undo.
final class UsedDone extends UsedState {
  const UsedDone(this.outcome);

  final UsedOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// The keypad, with [rupees] typed against [setAsideRupees] of [saving].
final class UsedReady extends UsedState {
  const UsedReady({
    required this.saving,
    required this.setAsideRupees,
    this.rupees = 0,
    this.rejections = 0,
    this.capShown = false,
    this.replaceNext = false,
    this.writing = false,
    this.saveFailed = false,
  });

  final RecurringRule saving;

  /// Whole rupees set aside in [saving]: the most that can be used.
  final int setAsideRupees;

  /// The amount typed; 0 means nothing typed, which is refused (AC-Y6).
  final int rupees;

  /// Counts refused keys, so the amount can shake and the cap ring can be held each time.
  final int rejections;

  /// A key past what is set aside was refused, so the slot says why until the next accepted key (AC-Y8).
  final bool capShown;

  /// *All of it* filled the amount, so the first digit replaces it instead of adding (FR-AD-8).
  final bool replaceNext;

  /// A save is in flight.
  final bool writing;
  final bool saveFailed;

  /// *All of it* is selected while the amount equals everything set aside (AC-Y6, AC-Y11).
  bool get allSelected => rupees > 0 && rupees == setAsideRupees;

  /// Nothing is set aside to use, so *Save* is off (AC-Y8).
  bool get nothingToUse => setAsideRupees < 1;

  /// Whether *Save* may be tapped.
  bool get canSave => !writing && rupees > 0 && rupees <= setAsideRupees;

  /// Returns a copy with the given fields replaced; [saveFailed] resets unless passed.
  UsedReady copyWith({
    int? setAsideRupees,
    int? rupees,
    int? rejections,
    bool? capShown,
    bool? replaceNext,
    bool? writing,
    bool saveFailed = false,
  }) =>
      UsedReady(
        saving: saving,
        setAsideRupees: setAsideRupees ?? this.setAsideRupees,
        rupees: rupees ?? this.rupees,
        rejections: rejections ?? this.rejections,
        capShown: capShown ?? this.capShown,
        replaceNext: replaceNext ?? this.replaceNext,
        writing: writing ?? this.writing,
        saveFailed: saveFailed,
      );

  @override
  List<Object?> get props =>
      <Object?>[saving, setAsideRupees, rupees, rejections, capShown, replaceNext, writing, saveFailed];
}
