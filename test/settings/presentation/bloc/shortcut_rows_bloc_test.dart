import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/settings/presentation/bloc/shortcut_rows_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/shortcut_rows_event.dart';
import 'package:hisaab/settings/presentation/bloc/shortcut_rows_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_shortcuts_platform.dart';

void main() {
  late FakeShortcutsPlatform platform;
  late ShortcutRowsBloc bloc;

  setUp(() {
    platform = FakeShortcutsPlatform();
    bloc = ShortcutRowsBloc(platform: platform);
  });

  tearDown(() async {
    await bloc.close();
    await platform.dispose();
  });

  group('ShortcutRowsBloc (FR-SE-6)', () {
    test('starts loading', () => expect(bloc.state, const ShortcutRowsLoading()));

    const List<(bool, bool)> phones = <(bool, bool)>[(true, true), (true, false), (false, true), (false, false)];
    for (final (bool widget, bool tile) in phones) {
      test('a phone that can add the widget: $widget, the tile: $tile shows those rows', () async {
        platform
          ..pinWidgetSupported = widget
          ..tileSupported = tile;

        await bloc.dispatch(const ShortcutRowsLoadRequested());

        expect(bloc.state, ShortcutRowsReady(canAddWidget: widget, canAddTile: tile));
        expect((bloc.state as ShortcutRowsReady).any, widget || tile);
      });
    }

    test('events and states compare by value', () {
      expect(const ShortcutRowsLoadRequested(), const ShortcutRowsLoadRequested());
      expect(const ShortcutRowsWidgetTapped(), isNot(const ShortcutRowsTileTapped()));
      expect(const ShortcutRowsLoading(), const ShortcutRowsLoading());
      expect(const ShortcutRowsReady(canAddWidget: true, canAddTile: false), isNot(const ShortcutRowsReady(canAddWidget: true, canAddTile: true)));
      expect(const ShortcutRowsLoadRequested().props, isEmpty);
      expect(const ShortcutRowsLoading().props, isEmpty);
    });

    test('Add a widget asks Android once', () async {
      await bloc.dispatch(const ShortcutRowsWidgetTapped());
      expect(platform.widgetPins, 1);
    });

    test('Add to quick settings asks Android once', () async {
      await bloc.dispatch(const ShortcutRowsTileTapped());
      expect(platform.tileAdds, 1);
    });

    test('a second tap while Android is being asked is dropped (droppable)', () async {
      final Completer<void> gate = Completer<void>();
      platform.askGate = gate;

      bloc
        ..add(const ShortcutRowsWidgetTapped())
        ..add(const ShortcutRowsTileTapped());
      await pumpEventQueue();
      bloc
        ..add(const ShortcutRowsWidgetTapped())
        ..add(const ShortcutRowsTileTapped());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect((platform.widgetPins, platform.tileAdds), (1, 1));
    });
  });
}
