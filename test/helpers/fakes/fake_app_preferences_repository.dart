import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [AppPreferencesRepository]; set [failure] to make every call fail.
final class FakeAppPreferencesRepository implements AppPreferencesRepository {
  FakeAppPreferencesRepository({
    this.done = false,
    this.draftJson,
    this.reminders = const Option<bool>.none(),
    this.theme = ThemeChoice.matchPhone,
  });

  bool done;
  String? draftJson;

  /// The answer to "Remind you on the day it's due?"; [None] when never asked.
  Option<bool> reminders;
  /// The saved look (FR-SE-3).
  ThemeChoice theme;
  Failure? failure;

  /// Failure for [markOnboardingDone] only.
  Failure? markDoneFailure;

  /// When set, [markOnboardingDone] waits for it, so a test can see the in-between state.
  Completer<void>? markDoneGate;

  TaskEither<Failure, T> _run<T>(T Function() action, [Failure? override]) {
    final Failure? current = override ?? failure;
    return current == null ? TaskEither<Failure, T>.right(action()) : TaskEither<Failure, T>.left(current);
  }

  @override
  TaskEither<Failure, bool> onboardingDone() => _run(() => done);

  @override
  TaskEither<Failure, Unit> markOnboardingDone() {
    final Completer<void>? gate = markDoneGate;
    final TaskEither<Failure, Unit> mark = _run(() {
      done = true;
      draftJson = null;
      return unit;
    }, markDoneFailure);
    return gate == null ? mark : TaskEither<Failure, Unit>(() async {
      await gate.future;
      return Either<Failure, Unit>.right(unit);
    }).flatMap((Unit _) => mark);
  }

  @override
  TaskEither<Failure, Option<String>> onboardingDraft() => _run(() => Option<String>.fromNullable(draftJson));

  @override
  TaskEither<Failure, Unit> saveOnboardingDraft(String json) => _run(() {
        draftJson = json;
        return unit;
      });

  @override
  TaskEither<Failure, Option<bool>> billRemindersChoice() => _run(() => reminders);

  @override
  TaskEither<Failure, Unit> saveBillRemindersChoice({required bool remind}) => _run(() {
        reminders = Option<bool>.of(remind);
        return unit;
      });

  @override
  TaskEither<Failure, ThemeChoice> themeChoice() => _run(() => theme);

  @override
  TaskEither<Failure, Unit> saveThemeChoice(ThemeChoice choice) => _run(() {
        theme = choice;
        return unit;
      });
}
