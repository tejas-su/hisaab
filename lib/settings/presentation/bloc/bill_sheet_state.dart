import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// The bill's answers, each a row on the bill sheet, in row order.
///
/// [target] is a saving's *Saving up to* (BR-23, AC-T1).
enum BillAnswer { amount, mode, day, name, icon, target, used }

/// What the bill sheet did, for the screen that opened it to act on (D118).
sealed class BillSheetOutcome extends Equatable {
  const BillSheetOutcome();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing was saved.
final class BillSheetUnchanged extends BillSheetOutcome {
  const BillSheetUnchanged();
}

/// One or more answers were saved; [rule] is the bill as it is now.
final class BillSheetChanged extends BillSheetOutcome {
  const BillSheetChanged(this.rule);

  final RecurringRule rule;

  @override
  List<Object?> get props => <Object?>[rule];
}

/// The user asked to delete [rule]; the opening screen deletes it and offers Undo.
final class BillSheetDeleted extends BillSheetOutcome {
  const BillSheetDeleted(this.rule);

  final RecurringRule rule;

  @override
  List<Object?> get props => <Object?>[rule];
}

/// A cost was used from the saving, and its *Used some of it* write finished; the opening screen
/// offers Undo for it (AC-Y9).
final class BillSheetUsed extends BillSheetOutcome {
  const BillSheetUsed(this.outcome);

  final UsedOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// *I bought it* used the whole set-aside amount and deleted the saving; the opening screen offers
/// one Undo that restores both (AC-T9, D213).
final class BillSheetBought extends BillSheetOutcome {
  const BillSheetBought(this.outcome);

  final UsedOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// The bill sheet's situation.
sealed class BillSheetState extends Equatable {
  const BillSheetState();
}

/// The sheet is showing the bill, or one question when [open] is some.
///
/// [rupees] and [fresh] are the amount question's keypad value (a fresh value is replaced by
/// the first key); [draftName] is the name question's text. [justSaved] flashes that row and
/// shows "Saved."; [changed] is true once anything has been saved; [rejections] counts refused
/// keys so the amount can shake. [setAside] is what a saving still has set aside, once read
/// (BR-19); it decides whether *Used some of it* shows. [today] comes from the sheet's clock, so a
/// target's month carries its year only when it is not this year (BR-23). [dayEffect] is read when
/// the *Saving up to* question opens, so each typed digit can say how today's share moves (AC-T3).
final class BillSheetReady extends BillSheetState {
  const BillSheetReady({
    required this.rule,
    this.status = const Option<BillStatus>.none(),
    this.open = const Option<BillAnswer>.none(),
    this.rupees = 0,
    this.fresh = false,
    this.draftName = '',
    this.justSaved = const Option<BillAnswer>.none(),
    this.changed = false,
    this.saving = false,
    this.saveFailed = false,
    this.rejections = 0,
    this.setAside = const Option<Money>.none(),
    this.today = const Option<CalendarDate>.none(),
    this.dayEffect = const Option<TargetDayEffect>.none(),
  });

  final RecurringRule rule;
  final Option<BillStatus> status;
  final Option<BillAnswer> open;
  final int rupees;
  final bool fresh;
  final String draftName;
  final Option<BillAnswer> justSaved;
  final bool changed;
  final bool saving;
  final bool saveFailed;
  final int rejections;
  final Option<Money> setAside;
  final Option<CalendarDate> today;
  final Option<TargetDayEffect> dayEffect;

  /// True when a saving with a target has at least that much set aside: it has stopped putting in
  /// and offers *I bought it* and *Keep saving* (BR-23, D213).
  bool get reached => switch ((rule.target, setAside)) {
        (Some<Money>(value: final Money target), Some<Money>(value: final Money aside)) => aside.compareTo(target) >= 0,
        _ => false,
      };

  /// How far the saving is from its target, for the slip's line (AC-T6); none without a target.
  Option<TargetProgress> get targetProgress => rule.target.map(_progressTo);

  /// How far the saving is from the amount typed on the *Saving up to* question (AC-T3); none at ₹0.
  Option<TargetProgress> get typedProgress =>
      rupees == 0 ? const Option<TargetProgress>.none() : Option<TargetProgress>.of(_progressTo(Money.fromMajor(rupees)));

  /// How the amount typed on the *Saving up to* question moves today's share (AC-T3, BR-23): above
  /// ₹0 it goes up, below ₹0 down. None at ₹0 typed, or before the effect is read.
  Option<Money> get typedDayChange => rupees == 0
      ? const Option<Money>.none()
      : dayEffect.map((TargetDayEffect effect) => effect.changeFor(Money.fromMajor(rupees)));

  TargetProgress _progressTo(Money target) =>
      SavingTarget.progress(target: target, setAside: setAside.getOrElse(() => Money.zero), saving: rule);

  /// What closing the sheet now would report.
  BillSheetOutcome get outcome => changed ? BillSheetChanged(rule) : const BillSheetUnchanged();

  /// Returns a copy with the given fields replaced; [saving] and [saveFailed] reset unless passed.
  BillSheetReady copyWith({
    RecurringRule? rule,
    Option<BillStatus>? status,
    Option<BillAnswer>? open,
    int? rupees,
    bool? fresh,
    String? draftName,
    Option<BillAnswer>? justSaved,
    bool? changed,
    bool saving = false,
    bool saveFailed = false,
    int? rejections,
    Option<Money>? setAside,
    Option<TargetDayEffect>? dayEffect,
  }) =>
      BillSheetReady(
        rule: rule ?? this.rule,
        status: status ?? this.status,
        open: open ?? this.open,
        rupees: rupees ?? this.rupees,
        fresh: fresh ?? this.fresh,
        draftName: draftName ?? this.draftName,
        justSaved: justSaved ?? this.justSaved,
        changed: changed ?? this.changed,
        saving: saving,
        saveFailed: saveFailed,
        rejections: rejections ?? this.rejections,
        setAside: setAside ?? this.setAside,
        today: today,
        dayEffect: dayEffect ?? this.dayEffect,
      );

  @override
  List<Object?> get props =>
      <Object?>[rule, status, open, rupees, fresh, draftName, justSaved, changed, saving, saveFailed, rejections, setAside, today, dayEffect];
}

/// The sheet should close, reporting [outcome].
final class BillSheetClosed extends BillSheetState {
  const BillSheetClosed(this.outcome);

  final BillSheetOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}
