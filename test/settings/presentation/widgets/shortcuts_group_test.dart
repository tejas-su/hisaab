import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/settings/presentation/bloc/shortcut_rows_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/shortcut_rows_event.dart';
import 'package:hisaab/settings/presentation/widgets/shortcuts_group.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_shortcuts_platform.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeShortcutsPlatform platform;

  setUp(() => platform = FakeShortcutsPlatform());
  tearDown(() => platform.dispose());

  Future<ShortcutRowsBloc> show(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1}) async {
    final ShortcutRowsBloc bloc = await tester.buildBloc(() => ShortcutRowsBloc(platform: platform)..add(const ShortcutRowsLoadRequested()));
    addTearDown(() => tester.runAsync(bloc.close));
    await pumpApp(
      tester,
      Scaffold(body: ListView(children: <Widget>[BlocProvider<ShortcutRowsBloc>.value(value: bloc, child: const ShortcutsGroup())])),
      size: size,
      textScale: textScale,
    );
    await tester.settle();
    return bloc;
  }

  group('ShortcutsGroup (FR-SE-6, mockup 38 §6)', () {
    testWidgets('shows the heading and both rows with their hints', (WidgetTester tester) async {
      await show(tester);

      expect(find.text('Shortcuts'), findsOneWidget);
      expect(find.text('Add a widget'), findsOneWidget);
      expect(find.text("See what's safe to spend from your home screen"), findsOneWidget);
      expect(find.text('Add to quick settings'), findsOneWidget);
      expect(find.text('Add a spend from the pull-down'), findsOneWidget);
    });

    testWidgets('tapping a row asks Android', (WidgetTester tester) async {
      await show(tester);

      await tester.tap(find.byKey(const ValueKey<String>('add-widget')));
      await tester.settle();
      await tester.tap(find.byKey(const ValueKey<String>('add-tile')));
      await tester.settle();

      expect((platform.widgetPins, platform.tileAdds), (1, 1));
    });

    testWidgets('a launcher that cannot pin hides that row only (AC-1, E57)', (WidgetTester tester) async {
      platform.pinWidgetSupported = false;
      await show(tester);

      expect(find.byKey(const ValueKey<String>('add-widget')), findsNothing);
      expect(find.byKey(const ValueKey<String>('add-tile')), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('below Android 13 the tile row is hidden (AC-2, E57)', (WidgetTester tester) async {
      platform.tileSupported = false;
      await show(tester);

      expect(find.byKey(const ValueKey<String>('add-widget')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('add-tile')), findsNothing);
    });

    testWidgets('with neither, the whole group is hidden, heading too (AC-3)', (WidgetTester tester) async {
      platform
        ..pinWidgetSupported = false
        ..tileSupported = false;
      await show(tester);

      expect(find.text('Shortcuts'), findsNothing);
    });

    testWidgets('the heading is a heading for TalkBack and the rows meet the guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await show(tester);

      expect(tester.getSemantics(find.text('Shortcuts')), matchesSemantics(label: 'Shortcuts', isHeader: true));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final Size size in <Size>[TestWindows.smallPhone, TestWindows.phoneLandscape, TestWindows.foldableUnfolded, TestWindows.tablet]) {
      testWidgets('lays out without overflow at $size', (WidgetTester tester) async {
        await show(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('add-tile')), findsOneWidget);
      });
    }

    testWidgets('holds at 2× text', (WidgetTester tester) async {
      await show(tester, size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
