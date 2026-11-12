import 'dart:async';

import 'package:hisaab/backup/backup.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_backup_repository.dart';
import '../../../helpers/fakes/fake_bill_reminders.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/pump_app.dart';

const CalendarDate _today = CalendarDate(2026, 11, 6);
const ValueKey<String> _hold = ValueKey<String>('hold-to-delete');

void main() {
  late FakeBackupRepository backups;
  late FakeHaptics haptics;
  late int deleted;

  setUp(() {
    backups = FakeBackupRepository();
    haptics = FakeHaptics();
    deleted = 0;
  });

  Future<void> pumpPage(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1, bool reduceMotion = false}) async {
    final YourHisaabBloc yourHisaab = await tester.buildBloc(
      () => YourHisaabBloc(backups: backups, clock: FakeClock(DateTime(2026, 11, 6, 10)), haptics: haptics),
    );
    final DeleteEverythingBloc delete = await tester.buildBloc(
      () => DeleteEverythingBloc(deleteEverything: DeleteEverything(backups: backups, reminders: FakeBillReminders()), haptics: haptics),
    );
    addTearDown(yourHisaab.close);
    addTearDown(delete.close);
    await pumpApp(
      tester,
      MultiBlocProvider(
        providers: <BlocProvider<Object?>>[
          BlocProvider<YourHisaabBloc>.value(value: yourHisaab),
          BlocProvider<DeleteEverythingBloc>.value(value: delete),
        ],
        child: DeleteEverythingPage(today: _today, haptics: haptics, onDeleted: () => deleted++),
      ),
      size: size,
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    yourHisaab.add(const YourHisaabLoadRequested());
    await tester.settle();
  }

  /// Puts a finger on the key and waits for the tap-down, so the fill has started.
  Future<TestGesture> press(WidgetTester tester) async {
    final TestGesture finger = await tester.startGesture(tester.getCenter(find.byKey(_hold)));
    await tester.pump(kPressTimeout);
    await tester.pump();
    return finger;
  }

  Future<void> holdFor(WidgetTester tester, Duration duration) async {
    final TestGesture finger = await press(tester);
    await tester.pump(duration);
    await finger.up();
    await tester.settle();
  }

  group('DeleteEverythingPage (FR-SE-4 AC-4..8)', () {
    testWidgets('says what goes, what stays, and that there is no backup yet', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.textContaining('This clears hisaab on this phone.'), findsOneWidget);
      expect(find.text('This goes:'), findsOneWidget);
      expect(find.text('Every entry you added'), findsOneWidget);
      expect(find.text('Look and your other settings'), findsOneWidget);
      expect(find.text("Once it's deleted, there's no getting it back."), findsOneWidget);
      expect(find.text('Backup files you made stay where you put them.'), findsOneWidget);
      expect(find.text('Not backed up yet. Back up first to keep a copy.'), findsOneWidget);
      expect(find.text('Hold to delete everything'), findsWidgets);
      expect(find.text('Press and hold to delete.'), findsOneWidget);
    });

    testWidgets('shows the last backup day when there is one', (WidgetTester tester) async {
      backups.statusAnswer = Either<Failure, BackupStatus>.right(
        const BackupStatus(lastBackedUp: Option<CalendarDate>.of(CalendarDate(2026, 10, 12)), undo: Option<RestoreUndo>.none()),
      );

      await pumpPage(tester);

      expect(find.text('Last backed up 12 Oct'), findsOneWidget);
    });

    testWidgets('a full 1.5 s hold deletes on release, with a tick and a threshold (AC-6)', (WidgetTester tester) async {
      await pumpPage(tester);

      final TestGesture finger = await press(tester);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.text('Let go to delete'), findsWidgets);
      expect(backups.wipes, 0);
      await finger.up();
      await tester.settle();

      expect(backups.wipes, 1);
      expect(deleted, 1);
      expect(haptics.events, <String>['tick', 'threshold']);
    });

    testWidgets('letting go early drains it and deletes nothing', (WidgetTester tester) async {
      await pumpPage(tester);

      await holdFor(tester, const Duration(seconds: 1));

      expect(backups.wipes, 0);
      expect(find.text('Keep holding till it fills up.'), findsOneWidget);
      expect(find.text('Hold to delete everything'), findsWidgets);
    });

    testWidgets('sliding off the key cancels', (WidgetTester tester) async {
      await pumpPage(tester);

      final TestGesture finger = await press(tester);
      await tester.pump(const Duration(milliseconds: 1600));
      await finger.moveBy(const Offset(0, -200));
      await finger.up();
      await tester.settle();

      expect(backups.wipes, 0);
    });

    testWidgets('with reduced motion a full hold still deletes', (WidgetTester tester) async {
      await pumpPage(tester, reduceMotion: true);

      await holdFor(tester, const Duration(milliseconds: 1600));

      expect(backups.wipes, 1);
    });

    testWidgets('with reduced motion an early release drains at once', (WidgetTester tester) async {
      await pumpPage(tester, reduceMotion: true);

      await holdFor(tester, const Duration(milliseconds: 1300));

      expect(backups.wipes, 0);
      expect(find.text('Keep holding till it fills up.'), findsOneWidget);
    });

    testWidgets('with TalkBack it arms on the first tap and deletes on the second (AC-7)', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpPage(tester);

      await tester.tap(find.byKey(_hold));
      await tester.pump();
      expect(find.text('Double-tap again to delete everything'), findsWidgets);
      expect(backups.wipes, 0);

      await tester.tap(find.byKey(_hold));
      await tester.settle();
      expect(backups.wipes, 1);
    });

    testWidgets('an armed key disarms after 10 s', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpPage(tester);

      await tester.tap(find.byKey(_hold));
      await tester.pump(const Duration(seconds: 11));

      expect(find.text('Hold to delete everything'), findsWidgets);
    });

    testWidgets('the screen reader action arms then deletes', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpPage(tester);

      tester.semantics.tap(find.semantics.byLabel('Delete everything in hisaab'));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('Double-tap again to delete everything'));
      await tester.settle();

      expect(backups.wipes, 1);
      semantics.dispose();
    });

    testWidgets('a keyboard arms with Enter and deletes with a second Enter', (WidgetTester tester) async {
      await pumpPage(tester);
      Focus.of(tester.element(find.byKey(_hold))).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.settle();

      expect(backups.wipes, 1);
    });

    group('the 5 s Undo after a full hold (AC-6a)', () {
      Future<void> holdAndLetGo(WidgetTester tester) async {
        final TestGesture finger = await press(tester);
        await tester.pump(const Duration(milliseconds: 1600));
        await finger.up();
        await tester.pump();
      }

      testWidgets('drains back over 5 s reading Undo, then deletes', (WidgetTester tester) async {
        await pumpPage(tester);

        await holdAndLetGo(tester);
        expect(find.text('Undo'), findsWidgets);
        expect(find.text('Deleting in 5 seconds. Tap Undo to stop.'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Deleting in 3 seconds. Tap Undo to stop.'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 2900));
        expect(find.text('Deleting in 1 second. Tap Undo to stop.'), findsOneWidget);
        expect(backups.wipes, 0);

        await tester.pump(const Duration(milliseconds: 200));
        await tester.settle();
        expect(backups.wipes, 1);
        expect(deleted, 1);
      });

      testWidgets('tapping Undo stops it and deletes nothing', (WidgetTester tester) async {
        await pumpPage(tester);

        await holdAndLetGo(tester);
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.byKey(_hold));
        await tester.settle();
        await tester.pump(const Duration(seconds: 5));

        expect(backups.wipes, 0);
        expect(find.text('Stopped. Nothing was deleted.'), findsOneWidget);
        expect(find.text('Hold to delete everything'), findsWidgets);
        expect(haptics.events, <String>['tick', 'threshold', 'tick']);
      });

      testWidgets('a hold after Undo needs the full 1.5 s again', (WidgetTester tester) async {
        await pumpPage(tester);

        await holdAndLetGo(tester);
        await tester.tap(find.byKey(_hold));
        await tester.settle();
        await holdFor(tester, const Duration(seconds: 1));

        expect(backups.wipes, 0);
        expect(find.text('Keep holding till it fills up.'), findsOneWidget);
      });

      testWidgets('a press that slides off during the countdown neither stops it nor restarts the fill', (WidgetTester tester) async {
        await pumpPage(tester);

        await holdAndLetGo(tester);
        final TestGesture finger = await press(tester);
        await finger.moveBy(const Offset(0, -200));
        await finger.up();
        await tester.pump();
        expect(find.text('Undo'), findsWidgets);
        await tester.settle();

        expect(backups.wipes, 1);
      });

      testWidgets('with reduced motion it still waits the full 5 s', (WidgetTester tester) async {
        await pumpPage(tester, reduceMotion: true);

        await holdAndLetGo(tester);
        await tester.pump(const Duration(seconds: 4));
        expect(backups.wipes, 0);

        await tester.pump(const Duration(seconds: 1));
        await tester.settle();
        expect(backups.wipes, 1);
      });

      testWidgets('with TalkBack the confirm starts it and a third tap undoes', (WidgetTester tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await pumpPage(tester);

        await tester.tap(find.byKey(_hold));
        await tester.pump();
        await tester.tap(find.byKey(_hold));
        await tester.pump();
        expect(find.text('Undo'), findsWidgets);
        expect(tester.takeAnnouncements().map((CapturedAccessibilityAnnouncement a) => a.message),
            contains('Deleting everything in 5 seconds. Double-tap to undo.'));

        await tester.tap(find.byKey(_hold));
        await tester.settle();
        await tester.pump(const Duration(seconds: 5));
        expect(backups.wipes, 0);
        expect(find.text('Hold to delete everything'), findsWidgets);
      });

      testWidgets('the screen reader hears Undo while it counts down', (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await pumpPage(tester);

        await holdAndLetGo(tester);

        expect(find.semantics.byLabel('Undo. Keep everything'), findsOne);
        semantics.dispose();
      });
    });

    testWidgets('Back up first backs up and stays on the page (AC-5)', (WidgetTester tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey<String>('back-up-first')));
      await tester.settle();

      expect(backups.backUps, 1);
      expect(find.text('Backed up as hisaab-backup-2026-11-06.json'), findsOneWidget);
      expect(find.text('Hold to delete everything'), findsWidgets);
    });

    testWidgets('reads Deleting while it works', (WidgetTester tester) async {
      backups.gate = Completer<void>();
      await pumpPage(tester);

      await holdFor(tester, const Duration(milliseconds: 1600));

      expect(find.text('Deleting…'), findsWidgets);
      backups.gate!.complete();
      await tester.settle();
      expect(deleted, 1);
    });

    testWidgets('a failed delete stays on the page and says nothing changed', (WidgetTester tester) async {
      backups.writeAnswer = Either<Failure, Unit>.left(DatabaseFailure('x'));
      await pumpPage(tester);

      await holdFor(tester, const Duration(milliseconds: 1600));

      expect(deleted, 0);
      expect(find.text("Couldn't delete. Nothing changed. Try again."), findsOneWidget);
      expect(haptics.events.last, 'reject');
    });

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a tablet', TestWindows.tablet, 1),
    ]) {
      testWidgets('lays out on $name', (WidgetTester tester) async {
        await pumpPage(tester, size: size, textScale: scale);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
