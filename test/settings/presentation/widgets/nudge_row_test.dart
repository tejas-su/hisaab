import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/settings/domain/usecase/answer_nudge.dart';
import 'package:hisaab/settings/domain/usecase/get_nudge_switch.dart';
import 'package:hisaab/settings/presentation/bloc/nudge_row_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/nudge_row_event.dart';
import 'package:hisaab/settings/presentation/widgets/nudge_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_nudges.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late FakeNudges nudges;
  late int changed;

  setUp(() {
    preferences = FakeAppPreferencesRepository(done: true);
    nudges = FakeNudges();
    changed = 0;
  });

  tearDown(() => nudges.dispose());

  const ValueKey<String> row = ValueKey<String>('nudge-row');

  Future<void> show(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1}) async {
    final NudgeRowBloc bloc = await tester.buildBloc(
      () => NudgeRowBloc(
        getSwitch: GetNudgeSwitch(preferences: preferences, nudges: nudges),
        answer: AnswerNudge(preferences: preferences, nudges: nudges),
        haptics: FakeHaptics(),
      )..add(const NudgeRowLoadRequested()),
    );
    addTearDown(() => tester.runAsync(bloc.close));
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: <Widget>[BlocProvider<NudgeRowBloc>.value(value: bloc, child: NudgeRow(onChanged: () => changed++))],
        ),
      ),
      size: size,
      textScale: textScale,
    );
    await tester.settle();
  }

  bool switchOn(WidgetTester tester) => tester.widget<Switch>(find.byType(Switch)).value;

  group('NudgeRow (FR-SE-7)', () {
    testWidgets('reads Daily nudge with its hint and the switch off until turned on (AC-1)', (WidgetTester tester) async {
      await show(tester);
      expect(find.text('Daily nudge'), findsOneWidget);
      expect(find.text('A gentle reminder when you usually spend'), findsOneWidget);
      expect(switchOn(tester), isFalse);
    });

    testWidgets('sits under a Reminders heading that TalkBack reads as a header (AC-1)', (WidgetTester tester) async {
      await show(tester);
      expect(find.text('Reminders'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Reminders')),
        matchesSemantics(label: 'Reminders', isHeader: true),
      );
      expect(tester.getTopLeft(find.text('Reminders')).dy, lessThan(tester.getTopLeft(find.text('Daily nudge')).dy));
    });

    testWidgets('a stored yes reads on', (WidgetTester tester) async {
      preferences.nudgesOn = const Option<bool>.of(true);
      await show(tester);
      expect(switchOn(tester), isTrue);
    });

    testWidgets('the phone permission being off reads off with its line, without a prompt (E122)', (WidgetTester tester) async {
      preferences.nudgesOn = const Option<bool>.of(true);
      nudges.granted = false;
      await show(tester);
      expect(switchOn(tester), isFalse);
      expect(find.text("Allow notifications in your phone's settings to turn this on."), findsOneWidget);
      expect(nudges.permissionAsks, 0);
    });

    testWidgets('tapping the row turns it on, asks Android, stores it and reports the change (AC-2)', (WidgetTester tester) async {
      await show(tester);
      await tester.tap(find.byKey(row));
      await tester.settle();
      expect(switchOn(tester), isTrue);
      expect((preferences.nudgesOn, nudges.permissionAsks, changed), (const Option<bool>.of(true), 1, 1));
    });

    testWidgets('tapping the switch itself flips it too', (WidgetTester tester) async {
      await show(tester);
      await tester.tap(find.byType(Switch));
      await tester.settle();
      expect(preferences.nudgesOn, const Option<bool>.of(true));
    });

    testWidgets('a refusal leaves it off and shows the line under it (AC-2)', (WidgetTester tester) async {
      nudges.granted = false;
      await show(tester);
      await tester.tap(find.byKey(row));
      await tester.settle();
      expect(switchOn(tester), isFalse);
      expect(find.text("Allow notifications in your phone's settings to turn this on."), findsOneWidget);
      expect(changed, 1);
    });

    testWidgets('turning off stores off and reports the change so every nudge is cancelled (AC-3)', (WidgetTester tester) async {
      preferences.nudgesOn = const Option<bool>.of(true);
      await show(tester);
      await tester.tap(find.byKey(row));
      await tester.settle();
      expect(switchOn(tester), isFalse);
      expect((preferences.nudgesOn, changed), (const Option<bool>.of(false), 1));
      expect(find.textContaining('Allow notifications'), findsNothing);
    });

    testWidgets('TalkBack reads Daily nudge as a switch, off then on (AC-5)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await show(tester);
      expect(
        tester.getSemantics(find.byKey(row)),
        matchesSemantics(label: 'Daily nudge', hasToggledState: true, hasTapAction: true, hasEnabledState: false),
      );
      await tester.tap(find.byKey(row));
      await tester.settle();
      expect(
        tester.getSemantics(find.byKey(row)),
        matchesSemantics(label: 'Daily nudge', hasToggledState: true, isToggled: true, hasTapAction: true, hasEnabledState: false),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await show(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final Size size in <Size>[
      TestWindows.phone,
      TestWindows.phoneLandscape,
      TestWindows.smallPhone,
      TestWindows.foldableUnfolded,
      TestWindows.foldableLandscape,
      TestWindows.tablet,
    ]) {
      for (final double scale in <double>[1, 2]) {
        testWidgets('is at least 56dp tall and fits ${size.width.toInt()}x${size.height.toInt()} at ${scale}x text (AC-5)', (WidgetTester tester) async {
          nudges.granted = false;
          await show(tester, size: size, textScale: scale);
          await tester.tap(find.byKey(row));
          await tester.settle();
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byKey(row)).height, greaterThanOrEqualTo(NudgeRow.minHeight));
        });
      }
    }
  });
}
