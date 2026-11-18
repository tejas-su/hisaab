import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/habits/domain/entities/nudge_state.dart';
import 'package:hisaab/habits/domain/repository/nudge_state_repository.dart';

/// An in-memory [NudgeStateRepository]; set [failure] to make every call fail with it.
final class FakeNudgeStateRepository implements NudgeStateRepository {
  FakeNudgeStateRepository([Iterable<NudgeState> states = const <NudgeState>[]])
      : states = <int, NudgeState>{for (final NudgeState state in states) state.categoryId: state};

  /// The stored states by category id, changed in place as the database would be.
  final Map<int, NudgeState> states;
  Failure? failure;

  TaskEither<Failure, T> _run<T>(T Function() action) {
    final Failure? current = failure;
    return current == null ? TaskEither<Failure, T>.right(action()) : TaskEither<Failure, T>.left(current);
  }

  @override
  TaskEither<Failure, Map<int, NudgeState>> all() => _run(() => Map<int, NudgeState>.of(states));

  @override
  TaskEither<Failure, Unit> put(NudgeState state) => _run(() {
        states[state.categoryId] = state;
        return unit;
      });

  @override
  TaskEither<Failure, Unit> clear() => _run(() {
        states.clear();
        return unit;
      });
}
