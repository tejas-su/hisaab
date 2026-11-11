import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/design/hisaab_dimensions.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_bar.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_host.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const String _deleted = 'Deleted ₹250';
const String _toast = 'Copied. In the chat, long-press and tap Paste.';

/// Pumps a page whose body is a host [bottom] dp above its edge, and returns the host.
Future<HisaabSnackbarHostState> _pumpHost(
  WidgetTester tester, {
  double bottom = HisaabSpacing.xl,
  bool reduceMotion = false,
  double textScale = 1,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: HisaabSnackbarHost(
        bottom: bottom,
        child: Builder(builder: (BuildContext context) => const SizedBox.expand()),
      ),
    ),
    reduceMotion: reduceMotion,
    textScale: textScale,
  );
  return HisaabSnackbarHost.of(tester.element(find.byType(SizedBox).last));
}

HisaabSnackbar _undo(List<String> taps) => HisaabSnackbar(
      message: _deleted,
      semanticsLabel: 'Deleted 250 rupees',
      action: HisaabSnackbarAction(label: 'Undo', onPressed: () => taps.add('undo')),
    );

Future<void> _show(WidgetTester tester, HisaabSnackbarHostState host, HisaabSnackbar snackbar) async {
  host.show(snackbar);
  await tester.pumpAndSettle();
}

void _useTalkBack(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  group('HisaabSnackbarHost', () {
    test('a bar stays a medium 4 s, not a long 6 s (SPEC BR-10)', () {
      expect(HisaabSnackbarHost.visibleFor, const Duration(seconds: 4));
    });

    testWidgets('a bar with Undo closes itself after 4 s (regression: it stayed forever)', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      await tester.pump(HisaabSnackbarHost.visibleFor - const Duration(milliseconds: 1));
      expect(find.text(_deleted), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(find.text(_deleted), findsNothing);
    });

    testWidgets('a plain message closes itself after 4 s', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, const HisaabSnackbar(message: _toast));

      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.pumpAndSettle();

      expect(find.text(_toast), findsNothing);
    });

    testWidgets('Undo runs once, even tapped twice, and closes the bar', (WidgetTester tester) async {
      final List<String> taps = <String>[];
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(taps));

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(taps, <String>['undo']);
      expect(find.text(_deleted), findsNothing);
    });

    testWidgets('with TalkBack, a bar with Undo stays until dismissed', (WidgetTester tester) async {
      _useTalkBack(tester);
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      await tester.pump(HisaabSnackbarHost.visibleFor * 3);
      await tester.pumpAndSettle();

      expect(find.text(_deleted), findsOneWidget);
    });

    testWidgets('with TalkBack, a plain message still closes after 4 s', (WidgetTester tester) async {
      _useTalkBack(tester);
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, const HisaabSnackbar(message: _toast));

      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.pumpAndSettle();

      expect(find.text(_toast), findsNothing);
    });

    testWidgets('a newer message replaces the current one and gets its own 4 s', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));
      await tester.pump(const Duration(seconds: 4));

      await _show(tester, host, const HisaabSnackbar(message: _toast));
      await tester.pump(const Duration(seconds: 4));

      expect(find.text(_deleted), findsNothing);
      expect(find.text(_toast), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(_toast), findsNothing);
    });

    testWidgets('swiping it down dismisses it', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      await tester.fling(find.text(_deleted), const Offset(0, 200), 1000);
      await tester.pumpAndSettle();

      expect(find.text(_deleted), findsNothing);
    });

    testWidgets('a finger on it holds the timer; lifting starts a fresh 4 s', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      final TestGesture finger = await tester.startGesture(tester.getCenter(find.text(_deleted)));
      await tester.pump(HisaabSnackbarHost.visibleFor * 2);
      expect(find.text(_deleted), findsOneWidget);
      await finger.up();
      await tester.pump(HisaabSnackbarHost.visibleFor - const Duration(seconds: 1));
      expect(find.text(_deleted), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text(_deleted), findsNothing);
    });

    testWidgets('a cancelled touch also starts a fresh 4 s', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      final TestGesture finger = await tester.startGesture(tester.getCenter(find.text(_deleted)));
      await tester.pump(HisaabSnackbarHost.visibleFor);
      await finger.cancel();
      await tester.pump(HisaabSnackbarHost.visibleFor - const Duration(seconds: 1));
      expect(find.text(_deleted), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text(_deleted), findsNothing);
    });

    testWidgets('keyboard focus on Undo holds the timer until focus leaves', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(HisaabSnackbarHost.visibleFor * 2);
      expect(find.text(_deleted), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.pumpAndSettle();

      expect(find.text(_deleted), findsNothing);
    });

    testWidgets('hide() closes the bar early, and does nothing when none shows', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      host.hide();
      await tester.pumpAndSettle();
      await _show(tester, host, _undo(<String>[]));

      host.hide();
      await tester.pumpAndSettle();

      expect(find.byType(HisaabSnackbarBar), findsNothing);
    });

    testWidgets('rises 16 dp into place, and only fades with reduced motion', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      host.show(_undo(<String>[]));
      await tester.pump();
      final double start = tester.getTopLeft(find.byType(HisaabSnackbarBar)).dy;
      await tester.pumpAndSettle();
      expect(start - tester.getTopLeft(find.byType(HisaabSnackbarBar)).dy, closeTo(HisaabSnackbarHost.rise, 0.5));

      final HisaabSnackbarHostState reduced = await _pumpHost(tester, reduceMotion: true);
      reduced.show(_undo(<String>[]));
      await tester.pump();
      final double reducedStart = tester.getTopLeft(find.byType(HisaabSnackbarBar)).dy;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(HisaabSnackbarBar)).dy, reducedStart);
      reduced.hide();
      await tester.pumpAndSettle();
      expect(find.byType(HisaabSnackbarBar), findsNothing);
    });

    testWidgets('shares the gutter edges and sits [bottom] dp above the host edge', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester, bottom: 0);
      await _show(tester, host, _undo(<String>[]));

      final Rect bar = tester.getRect(find.byType(HisaabSnackbarBar));
      expect(bar.left, HisaabSpacing.gutter);
      expect(bar.right, TestWindows.phone.width - HisaabSpacing.gutter);
      expect(bar.bottom, TestWindows.phone.height);
    });

    testWidgets('is an inverse pill with the page colour for its words', (WidgetTester tester) async {
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      final Container pill = tester.widget<Container>(
        find.descendant(of: find.byType(HisaabSnackbarBar), matching: find.byType(Container)).first,
      );
      expect((pill.decoration! as ShapeDecoration).color, HisaabColors.light.inverse);
      expect(tester.widget<Text>(find.text(_deleted)).style?.color, HisaabColors.light.background);
      expect(tester.widget<Text>(find.text('Undo')).style?.color, HisaabColors.light.background);
    });

    testWidgets('announces as a live region with a spoken amount and a Dismiss action', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final HisaabSnackbarHostState host = await _pumpHost(tester);
      await _show(tester, host, _undo(<String>[]));

      expect(find.semantics.byFlag(SemanticsFlag.isLiveRegion), findsOne);
      expect(find.semantics.byLabel('Deleted 250 rupees'), findsOne);
      tester.semantics.performAction(find.semantics.byAction(SemanticsAction.dismiss), SemanticsAction.dismiss);
      await tester.pumpAndSettle();

      expect(find.byType(HisaabSnackbarBar), findsNothing);
      handle.dispose();
    });

    testWidgets('meets tap-target, label and contrast guidelines at 2x text', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final HisaabSnackbarHostState host = await _pumpHost(tester, textScale: 2);
      await _show(tester, host, _undo(<String>[]));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
