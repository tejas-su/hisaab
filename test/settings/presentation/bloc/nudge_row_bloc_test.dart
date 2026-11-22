import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/notifications/nudge_notice.dart';
import 'package:hisaab/core/notifications/nudges.dart';
import 'package:hisaab/settings/domain/usecase/answer_nudge.dart';
import 'package:hisaab/settings/domain/usecase/get_nudge_switch.dart';
import 'package:hisaab/settings/presentation/bloc/nudge_row_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/nudge_row_event.dart';
import 'package:hisaab/settings/presentation/bloc/nudge_row_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_nudges.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late FakeNudges nudges;
  late FakeHaptics haptics;
  late NudgeRowBloc bloc;

  group('NudgeRow values', () {
    test('events and states compare by what they hold', () {
      expect(const NudgeRowLoadRequested(), const NudgeRowLoadRequested());
      expect(const NudgeRowToggled(on: true), const NudgeRowToggled(on: true));
      expect(const NudgeRowToggled(on: true), isNot(const NudgeRowToggled(on: false)));
      expect(const NudgeRowLoading(), const NudgeRowLoading());
      expect(const NudgeRowLoading().props, isEmpty);
      expect(const NudgeRowLoadRequested().props, isEmpty);
    });
  });

  setUp(() {
    preferences = FakeAppPreferencesRepository(done: true);
    nudges = FakeNudges();
    haptics = FakeHaptics();
    bloc = NudgeRowBloc(
      getSwitch: GetNudgeSwitch(preferences: preferences, nudges: nudges),
      answer: AnswerNudge(preferences: preferences, nudges: nudges),
      haptics: haptics,
    );
  });

  tearDown(() async {
    await bloc.close();
    await nudges.dispose();
  });

  group('NudgeRowBloc (FR-SE-7)', () {
    test('starts loading', () => expect(bloc.state, const NudgeRowLoading()));

    test('a never-answered choice loads as off (AC-1)', () async {
      await bloc.dispatch(const NudgeRowLoadRequested());
      expect(bloc.state, const NudgeRowReady(on: false));
      expect(nudges.permissionAsks, 0);
    });

    test('a stored yes loads as on', () async {
      preferences.nudgesOn = const Option<bool>.of(true);
      await bloc.dispatch(const NudgeRowLoadRequested());
      expect(bloc.state, const NudgeRowReady(on: true));
    });

    test('a stored yes with the phone permission off loads as off with the refusal line, no prompt (E122)', () async {
      preferences.nudgesOn = const Option<bool>.of(true);
      nudges.granted = false;
      await bloc.dispatch(const NudgeRowLoadRequested());
      expect(bloc.state, const NudgeRowReady(on: false, refused: true));
      expect(nudges.permissionAsks, 0);
    });

    test('a failed read loads as off', () async {
      preferences.failure = DatabaseFailure('x');
      await bloc.dispatch(const NudgeRowLoadRequested());
      expect(bloc.state, const NudgeRowReady(on: false));
    });

    test('turning on asks Android, stores on, counts a change and ticks (AC-2)', () async {
      await bloc.dispatch(const NudgeRowLoadRequested());
      await bloc.dispatch(const NudgeRowToggled(on: true));
      expect(bloc.state, const NudgeRowReady(on: true, changes: 1));
      expect((preferences.nudgesOn, nudges.permissionAsks), (const Option<bool>.of(true), 1));
      expect(haptics.events, <String>['tick']);
    });

    test('a refusal leaves it off with the refusal line and stores off (AC-2, E122)', () async {
      nudges.granted = false;
      await bloc.dispatch(const NudgeRowLoadRequested());
      await bloc.dispatch(const NudgeRowToggled(on: true));
      expect(bloc.state, const NudgeRowReady(on: false, refused: true, changes: 1));
      expect(preferences.nudgesOn, const Option<bool>.of(false));
    });

    test('turning off stores off without asking Android and clears the refusal (AC-3)', () async {
      preferences.nudgesOn = const Option<bool>.of(true);
      await bloc.dispatch(const NudgeRowLoadRequested());
      await bloc.dispatch(const NudgeRowToggled(on: false));
      expect(bloc.state, const NudgeRowReady(on: false, changes: 1));
      expect(nudges.permissionAsks, 0);
    });

    test('a failed write changes nothing', () async {
      await bloc.dispatch(const NudgeRowLoadRequested());
      preferences.failure = DatabaseFailure('x');
      await bloc.dispatch(const NudgeRowToggled(on: true));
      expect(bloc.state, const NudgeRowReady(on: false));
    });

    test('a flip before the row has loaded is ignored', () async {
      await bloc.dispatch(const NudgeRowToggled(on: true));
      expect(bloc.state, const NudgeRowLoading());
      expect(nudges.permissionAsks, 0);
    });

    test('a second flip while Android is being asked is dropped (droppable)', () async {
      await bloc.dispatch(const NudgeRowLoadRequested());
      final Completer<bool> gate = Completer<bool>();
      final GatedNudges gated = GatedNudges(gate.future);
      final NudgeRowBloc slow = NudgeRowBloc(
        getSwitch: GetNudgeSwitch(preferences: preferences, nudges: gated),
        answer: AnswerNudge(preferences: preferences, nudges: gated),
        haptics: haptics,
      );
      addTearDown(() async {
        await slow.close();
        await gated.dispose();
      });
      slow
        ..add(const NudgeRowLoadRequested())
        ..add(const NudgeRowToggled(on: true));
      await pumpEventQueue();
      slow
        ..add(const NudgeRowToggled(on: true))
        ..add(const NudgeRowToggled(on: true));
      await pumpEventQueue();
      gate.complete(true);
      await pumpEventQueue();
      expect(gated.permissionAsks, 1);
    });
  });
}

/// A [Nudges] whose permission answer waits for [gate].
final class GatedNudges implements Nudges {
  GatedNudges(this.gate);

  final Future<bool> gate;
  int permissionAsks = 0;

  @override
  Future<bool> requestPermission() {
    permissionAsks++;
    return gate;
  }

  Future<void> dispose() async {}

  @override
  Future<void> arm(List<NudgeNotice> upcoming) async {}

  @override
  Future<bool> areEnabled() async => true;

  @override
  Future<bool> launchedByNudge() async => false;

  @override
  Stream<void> get taps => const Stream<void>.empty();
}
