import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/entry_kind.dart';
import '../domain/entities/recurring_rule.dart';

/// Picks a bill's or a saving's words for the shared list, wizard and sheet (D120).
///
/// A bill (*Spent*) "goes out"; a saving (*Saved*) "goes in". Any other kind reads as a bill.
extension RuleWords on AppLocalizations {
  /// The list's title: "Fixed bills" or "Savings".
  String ruleListTitle(EntryKind kind) => _isSaving(kind) ? savings : fixedBills;

  /// The hint under the list's title.
  String ruleListHint(EntryKind kind) => _isSaving(kind) ? savingsHint : fixedBillsHint;

  /// The add button.
  String ruleAdd(EntryKind kind) => _isSaving(kind) ? addSaving : addBill;

  /// The empty list.
  String ruleNone(EntryKind kind) => _isSaving(kind) ? noSavings : noBills;

  /// The wizard's first question.
  String ruleNameQuestion(EntryKind kind) => _isSaving(kind) ? savingNameQuestion : billNameQuestion;

  /// The name field's hint.
  String ruleNameHint(EntryKind kind) => _isSaving(kind) ? savingNameHint : billNameHint;

  /// "How much is {label}?" or "How much goes into {label}?".
  String ruleAmountQuestion(EntryKind kind, String label) =>
      _isSaving(kind) ? savingAmountQuestion(label) : billAmountQuestion(label);

  /// "Which day does {label} go out?" or "… go in?".
  String ruleDayQuestion(EntryKind kind, String label) => _isSaving(kind) ? savingDayQuestion(label) : billDayQuestion(label);

  /// The sheet's small label above the name.
  String ruleEyebrow(EntryKind kind) => _isSaving(kind) ? savingSheetEyebrow : billSheetEyebrow;

  /// The sheet's delete key.
  String ruleDelete(EntryKind kind) => _isSaving(kind) ? deleteSaving : deleteBill;

  /// The sheet's foot: when the next one goes out or in.
  String ruleNext(EntryKind kind, String date) => _isSaving(kind) ? savingNextGoesIn(date) : billNextGoesOut(date);

  /// The stamp before the day.
  String ruleStampDue(EntryKind kind, int days) => _isSaving(kind) ? savingStampDue(days) : billStampDue(days);

  /// The stamp once this month's posted.
  String ruleStampCounted(EntryKind kind, String date) => _isSaving(kind) ? savingStampCounted(date) : billStampCounted(date);

  /// The stamp when this month's posted today.
  String ruleStampCountedToday(EntryKind kind) => _isSaving(kind) ? savingStampCountedToday : billStampCountedToday;

  /// The snackbar after [rule] is deleted.
  String ruleDeleted(RecurringRule rule) => _isSaving(rule.kind) ? savingDeleted(rule.label) : billDeleted(rule.label);

  /// Home's nudge for [rule], [days] away; a saving names the [weekday] (D120).
  String ruleGoesOut(RecurringRule rule, String amount, int days, String weekday) =>
      _isSaving(rule.kind) ? savingGoesIn(rule.label, amount, days, weekday) : billGoesOut(rule.label, amount, days);

  /// TalkBack's hint on the nudge.
  String ruleOpensHint(EntryKind kind) => _isSaving(kind) ? dueSoonOpensSaving : dueSoonOpensBill;

  static bool _isSaving(EntryKind kind) => kind == EntryKind.saved;
}
