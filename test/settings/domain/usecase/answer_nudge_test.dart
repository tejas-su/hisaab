import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/settings/domain/usecase/answer_nudge.dart';

import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_nudges.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late FakeNudges nudges;

  setUp(() {
    preferences = FakeAppPreferencesRepository(done: true);
    nudges = FakeNudges();
  });

  tearDown(() => nudges.dispose());

  Future<Either<Failure, bool>> answer({required bool on}) => AnswerNudge(preferences: preferences, nudges: nudges)(on).run();

  group('AnswerNudge (BR-22.8, E122)', () {
    test('Remind me with the permission granted stores on and asks Android once', () async {
      expect(await answer(on: true), const Right<Failure, bool>(true));
      expect((preferences.nudgesOn, nudges.permissionAsks), (const Option<bool>.of(true), 1));
    });

    test('Remind me refused stores off, so it is never asked again', () async {
      nudges.granted = false;
      expect(await answer(on: true), const Right<Failure, bool>(false));
      expect(preferences.nudgesOn, const Option<bool>.of(false));
    });

    test('Not now stores off and never asks Android', () async {
      expect(await answer(on: false), const Right<Failure, bool>(false));
      expect((preferences.nudgesOn, nudges.permissionAsks), (const Option<bool>.of(false), 0));
    });

    test('a failed save is a Left', () async {
      preferences.failure = DatabaseFailure('x');
      expect((await answer(on: true)).isLeft(), isTrue);
    });
  });
}
