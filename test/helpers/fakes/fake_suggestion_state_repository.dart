import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/repository/suggestion_state_repository.dart';

/// An in-memory [SuggestionStateRepository]; set [failure] to make every call fail with it, or
/// [writeFailure] to fail only [put] and [remove].
final class FakeSuggestionStateRepository implements SuggestionStateRepository {
  FakeSuggestionStateRepository([Iterable<SuggestionState> states = const <SuggestionState>[]])
      : states = <int, SuggestionState>{for (final SuggestionState state in states) state.categoryId: state};

  /// The stored states by category id, changed in place as the database would be.
  final Map<int, SuggestionState> states;
  Failure? failure;
  Failure? writeFailure;

  /// Every call in order, as `all`, `of:<id>`, `put:<id>` or `remove:<id>`.
  final List<String> calls = <String>[];

  /// When set, the next [all] takes the states as they are now but answers only once this
  /// completes. Only habits code reads this repository, so it holds back a habits load alone.
  Completer<void>? nextReadGate;

  TaskEither<Failure, T> _run<T>(T Function() action, {bool write = false}) {
    final Failure? current = failure ?? (write ? writeFailure : null);
    return current == null ? TaskEither<Failure, T>.right(action()) : TaskEither<Failure, T>.left(current);
  }

  @override
  TaskEither<Failure, Map<int, SuggestionState>> all() {
    calls.add('all');
    final Completer<void>? gate = nextReadGate;
    nextReadGate = null;
    final TaskEither<Failure, Map<int, SuggestionState>> read = _run(() => Map<int, SuggestionState>.of(states));
    return gate == null
        ? read
        : TaskEither<Failure, Unit>(() async {
            await gate.future;
            return Either<Failure, Unit>.right(unit);
          }).flatMap((Unit _) => read);
  }

  @override
  TaskEither<Failure, Option<SuggestionState>> of(int categoryId) {
    calls.add('of:$categoryId');
    return _run(() => Option<SuggestionState>.fromNullable(states[categoryId]));
  }

  @override
  TaskEither<Failure, Unit> put(SuggestionState state) {
    calls.add('put:${state.categoryId}');
    return _run(() {
      states[state.categoryId] = state;
      return unit;
    }, write: true);
  }

  @override
  TaskEither<Failure, Unit> remove(int categoryId) {
    calls.add('remove:$categoryId');
    return _run(() {
      states.remove(categoryId);
      return unit;
    }, write: true);
  }
}
