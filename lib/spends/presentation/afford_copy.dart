import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/afford_answer.dart';
import 'bloc/afford_state.dart';

/// How amounts and months are put into words: drawn ("₹5,000", "Dec 2027") or spoken
/// ("5,000 rupees", "December 2027").
typedef AffordWords = ({String Function(Money amount) amount, String Function(CalendarDate date) month});

/// One *Other ways* row: its [title] (ending "· suggested" when [suggested]) and its one [line].
typedef AffordWay = ({String title, String line, bool suggested});

/// One day-amount bar: its [label], the [perDay] it shows, and whether it is [filled] ("with
/// this") or an outline ("usually").
typedef AffordBar = ({String label, Money perDay, bool filled});

/// The words of a *Can I afford it?* answer (SPEC BR-24, FR-SP-9 AC-4, AC-5, UI_DESIGN 5.4a).
abstract final class AffordCopy {
  /// Amounts and months as drawn ("₹5,000", "Dec 2027"), or as TalkBack says them when [spoken]
  /// ("5,000 rupees", "December 2027").
  static AffordWords words(MoneyFormatter money, AppLocalizations strings, {required bool spoken}) => (
        amount: (Money amount) => spoken ? strings.spokenAmount(money.digits(amount)) : money.format(amount),
        month: (CalendarDate date) => DateFormat(spoken ? 'MMMM y' : 'MMM y', money.locale).format(DateTime(date.year, date.month)),
      );

  /// The verdict, such as "Not yet.".
  static String verdict(AffordVerdict verdict, AppLocalizations strings) => switch (verdict) {
        AffordVerdict.fromSavings => strings.affordFromSavingsVerdict,
        AffordVerdict.withCard => strings.affordWithCardVerdict,
        AffordVerdict.saveUp || AffordVerdict.daysFull => strings.affordNotYetVerdict,
        AffordVerdict.tooEarly => strings.affordTooEarlyVerdict,
      };

  /// The verdict and its sentences as TalkBack reads them, with amounts and months spoken (AC-9).
  static String spokenAnswer(AffordAnswered state, AppLocalizations strings, MoneyFormatter money) =>
      <String>[verdict(state.answer.verdict, strings), ...sentences(state, strings, words(money, strings, spoken: true))].join(' ');

  /// The one or two sentences under the verdict; none for *Ask again after payday*.
  static List<String> sentences(AffordAnswered state, AppLocalizations strings, AffordWords words) {
    final AffordAnswer answer = state.answer;
    final String have = words.amount(state.draft.haveMoney);
    final String need = words.amount(answer.need);
    return switch (answer.verdict) {
      AffordVerdict.fromSavings => <String>[strings.affordFromSavingsLine(have)],
      AffordVerdict.withCard => <String>[
          state.draft.haveMoney.isZero ? strings.affordCardOnlyLine(need) : strings.affordWithCardLine(have, need),
          strings.affordWithCardDays(words.amount(_perDay(answer.cardPerDay))),
        ],
      AffordVerdict.saveUp => <String>[
          _saveUpLine(state, strings, words),
          strings.affordSaveUpDays(words.amount(_perDay(answer.savingPerDay)), words.amount(answer.normalPerDay)),
        ],
      AffordVerdict.daysFull => <String>[strings.affordDaysFullLine],
      AffordVerdict.tooEarly => const <String>[],
    };
  }

  static String _saveUpLine(AffordAnswered state, AppLocalizations strings, AffordWords words) {
    final String spare = words.amount(state.answer.spare);
    return state.doneBy.match(
      () => strings.affordSaveUpFarLine(spare),
      (CalendarDate date) => strings.affordSaveUpLine(spare, words.month(date)),
    );
  }

  /// The day-amount bars: "usually" for every answer with history, and "with this" when the
  /// card or a saving changes the day amount; none without history.
  static List<AffordBar> bars(AffordAnswered state, AppLocalizations strings) {
    if (state.usual.isNone()) {
      return const <AffordBar>[];
    }
    final AffordAnswer answer = state.answer;
    final AffordBar usually = (label: strings.affordBarUsually, perDay: answer.normalPerDay, filled: false);
    final Option<Money> withThis = switch (answer.verdict) {
      AffordVerdict.withCard => answer.cardPerDay,
      AffordVerdict.saveUp => answer.savingPerDay,
      AffordVerdict.fromSavings || AffordVerdict.daysFull || AffordVerdict.tooEarly => const Option<Money>.none(),
    };
    return <AffordBar>[
      usually,
      ...withThis.match(
        () => const <AffordBar>[],
        (Money perDay) => <AffordBar>[(label: strings.affordBarWithThis, perDay: perDay, filled: true)],
      ),
    ];
  }

  /// The three *Other ways* rows, the one matching the verdict marked as suggested.
  static List<AffordWay> ways(AffordAnswered state, AppLocalizations strings, AffordWords words) {
    final AffordVerdict verdict = state.answer.verdict;
    AffordWay way(String title, String line, AffordVerdict suggests) => (
          title: verdict == suggests ? strings.affordWaySuggested(title) : title,
          line: line,
          suggested: verdict == suggests,
        );
    return <AffordWay>[
      way(strings.affordWayFromSavings, _fromSavingsLine(state, strings, words), AffordVerdict.fromSavings),
      way(strings.affordWayCard, _cardLine(state, strings, words), AffordVerdict.withCard),
      way(strings.affordWaySaveUp, _saveUpWayLine(state, strings, words), AffordVerdict.saveUp),
    ];
  }

  static String _fromSavingsLine(AffordAnswered state, AppLocalizations strings, AffordWords words) {
    final Money have = state.draft.haveMoney;
    if (state.answer.need.isZero) {
      return strings.affordWayCovered(words.amount(have));
    }
    return have.isZero
        ? strings.affordWayNothingSaved(words.amount(state.answer.need))
        : strings.affordWayShort(words.amount(have), words.amount(state.answer.need));
  }

  // why: the card's day amount is clamped at ₹0 when the room is smaller than the need, so below
  // the breathing space it is worded against the floor, never as "about ₹0 a day".
  static String _cardLine(AffordAnswered state, AppLocalizations strings, AffordWords words) {
    final AffordAnswer answer = state.answer;
    if (answer.need.isZero) {
      return strings.affordWayNotNeeded;
    }
    final String need = words.amount(answer.need);
    return answer.cardPerDay.match(
      () => strings.affordWayNotYet,
      (Money perDay) => perDay < answer.floor
          ? strings.affordWayCardBelow(need, words.amount(answer.floor))
          : strings.affordWayCardFits(need, words.amount(perDay)),
    );
  }

  static String _saveUpWayLine(AffordAnswered state, AppLocalizations strings, AffordWords words) {
    final AffordAnswer answer = state.answer;
    if (answer.need.isZero) {
      return strings.affordWayNotNeeded;
    }
    if (answer.verdict == AffordVerdict.tooEarly) {
      return strings.affordWayNotYet;
    }
    if (answer.spare.isZero) {
      return strings.affordWayNothingSpare;
    }
    final String spare = words.amount(answer.spare);
    return state.doneBy.match(
      () => strings.affordWaySaveFar(spare),
      (CalendarDate date) => strings.affordWaySaveFits(spare, words.month(date)),
    );
  }

  static Money _perDay(Option<Money> perDay) => perDay.getOrElse(() => Money.zero);
}
