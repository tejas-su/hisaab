import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/settings/settings.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [AppPreferencesRepository]; set [failure] to make every call fail.
final class FakeAppPreferencesRepository implements AppPreferencesRepository {
  FakeAppPreferencesRepository({this.done = false, this.draftJson});

  bool done;
  String? draftJson;
  Failure? failure;

  /// Failure for [markOnboardingDone] only.
  Failure? markDoneFailure;

  TaskEither<Failure, T> _run<T>(T Function() action, [Failure? override]) {
    final Failure? current = override ?? failure;
    return current == null ? TaskEither<Failure, T>.right(action()) : TaskEither<Failure, T>.left(current);
  }

  @override
  TaskEither<Failure, bool> onboardingDone() => _run(() => done);

  @override
  TaskEither<Failure, Unit> markOnboardingDone() => _run(() {
        done = true;
        draftJson = null;
        return unit;
      }, markDoneFailure);

  @override
  TaskEither<Failure, Option<String>> onboardingDraft() => _run(() => Option<String>.fromNullable(draftJson));

  @override
  TaskEither<Failure, Unit> saveOnboardingDraft(String json) => _run(() {
        draftJson = json;
        return unit;
      });
}
