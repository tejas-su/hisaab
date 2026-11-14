import '../../core/design/app_icons.dart';
import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/cycle_bar.dart';
import '../domain/entities/spends_comparison.dart';
import 'cycle_label.dart';
import 'month_story_copy.dart';

/// A comparison line as shown and as spoken, with its arrow ([arrow] is null for "Same as").
typedef ComparisonWords = ({String shown, String spoken, AppIconData? arrow});

/// The words of the Spends graphs (SPEC BR-21, FR-SP-3a, FR-SP-4, FR-SP-8; copy deck 46).
final class SpendsGraphCopy {
  SpendsGraphCopy({required this.strings, required this.shown, required this.spoken, required this.locale, required this.today});

  final AppLocalizations strings;
  final AmountWriter shown;
  final AmountWriter spoken;
  final String locale;

  /// Names cycles as the switcher does.
  final CalendarDate today;

  /// Shorter than this, a cycle is a week ("the week before").
  static const int _monthDays = 28;

  /// The pace card's line: [comparison] against [previous].
  ComparisonWords comparison(SpendsComparison comparison, PayCycle previous) {
    final String before = _isWeek(previous) ? strings.spendsCompareWeekBefore : strings.spendsCompareInCycle(_name(previous));
    String line(AmountWriter amount) => comparison.wholeCycle
        ? strings.spendsCompareDone(_direction(comparison.change), amount(_size(comparison.change)), before)
        : strings.spendsCompareNow(_direction(comparison.change), amount(_size(comparison.change)), before);
    return (shown: line(shown), spoken: line(spoken), arrow: _arrow(comparison.change));
  }

  /// An opened row's change against [previous], named short ("Sep") or "the week before".
  ComparisonWords rowChange(Money change, PayCycle previous) {
    final String before = _isWeek(previous) ? strings.spendsCompareWeekBefore : CycleLabel.rangeOf(<PayCycle>[previous], locale: locale).$1;
    String line(AmountWriter amount) => strings.spendsRowChange(_direction(change), amount(_size(change)), before);
    return (shown: line(shown), spoken: line(spoken), arrow: _arrow(change));
  }

  /// The strip's sentence for [bar], written with [amount]: "September: spent ₹39,600, saved ₹1,000.
  /// ₹4,400 left over." (FR-SP-8).
  String readOut(CycleBar bar, AmountWriter amount) {
    final String name = bar.isRunning ? strings.spendsStripSoFar(_name(bar.cycle)) : _name(bar.cycle);
    if (!bar.hasEntries) {
      return strings.spendsStripReadNone(name);
    }
    final String spent = bar.saved.isZero
        ? strings.spendsStripReadSpent(name, amount(bar.spent))
        : strings.spendsStripReadSpentSaved(name, amount(bar.spent), amount(bar.saved));
    return '$spent ${_tail(bar, amount)}'.trim();
  }

  /// The strip's title and count for [strip].
  (String, String?) stripHeading(MonthsStrip strip, int shownCount) {
    final String unit = _isWeek(strip.bars.last.cycle) ? 'week' : 'month';
    final String title = strings.spendsStripTitle(unit, shownCount);
    final int counted = strip.counted;
    if (counted == 0) {
      return (title, null);
    }
    final int left = strip.leftOver;
    final String count = switch (left) {
      0 => strings.spendsStripLeftNone(unit, counted),
      _ when left == counted && counted == 2 => strings.spendsStripLeftBoth(unit),
      _ when left == counted => strings.spendsStripLeftAll(unit, counted),
      _ => strings.spendsStripLeftSome(unit, left, counted),
    };
    return (title, count);
  }

  /// A cycle's short label under its bar: "May", or a weekly cycle's start date.
  String barLabel(PayCycle cycle) =>
      _isWeek(cycle) ? MonthStoryCopy.shortDate(cycle.start, locale) : CycleLabel.rangeOf(<PayCycle>[cycle], locale: locale).$1;

  String _tail(CycleBar bar, AmountWriter amount) {
    if (bar.isRunning) {
      return strings.spendsStripDaysToGo(bar.daysLeft);
    }
    if (!bar.hasIncome) {
      return '';
    }
    if (bar.left.isZero) {
      return strings.spendsSplitNoneDone;
    }
    return bar.left.isNegative ? '${strings.storyMoreThanCameIn(amount(Money.zero - bar.left))}.' : '${strings.storyLeftOver(amount(bar.left))}.';
  }

  String _name(PayCycle cycle) => CycleLabel.of(cycle, locale: locale, today: today);

  static bool _isWeek(PayCycle cycle) => cycle.lengthInDays < _monthDays;

  static String _direction(Money change) =>
      change.amountMinor.abs() < SpendsComparison.sameWithin.amountMinor ? 'same' : (change.isNegative ? 'less' : 'more');

  static Money _size(Money change) => Money(change.amountMinor.abs());

  static AppIconData? _arrow(Money change) => switch (_direction(change)) {
        'less' => AppIcons.less,
        'more' => AppIcons.more,
        _ => null,
      };
}
