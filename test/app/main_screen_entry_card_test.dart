import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/widgets/add_key.dart';
import 'package:hisaab/app/widgets/hisaab_dock.dart';
import 'package:hisaab/core/widgets/keypad.dart';
import 'package:hisaab/home/presentation/widgets/hero_card.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

void main() {
  late FakeServices services;

  setUp(() => services = FakeServices());
  tearDown(() => services.dispose());

  Future<void> boot(
    WidgetTester tester, {
    Size size = TestWindows.phone,
    List<DisplayFeature> features = const <DisplayFeature>[],
    bool reduceMotion = false,
  }) async {
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..displayFeatures = features;
    addTearDown(tester.view.reset);
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  Future<void> tapAndLoad(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  Finder key(String name) => find.byKey(ValueKey<String>(name));
  Finder keypadKey(String label) => find.descendant(of: find.byType(Keypad), matching: find.text(label)).first;

  group('MainScreen with the entry card (FR-AD-8 AC-11, AC-12)', () {
    testWidgets('phone: the dock steps aside and the hero tucks in with a preview; Done brings both back', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, find.text('Chai & samosa'));
      expect(key('entry-card-4'), findsOneWidget);
      expect(find.byType(HisaabDock), findsNothing);
      expect(key('hero-held'), findsOneWidget);
      expect(find.text("updates when you're done"), findsOneWidget);

      await tapAndLoad(tester, key('entry-card-amount'));
      await tapAndLoad(tester, keypadKey('1'));
      await tapAndLoad(tester, keypadKey('6'));
      await tapAndLoad(tester, keypadKey('0'));
      // why: the keypad scrolled the list; the tucked hero is at its top.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.text('after Done'), findsOneWidget);

      await tapAndLoad(tester, key('entry-card-done'));
      expect(find.byType(HisaabDock), findsOneWidget);
      expect(find.byType(HeroCard), findsOneWidget);
      expect(find.text('Changed to ₹160'), findsOneWidget);
    });

    testWidgets('phone: Delete in the card deletes with Home\'s Undo', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, find.text('Chai & samosa'));
      await tapAndLoad(tester, key('entry-card-delete'));
      expect(find.text('Chai & samosa'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('tablet: the board takes the Spends pane and the Add key steps aside', (WidgetTester tester) async {
      await boot(tester, size: TestWindows.tablet);
      expect(find.byType(AddKey), findsOneWidget);
      await tapAndLoad(tester, find.text('Chai & samosa'));
      expect(find.text('Change anything'), findsOneWidget);
      expect(find.byType(AddKey), findsNothing);
      expect(find.byType(SpendsPage, skipOffstage: true), findsNothing);
      await tapAndLoad(tester, key('entry-card-done'));
      expect(find.text('Change anything'), findsNothing);
      expect(find.byType(SpendsPage), findsOneWidget);
    });

    testWidgets('tabletop: the board sits below the fold in the dock\'s place', (WidgetTester tester) async {
      await boot(
        tester,
        size: TestWindows.tabletop,
        features: <DisplayFeature>[TestWindows.tabletopFold],
      );
      // why: Home is only the 420dp above the fold, so the lazy list builds Today on the way down.
      await tester.scrollUntilVisible(find.text('Chai & samosa'), 200, scrollable: find.byType(Scrollable).first);
      await tapAndLoad(tester, find.text('Chai & samosa'));
      expect(find.text('Change anything'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Change anything')).dy, greaterThanOrEqualTo(TestWindows.tabletopFold.bounds.bottom));
      expect(find.byType(HisaabDock), findsNothing);
    });

    testWidgets('reduced motion: the dock jumps aside and back', (WidgetTester tester) async {
      await boot(tester, reduceMotion: true);
      await tapAndLoad(tester, find.text('Chai & samosa'));
      expect(find.byType(HisaabDock), findsNothing);
      await tapAndLoad(tester, key('entry-card-done'));
      expect(find.byType(HisaabDock), findsOneWidget);
    });

    testWidgets('Every entry: a card\'s Delete uses the page\'s Undo', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, key('see-all'));
      await tapAndLoad(tester, find.text('Chai & samosa'));
      await tapAndLoad(tester, key('entry-card-delete'));
      expect(find.text('Chai & samosa'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('Every entry, wide: the board sits beside the list while a card is open', (WidgetTester tester) async {
      await boot(tester, size: TestWindows.tablet);
      await tapAndLoad(tester, key('see-all'));
      expect(find.byType(EntriesPage), findsOneWidget);
      await tapAndLoad(tester, find.text('Chai & samosa').last);
      expect(find.text('Change anything'), findsOneWidget);
      await tapAndLoad(tester, key('entry-card-done'));
      expect(find.text('Change anything'), findsNothing);
    });
  });
}
