import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/settings/domain/usecase/should_ask_nudge.dart';

import '../../../helpers/fakes/fake_app_preferences_repository.dart';

void main() {
  late FakeAppPreferencesRepository preferences;

  setUp(() => preferences = FakeAppPreferencesRepository(done: true));

  Future<bool> shouldAsk() async =>
      (await ShouldAskNudge(preferences: preferences)(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));

  group('ShouldAskNudge (BR-22.8, FR-SE-7 AC-4)', () {
    test('never answered: ask (the caller runs it only after the missed-log tap)', () async => expect(await shouldAsk(), isTrue));

    test('answered either way: never asked again', () async {
      preferences.nudgesOn = const Option<bool>.of(true);
      expect(await shouldAsk(), isFalse);
      preferences.nudgesOn = const Option<bool>.of(false);
      expect(await shouldAsk(), isFalse);
    });

    test('a failed read is a Left', () async {
      preferences.failure = DatabaseFailure('x');
      expect((await ShouldAskNudge(preferences: preferences)(const NoParams()).run()).isLeft(), isTrue);
    });
  });
}
