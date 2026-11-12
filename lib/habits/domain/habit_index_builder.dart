import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../ledger/ledger.dart';
import 'entities/day_type.dart';
import 'entities/habit_index.dart';
import 'entities/habit_inputs.dart';
import 'entities/suggestion_state.dart';
import 'entities/time_window.dart';
import 'entities/usual_habit.dart';
import 'habit_rules.dart';
import 'time_profile.dart';
import 'usual_amount.dart';

/// Works out the day's [HabitIndex] from the ledger (SPEC BR-17). Pure: no clock, no database.
abstract final class HabitIndexBuilder {
  /// Builds the index of [today] from [inputs].
  ///
  /// It holds a habit for every shown *Spent* category and day type that passes BR-17's four
  /// rules, the categories already logged [today], and the stored states unchanged.
  static HabitIndex build(HabitInputs inputs, {required CalendarDate today}) {
    final List<Entry> learned = _learned(inputs.entries, today);
    final _Days days = _Days(today, learned.map((Entry entry) => entry.date).toSet());
    return HabitIndex(
      builtOn: today,
      habits: _warmedUp(days)
          ? inputs.categories
              .where((Category category) => category.kind == EntryKind.spent && !category.hidden)
              .expand((Category category) => _habitsOf(category.id, _own(learned, category, inputs.states), days))
              .toList()
          : const <UsualHabit>[],
      loggedToday:
          inputs.entries.where((Entry entry) => entry.date == today).map((Entry entry) => entry.categoryId).toSet(),
      states: inputs.states,
    );
  }

  /// The entries a habit can be learned from, in any category: typed *Spent* entries of the last
  /// 56 days that were logged on the day they are dated.
  static List<Entry> _learned(List<Entry> entries, CalendarDate today) => entries.where((Entry entry) {
        final int age = entry.date.daysUntil(today);
        return entry.kind == EntryKind.spent &&
            entry.recurringId == null &&
            CalendarDate.fromDateTime(entry.createdAt) == entry.date &&
            age >= 0 &&
            age < HabitRules.horizonDays;
      }).toList();

  /// Rule 1, for the whole app: enough days of use before anything is suggested.
  static bool _warmedUp(_Days days) =>
      days.active.length >= HabitRules.minActiveDays &&
      days.active.any((CalendarDate date) => date.daysUntil(days.today) >= HabitRules.warmUpDays);

  /// The entries of [category] that feed its own habit: those logged since its last *Forget*.
  static List<Entry> _own(List<Entry> learned, Category category, Map<int, SuggestionState> states) {
    final Option<DateTime> forgottenAt = Option<SuggestionState>.fromNullable(states[category.id]).flatMap(
      (SuggestionState state) => state.forgottenAt,
    );
    return learned
        .where((Entry entry) => entry.categoryId == category.id)
        .where((Entry entry) => forgottenAt.match(() => true, (DateTime at) => !entry.createdAt.isBefore(at)))
        .toList();
  }

  static Iterable<UsualHabit> _habitsOf(int categoryId, List<Entry> own, _Days days) {
    final _Profile pooled = _profile(own, const Option<DayType>.none(), days);
    return DayType.values.expand(
      (DayType type) => _withFallback(_profile(own, Option<DayType>.of(type), days), pooled, days)
          .flatMap((_Profile profile) => _habit(categoryId, type, profile, days))
          .match(() => const <UsualHabit>[], (UsualHabit habit) => <UsualHabit>[habit]),
    );
  }

  /// The time profile of [entries] on days of [type], or on all days when [type] is none, and how
  /// it does against rules 2 to 4.
  static _Profile _profile(List<Entry> entries, Option<DayType> type, _Days days) {
    final List<Entry> ofType = entries.where((Entry entry) => _isOf(type, entry.date)).toList();
    final Option<TimeWindow> window = TimeProfile.windowOf(_slotWeights(ofType, days.today));
    final List<Entry> hits = window.match(
      () => const <Entry>[],
      (TimeWindow window) =>
          ofType.where((Entry entry) => window.contains(TimeProfile.minuteOf(entry.createdAt))).toList(),
    );
    return _Profile(
      type: type,
      window: window,
      hits: hits,
      amount: UsualAmount.pick(
        hits.map((Entry entry) => (amount: entry.amount, weight: _weight(entry, days.today))).toList(),
      ),
      // why: rule 3 counts "the 28 days before today", so an entry made earlier today can't
      // lower the share before the window has even opened.
      active: days.activeBefore(HabitRules.shareDays, type),
    );
  }

  static bool _isOf(Option<DayType> type, CalendarDate date) =>
      type.match(() => true, (DayType type) => DayType.of(date) == type);

  static double _weight(Entry entry, CalendarDate today) => TimeProfile.weightOf(entry.date.daysUntil(today));

  static List<double> _slotWeights(List<Entry> entries, CalendarDate today) => List<double>.generate(
        HabitRules.slotsPerDay,
        (int slot) => entries
            .where((Entry entry) => TimeProfile.slotOf(entry.createdAt) == slot)
            .fold(0, (double sum, Entry entry) => sum + _weight(entry, today)),
      );

  /// The profile a day type is offered from: its own when Regular, else the pooled one when the
  /// day type only fell short on count or share. [None] when neither holds.
  static Option<_Profile> _withFallback(_Profile own, _Profile pooled, _Days days) {
    if (own.regular) {
      return Option<_Profile>.of(own);
    }
    // why: without entries of its own inside the pooled window, a strong weekday habit would
    // leak into weekends it has never been logged on (E64).
    final int ownHits = pooled.hits.where((Entry entry) {
      final int age = entry.date.daysUntil(days.today);
      return _isOf(own.type, entry.date) && age >= 1 && age <= HabitRules.shareDays;
    }).length;
    final bool usePooled =
        own.shortOnlyOnCountOrShare && pooled.regular && ownHits >= HabitRules.pooledMinOwnHits;
    return usePooled ? Option<_Profile>.of(pooled) : const Option<_Profile>.none();
  }

  static Option<UsualHabit> _habit(int categoryId, DayType type, _Profile profile, _Days days) =>
      profile.window.flatMap(
        (TimeWindow window) => profile.amount.map(
          (Money amount) => UsualHabit(
            categoryId: categoryId,
            dayType: type,
            pooled: profile.type.isNone(),
            window: window,
            amount: amount,
            hitDays: profile.hitDays,
            activeDays: profile.active.length,
            lastHit: profile.hits
                .map((Entry entry) => entry.createdAt)
                .reduce((DateTime latest, DateTime at) => at.isAfter(latest) ? at : latest),
            fading: _fading(profile, type, days),
          ),
        ),
      );

  /// Whether the window was missed on the 3 most recent days of [type] with any learned entry.
  /// Days with no entry are never misses.
  static bool _fading(_Profile profile, DayType type, _Days days) {
    final List<CalendarDate> expected = days.activeBefore(HabitRules.horizonDays - 1, Option<DayType>.of(type)).toList()
      ..sort((CalendarDate a, CalendarDate b) => b.compareTo(a));
    return !expected.take(HabitRules.missedRun).any(profile.hitDates.contains);
  }
}

/// Today, and every date with a learned entry in any category.
final class _Days {
  const _Days(this.today, this.active);

  final CalendarDate today;

  // why: every category counts here, hidden and forgotten ones too. Otherwise hiding or
  // forgetting one category would shrink the days every other habit is measured against, and
  // could make one Regular by itself (BR-17).
  final Set<CalendarDate> active;

  /// The active dates in the [days] days before today, of [type] when given. Never today.
  Iterable<CalendarDate> activeBefore(int days, Option<DayType> type) => active.where((CalendarDate date) {
        final int age = date.daysUntil(today);
        return age >= 1 && age <= days && type.match(() => true, (DayType type) => DayType.of(date) == type);
      });
}

/// One category's time profile on one day type (or pooled, when [type] is none), with what
/// rules 2 to 4 need.
final class _Profile {
  _Profile({
    required this.type,
    required this.window,
    required this.hits,
    required this.amount,
    required Iterable<CalendarDate> active,
  })  : active = active.toList(),
        hitDates = hits.map((Entry entry) => entry.date).toSet();

  final Option<DayType> type;
  final Option<TimeWindow> window;

  /// The profile's entries logged inside [window].
  final List<Entry> hits;

  /// Rule 4's amount, if one reaches 70%.
  final Option<Money> amount;

  /// Rule 3's days: those before today with any learned entry.
  final List<CalendarDate> active;
  final Set<CalendarDate> hitDates;

  int get hitDays => active.where(hitDates.contains).length;

  bool get _enoughHits => hits.length >= HabitRules.minHits;

  bool get _enoughDays =>
      active.isNotEmpty && HabitRules.dayShareDen * hitDays >= HabitRules.dayShareNum * active.length;

  /// Rules 2, 3 and 4 hold (rule 1 is checked once for the whole app).
  bool get regular => _enoughHits && _enoughDays && amount.isSome();

  /// Not Regular, and rule 4 is not what failed: with no hits there is no amount to disagree on.
  bool get shortOnlyOnCountOrShare => !regular && (hits.isEmpty || amount.isSome());
}
