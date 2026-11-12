import 'dart:math' as math;

import 'package:fpdart/fpdart.dart';

import 'entities/time_window.dart';
import 'habit_rules.dart';

/// The time-of-day maths of *your usual*: slots, recency weights and the window (SPEC BR-17).
abstract final class TimeProfile {
  static const int _minutesPerHour = 60;

  /// The half-hour slot (0–47) [at] falls into, read from its own wall-clock fields (E62).
  static int slotOf(DateTime at) => minuteOf(at) ~/ HabitRules.slotMinutes;

  /// The minute of the day (0–1439) of [at], read from its own wall-clock fields (E62).
  static int minuteOf(DateTime at) => at.hour * _minutesPerHour + at.minute;

  /// How much an entry logged [ageDays] ago counts: 1 today, half every 14 days.
  static double weightOf(int ageDays) => math.pow(0.5, ageDays / HabitRules.halfLifeDays).toDouble();

  /// The window of a profile whose 48 slots hold the summed weights [slotWeights], unsmoothed.
  ///
  /// The slots are smoothed ¼ · ½ · ¼; the window is the run of slots around the highest one that
  /// are strictly above half of it, widened by 15 minutes each side and never longer than a day.
  ///
  /// Returns [None] when no slot has any weight, or when the run takes in every slot: a flat
  /// profile has no usual time (E71).
  static Option<TimeWindow> windowOf(List<double> slotWeights) {
    final List<double> smoothed = _smooth(slotWeights);
    final int peak = _peakOf(smoothed);
    if (smoothed[peak] <= 0) {
      return const Option<TimeWindow>.none();
    }
    final int before = _runLength(smoothed, peak, step: -1);
    final int slots = before + 1 + _runLength(smoothed, peak, step: 1);
    if (slots >= HabitRules.slotsPerDay) {
      return const Option<TimeWindow>.none();
    }
    return Option<TimeWindow>.of(_widen(startSlot: peak - before, slots: slots));
  }

  /// Each slot as itself twice plus its two neighbours, wrapping at midnight: ¼ · ½ · ¼ times 4,
  /// which leaves every comparison between slots unchanged.
  static List<double> _smooth(List<double> weights) => List<double>.generate(
        weights.length,
        (int slot) =>
            weights[(slot - 1) % weights.length] + 2 * weights[slot] + weights[(slot + 1) % weights.length],
      );

  static int _peakOf(List<double> smoothed) => List<int>.generate(smoothed.length, (int slot) => slot).reduce(
        // why: strictly greater keeps the earlier slot when two are equally high (BR-17, E71).
        (int best, int slot) => smoothed[slot] > smoothed[best] ? slot : best,
      );

  /// How many slots in a row beside [peak], going [step] (−1 earlier, 1 later), belong to its run.
  static int _runLength(List<double> smoothed, int peak, {required int step}) =>
      List<int>.generate(smoothed.length - 1, (int index) => index + 1)
          // why: strictly above half, so a lone busy slot does not pull in its two neighbours,
          // which smooth to exactly half of it (BR-17).
          .takeWhile((int distance) => 2 * smoothed[(peak + step * distance) % smoothed.length] > smoothed[peak])
          .length;

  static TimeWindow _widen({required int startSlot, required int slots}) => TimeWindow(
        startMinute: (startSlot * HabitRules.slotMinutes - HabitRules.widenMinutes) % HabitRules.minutesPerDay,
        lengthMinutes: math.min(
          slots * HabitRules.slotMinutes + 2 * HabitRules.widenMinutes,
          HabitRules.minutesPerDay,
        ),
      );
}
