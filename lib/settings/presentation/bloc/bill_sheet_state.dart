import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../ledger/ledger.dart';

/// The bill's answers, each a row on the bill sheet, in row order.
enum BillAnswer { amount, mode, day, name, icon }

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

/// The bill sheet's situation.
sealed class BillSheetState extends Equatable {
  const BillSheetState();
}

/// The sheet is showing the bill, or one question when [open] is some.
///
/// [rupees] and [fresh] are the amount question's keypad value (a fresh value is replaced by
/// the first key); [draftName] is the name question's text. [justSaved] flashes that row and
/// shows "Saved."; [changed] is true once anything has been saved; [rejections] counts refused
/// keys so the amount can shake.
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
      );

  @override
  List<Object?> get props =>
      <Object?>[rule, status, open, rupees, fresh, draftName, justSaved, changed, saving, saveFailed, rejections];
}

/// The sheet should close, reporting [outcome].
final class BillSheetClosed extends BillSheetState {
  const BillSheetClosed(this.outcome);

  final BillSheetOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}
