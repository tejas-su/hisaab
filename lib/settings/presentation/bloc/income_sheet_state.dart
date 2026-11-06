import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_rule.dart';
import '../../../ledger/ledger.dart';

/// The steps of the *When it comes* question: the five choices, the 1–31 grid, the weekdays.
enum IncomeWhenStep { choices, day, weekday }

/// The income sheet's situation (SPEC FR-SE-1, D137, D140).
sealed class IncomeSheetState extends Equatable {
  const IncomeSheetState();
}

/// The sheet shows the income slip, the amount question when [amountOpen], or a step of the
/// *When it comes* question when [step] is some.
///
/// [rupees] and [fresh] are the keypad's value (a fresh value is replaced by the first key).
/// [justSaved] flashes the changed row and shows "Changed."; [changed] is true once anything was
/// saved. [fixable] is the posted pay that *Change this month too* would change; [corrected] is
/// that pay as it was before, kept for Undo. [rejections] counts refused keys so the amount shakes.
/// [draft] is the pay rule picked on the question and [preview] today's summary with it;
/// [pendingRule] is a fixed day picked after "It changes", waiting for its amount; [lastsTill] is
/// the current cycle's new end after a payday change.
final class IncomeSheetReady extends IncomeSheetState {
  const IncomeSheetReady({
    required this.income,
    this.amountOpen = false,
    this.rupees = 0,
    this.fresh = false,
    this.justSaved = false,
    this.changed = false,
    this.fixable = const Option<Entry>.none(),
    this.corrected = const Option<Entry>.none(),
    this.step = const Option<IncomeWhenStep>.none(),
    this.draft = const Option<PayRule>.none(),
    this.preview = const Option<CycleSummary>.none(),
    this.pendingRule = const Option<PayRule>.none(),
    this.lastsTill = const Option<CalendarDate>.none(),
    this.saving = false,
    this.saveFailed = false,
    this.rejections = 0,
  });

  final Income income;
  final bool amountOpen;
  final int rupees;
  final bool fresh;
  final bool justSaved;
  final bool changed;
  final Option<Entry> fixable;
  final Option<Entry> corrected;
  final Option<IncomeWhenStep> step;
  final Option<PayRule> draft;
  final Option<CycleSummary> preview;
  final Option<PayRule> pendingRule;
  final Option<CalendarDate> lastsTill;
  final bool saving;
  final bool saveFailed;
  final int rejections;

  /// When the money comes now.
  PayRule get payRule => PayRuleSchedule.payRuleOf(income.rule);

  /// Whether the picked rule differs from the current one, so *Save* has something to save.
  bool get draftChanged => draft.match(() => false, (PayRule rule) => rule != payRule);

  /// Returns a copy with the given fields replaced; [saving] and [saveFailed] reset unless passed.
  IncomeSheetReady copyWith({
    Income? income,
    bool? amountOpen,
    int? rupees,
    bool? fresh,
    bool? justSaved,
    bool? changed,
    Option<Entry>? fixable,
    Option<Entry>? corrected,
    Option<IncomeWhenStep>? step,
    Option<PayRule>? draft,
    Option<CycleSummary>? preview,
    Option<PayRule>? pendingRule,
    Option<CalendarDate>? lastsTill,
    bool saving = false,
    bool saveFailed = false,
    int? rejections,
  }) =>
      IncomeSheetReady(
        income: income ?? this.income,
        amountOpen: amountOpen ?? this.amountOpen,
        rupees: rupees ?? this.rupees,
        fresh: fresh ?? this.fresh,
        justSaved: justSaved ?? this.justSaved,
        changed: changed ?? this.changed,
        fixable: fixable ?? this.fixable,
        corrected: corrected ?? this.corrected,
        step: step ?? this.step,
        draft: draft ?? this.draft,
        preview: preview ?? this.preview,
        pendingRule: pendingRule ?? this.pendingRule,
        lastsTill: lastsTill ?? this.lastsTill,
        saving: saving,
        saveFailed: saveFailed,
        rejections: rejections ?? this.rejections,
      );

  @override
  List<Object?> get props => <Object?>[
        income,
        amountOpen,
        rupees,
        fresh,
        justSaved,
        changed,
        fixable,
        corrected,
        step,
        draft,
        preview,
        pendingRule,
        lastsTill,
        saving,
        saveFailed,
        rejections,
      ];
}

/// The sheet should close.
final class IncomeSheetClosed extends IncomeSheetState {
  const IncomeSheetClosed();

  @override
  List<Object?> get props => <Object?>[];
}
