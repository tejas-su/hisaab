import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/amount_mode.dart';
import '../domain/entities/entry.dart';
import '../domain/entities/entry_kind.dart';
import '../domain/entities/recurring_rule.dart';

/// Picks a bill's or a saving's words for the shared list, wizard and sheet (D120).
///
/// A bill (*Spent*) "goes out"; a saving (*Saved*) "goes in". Any other kind reads as a bill.
extension RuleWords on AppLocalizations {
  /// The list's title: "Bills" or "Savings".
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

  /// "How much for {label} each month?", "How much do you put in {label} each month?", or
  /// "About how much…" for a bill
  /// whose amount changes or a card bill (D123).
  String ruleAmountQuestion(EntryKind kind, String label, AmountMode mode) {
    if (_isSaving(kind)) {
      return savingAmountQuestion(label);
    }
    return switch (mode) {
      AmountMode.fixed => billAmountQuestion(label),
      AmountMode.varies => billAmountQuestionVaries(label),
      AmountMode.card => billAmountQuestionCard(label),
    };
  }

  /// The *Kind of bill* answer for [mode] (D123).
  String amountModeName(AmountMode mode) => switch (mode) {
        AmountMode.fixed => billModeFixed,
        AmountMode.varies => billModeVaries,
        AmountMode.card => billModeCard,
      };

  /// "Which day of the month for {label}?", for a bill or a saving.
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

  /// The snackbar after [entry], of [amount], is deleted: a saving its rule put in reads as a
  /// skipped month, named by its note (the rule's name, D120), never a loss (case study 17);
  /// anything else says what was deleted.
  String entryRemoved(Entry entry, String amount) =>
      _isSaving(entry.kind) && entry.recurringId != null ? savingSkipped(entry.note ?? savingName('other')) : entryDeleted(amount);

  /// Home's nudge for [rule], [days] away; a saving names the [weekday] (D120), and a bill
  /// whose amount changes, or a card bill, says "about" (D123).
  String ruleGoesOut(RecurringRule rule, String amount, int days, String weekday) {
    if (_isSaving(rule.kind)) {
      return savingGoesIn(rule.label, amount, days, weekday);
    }
    return rule.amountMode == AmountMode.fixed ? billGoesOut(rule.label, amount, days) : billGoesOutAbout(rule.label, amount, days);
  }

  /// Home's line for a bill waiting for its amount since [date]; [isToday] when that is today (D123).
  String ruleWaiting(RecurringRule rule, String date, {required bool isToday}) => switch ((rule.amountMode, isToday)) {
        (AmountMode.card, true) => waitingCardToday(rule.label),
        (AmountMode.card, false) => waitingCardOn(rule.label, date),
        (_, true) => waitingVariesToday(rule.label),
        (_, false) => waitingVariesOn(rule.label, date),
      };

  /// TalkBack's hint on the nudge.
  String ruleOpensHint(EntryKind kind) => _isSaving(kind) ? dueSoonOpensSaving : dueSoonOpensBill;

  static bool _isSaving(EntryKind kind) => kind == EntryKind.saved;
}
