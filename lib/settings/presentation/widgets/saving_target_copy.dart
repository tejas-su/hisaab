import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// A line drawn one way and read another: [shown] may carry "·", a no-break space and a short
/// month; [spoken] has neither and names the month in full (AC-T7, AC-T12 B4).
typedef SpokenLine = ({String shown, String spoken});

/// The words of a saving's target (SPEC BR-23): its line on the slip and in the list, and the live
/// line under the *Saving up to* question.
extension SavingTargetCopy on BuildContext {
  /// The month of [date]: short when drawn ("May"), in full when [spoken] ("May"), with the year
  /// when it is not [today]'s year, or when today is unknown ("May 2027").
  String targetMonth(CalendarDate date, {required Option<CalendarDate> today, bool spoken = false}) {
    final bool thisYear = today.map((CalendarDate day) => day.year == date.year).getOrElse(() => false);
    final String month = spoken ? 'MMMM' : 'MMM';
    return DateFormat(thisYear ? month : '$month y', Localizations.localeOf(this).toString()).format(DateTime(date.year, date.month));
  }

  /// The slip's and the list's line for a saving with [target], [setAside] and [progress]
  /// (BR-23 display table, AC-T5, AC-T6).
  SpokenLine targetLine({
    required TargetProgress progress,
    required Money target,
    required Money setAside,
    required Option<CalendarDate> today,
  }) {
    final AppLocalizations strings = AppLocalizations.of(this);
    final bool none = !(setAside > Money.zero);
    final ({String shown, String spoken}) aside = _amount(setAside);
    final ({String shown, String spoken}) up = _amount(target);
    return switch (progress) {
      TargetReached() => (
          shown: strings.savingTargetReached(aside.shown, up.shown),
          spoken: strings.savingTargetReachedSpoken(aside.spoken, up.spoken),
        ),
      TargetEstimate(:final CalendarDate doneOn) when none => (
          shown: strings.savingTargetEstimateNone(up.shown, targetMonth(doneOn, today: today)),
          spoken: strings.savingTargetEstimateNoneSpoken(up.spoken, targetMonth(doneOn, today: today, spoken: true)),
        ),
      TargetEstimate(:final CalendarDate doneOn) => (
          shown: strings.savingTargetEstimate(aside.shown, targetMonth(doneOn, today: today)),
          spoken: strings.savingTargetEstimateSpoken(aside.spoken, targetMonth(doneOn, today: today, spoken: true)),
        ),
      TargetFar() when none => (shown: strings.savingTargetFarNone(up.shown), spoken: strings.savingTargetFarNoneSpoken(up.spoken)),
      TargetFar() => (shown: strings.savingTargetFar(aside.shown), spoken: strings.savingTargetFarSpoken(aside.spoken)),
    };
  }

  /// Line 1 of the *Saving up to* slot for a typed target's [progress] on [saving] (AC-T3).
  SpokenLine targetLiveLine({required TargetProgress progress, required RecurringRule saving, required Option<CalendarDate> today}) {
    final AppLocalizations strings = AppLocalizations.of(this);
    final ({String shown, String spoken}) monthly = _amount(saving.amount);
    return switch (progress) {
      TargetReached() => (shown: strings.savingTargetLiveReached, spoken: strings.savingTargetLiveReached),
      TargetEstimate(:final CalendarDate doneOn) => (
          shown: strings.savingTargetLive(monthly.shown, targetMonth(doneOn, today: today)),
          spoken: strings.savingTargetLiveSpoken(monthly.spoken, targetMonth(doneOn, today: today, spoken: true)),
        ),
      TargetFar() => (shown: strings.savingTargetLiveFar(monthly.shown), spoken: strings.savingTargetLiveFarSpoken(monthly.spoken)),
    };
  }

  SpokenLine _amount(Money amount) =>
      (shown: money.format(amount), spoken: AppLocalizations.of(this).spokenAmount(money.digits(amount)));
}
