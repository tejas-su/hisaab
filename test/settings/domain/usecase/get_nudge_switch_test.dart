import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/settings/domain/entities/nudge_switch.dart';
import 'package:hisaab/settings/domain/usecase/get_nudge_switch.dart';

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

  Future<NudgeSwitch> reads() async =>
      (await GetNudgeSwitch(preferences: preferences, nudges: nudges)(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));

  group('GetNudgeSwitch (FR-SE-7 AC-1, E122)', () {
    test('never answered reads off and never shows a prompt', () async {
      final NudgeSwitch found = await reads();
      expect((found.on, found.blocked, nudges.permissionAsks), (false, false, 0));
    });

    test('answered no reads off, not blocked', () async {
      preferences.nudgesOn = const Option<bool>.of(false);
      final NudgeSwitch found = await reads();
      expect((found.on, found.blocked), (false, false));
    });

    test('answered yes with notifications allowed reads on', () async {
      preferences.nudgesOn = const Option<bool>.of(true);
      expect((await reads()).on, isTrue);
    });

    test('answered yes but notifications turned off in the phone reads off and blocked, never prompting (E122)', () async {
      preferences.nudgesOn = const Option<bool>.of(true);
      nudges.granted = false;
      final NudgeSwitch found = await reads();
      expect((found.on, found.blocked, nudges.permissionAsks), (false, true, 0));
      expect(preferences.nudgesOn, const Option<bool>.of(true));
    });

    test('a failed read is a Left', () async {
      preferences.failure = DatabaseFailure('x');
      expect((await GetNudgeSwitch(preferences: preferences, nudges: nudges)(const NoParams()).run()).isLeft(), isTrue);
    });
  });

  test('NudgeSwitch compares by both answers', () {
    expect(const NudgeSwitch(answeredYes: true, enabled: false), const NudgeSwitch(answeredYes: true, enabled: false));
    expect(const NudgeSwitch(answeredYes: true, enabled: false), isNot(const NudgeSwitch(answeredYes: true, enabled: true)));
  });
}
