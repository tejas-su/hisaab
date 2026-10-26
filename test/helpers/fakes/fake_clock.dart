import 'package:expense_tracker/core/time/clock.dart';

/// A [Clock] pinned to [current]; move it with [advance] to test midnight and catch-up.
final class FakeClock extends Clock {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;

  /// Moves the clock forward by [duration].
  void advance(Duration duration) => current = current.add(duration);
}
