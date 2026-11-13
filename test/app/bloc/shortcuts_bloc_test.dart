import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisaab/app/bloc/shortcuts_bloc.dart';
import 'package:hisaab/app/bloc/shortcuts_event.dart';
import 'package:hisaab/app/bloc/shortcuts_state.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money_formatter.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

import '../../helpers/bloc_dispatch.dart';
import '../../helpers/fake_services.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));
  late FakeServices services;
  late ShortcutsBloc bloc;

  ShortcutsBloc build() => ShortcutsBloc(
        project: services.projectWidgetDays,
        preferences: services.preferences,
        platform: services.shortcuts,
        clock: services.clock,
        words: (strings: lookupAppLocalizations(const Locale('en')), money: MoneyFormatter()),
        ledger: services.ledger,
        recurring: services.recurring,
      );

  setUp(() {
    services = FakeServices();
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await services.shortcuts.dispose();
    await services.ledger.dispose();
  });

  group('ShortcutsBloc', () {
    test('starts idle and publishes nothing by itself', () async {
      expect(bloc.state, const ShortcutsIdle());
      await pumpEventQueue();
      expect(services.shortcuts.published, isEmpty);
    });

    test('a publish writes the projected days in the saved look (FR-WG-5)', () async {
      await services.preferences.saveThemeChoice(ThemeChoice.dark).run();

      await bloc.dispatch(const ShortcutsPublishRequested());

      final WidgetSnapshot snapshot = services.shortcuts.published.single;
      expect(snapshot.look, ThemeChoice.dark);
      expect(snapshot.writtenAt, WorkedExample.now);
      expect(snapshot.rows.first.hero, '₹1,430');
    });

    test('every ledger write publishes again', () async {
      await services.ledger.add(WorkedExample.entries.last.draft).run();
      await pumpEventQueue();

      expect(services.shortcuts.published, hasLength(1));
      expect(services.shortcuts.published.single.rows.first.hero, '₹1,190');
    });

    test('every rule change publishes again', () async {
      await services.recurring.setActive(WorkedExample.rent.id, active: false).run();
      await pumpEventQueue();

      expect(services.shortcuts.published, hasLength(1));
    });

    test('a failed read publishes nothing and logs', () async {
      services.ledger.failure = DatabaseFailure('locked');

      await bloc.dispatch(const ShortcutsPublishRequested());

      expect(services.shortcuts.published, isEmpty);
    });

    test('publishes one at a time, in order, so the newest is written last (sequential)', () async {
      final Completer<void> gate = Completer<void>();
      services.shortcuts.nextPublishGate = gate;
      bloc.add(const ShortcutsPublishRequested());
      await pumpEventQueue();
      await services.ledger.add(WorkedExample.entries.last.draft).run();
      await pumpEventQueue();

      expect(services.shortcuts.published, isEmpty);
      gate.complete();
      await pumpEventQueue();

      expect(services.shortcuts.published.map((WidgetSnapshot s) => s.rows.first.hero), <String>['₹1,430', '₹1,190']);
    });

    test('holds the tap that started the app (widget spec §8)', () async {
      services.shortcuts.launchedBy = const Option<LaunchAction>.of(LaunchAction.add);
      final Future<void> expectation = expectLater(bloc.stream, emits(const ShortcutsLaunchPending(LaunchAction.add)));

      await bloc.dispatch(const ShortcutsStarted());

      await expectation;
    });

    test('a start with no tap stays idle', () async {
      await bloc.dispatch(const ShortcutsStarted());

      expect(bloc.state, const ShortcutsIdle());
    });

    test('holds a tap while running until it is handled', () async {
      services.shortcuts.tap(LaunchAction.home);
      await pumpEventQueue();
      expect(bloc.state, const ShortcutsLaunchPending(LaunchAction.home));

      await bloc.dispatch(const ShortcutsLaunchHandled());

      expect(bloc.state, const ShortcutsIdle());
    });

    test('events and states compare by value', () {
      expect(const ShortcutsPublishRequested(), const ShortcutsPublishRequested());
      expect(const ShortcutsLaunched(LaunchAction.add), isNot(const ShortcutsLaunched(LaunchAction.home)));
      expect(const ShortcutsIdle(), const ShortcutsIdle());
      expect(const ShortcutsLaunchPending(LaunchAction.add), isNot(const ShortcutsLaunchPending(LaunchAction.setUp)));
      expect(const ShortcutsStarted().props, isEmpty);
      expect(const ShortcutsIdle().props, isEmpty);
    });

    test('closing mid-publish completes', () async {
      bloc.add(const ShortcutsPublishRequested());
      await expectLater(bloc.close(), completes);
    });
  });
}
