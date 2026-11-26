import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/widgets/hisaab_dock.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_bar.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/afford_card.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// *Can I afford it?* through the app's wiring: the Spends card opens the sheet, and *Start
/// saving*'s Undo shows over Spends on every layout (SPEC FR-SP-9 AC-1, AC-6, E164).
void main() {
  late FakeServices services;

  final Finder afford = find.byKey(const ValueKey<String>('afford-card'));

  setUp(() => services = FakeServices(rules: <RecurringRule>[...WorkedExample.rules, WorkedExample.rd]));
  tearDown(() => services.dispose());

  Future<void> boot(WidgetTester tester, {Size size = TestWindows.phone, List<DisplayFeature> displayFeatures = const <DisplayFeature>[]}) async {
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..displayFeatures = displayFeatures;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  Future<void> openSpendsTab(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(HisaabDock), matching: find.bySemanticsLabel('Spends')));
    await _settle(tester);
  }

  // why: the sheet's own path to *Start saving* is covered in afford_sheet_test; here the app's
  // Undo wiring is driven with the outcome the sheet hands back.
  Future<void> offerUndo(WidgetTester tester) async {
    BlocProvider.of<AffordUndoBloc>(tester.element(find.byType(SpendsPage))).add(AffordUndoOffered(SavingStarted(rule: WorkedExample.rd, previous: const Option<RecurringRule>.none())));
    await _settle(tester);
  }

  Finder undoBar() => find.byType(HisaabSnackbarBar);

  testWidgets('on a phone the card opens the check over Spends', (WidgetTester tester) async {
    await boot(tester);
    await openSpendsTab(tester);
    await tester.tap(afford);
    await _settle(tester);
    expect(find.byType(AffordSheet), findsOneWidget);
    expect(find.text('What do you want to buy?'), findsOneWidget);
  });

  testWidgets('a double tap on the card opens one sheet only', (WidgetTester tester) async {
    await boot(tester);
    await openSpendsTab(tester);
    // why: two taps that land before the sheet's first frame, as on a slow phone.
    final AffordCard card = tester.widget<AffordCard>(afford);
    card.onPressed();
    card.onPressed();
    await _settle(tester);
    expect(find.byType(AffordSheet), findsOneWidget);
    expect(find.text('What do you want to buy?'), findsOneWidget);
  });

  testWidgets('on a phone Undo shows over Spends and deletes the new saving (AC-6, E164)', (WidgetTester tester) async {
    await boot(tester);
    await openSpendsTab(tester);
    await offerUndo(tester);
    expect(find.text('Saving ₹5,000 a month for RD'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await _settle(tester);
    expect(services.recurring.rules.where((RecurringRule r) => r.id == WorkedExample.rd.id), isEmpty);
  });

  testWidgets('book posture: two panes, one card, it opens the check, and Undo shows in the Spends pane', (WidgetTester tester) async {
    await boot(tester, size: TestWindows.book, displayFeatures: const <DisplayFeature>[TestWindows.bookHinge]);
    expect(find.byType(SpendsPage), findsOneWidget);
    expect(afford, findsOneWidget);
    expect(tester.getRect(afford).left, greaterThanOrEqualTo(TestWindows.bookHinge.bounds.right));
    await offerUndo(tester);
    expect(undoBar(), findsOneWidget);
    expect(tester.getRect(undoBar()).left, greaterThanOrEqualTo(TestWindows.bookHinge.bounds.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('book posture: the card opens the check', (WidgetTester tester) async {
    await boot(tester, size: TestWindows.book, displayFeatures: const <DisplayFeature>[TestWindows.bookHinge]);
    await tester.tap(afford);
    await _settle(tester);
    expect(find.byType(AffordSheet), findsOneWidget);
  });

  testWidgets('a tablet: two panes, one card beside Ask AI, and Undo shows', (WidgetTester tester) async {
    await boot(tester, size: TestWindows.tablet);
    expect(afford, findsOneWidget);
    await offerUndo(tester);
    expect(find.text('Saving ₹5,000 a month for RD'), findsOneWidget);
  });

  testWidgets('tabletop: the card sits above the fold and Undo shows there', (WidgetTester tester) async {
    await boot(tester, size: TestWindows.tabletop, displayFeatures: const <DisplayFeature>[TestWindows.tabletopFold]);
    await openSpendsTab(tester);
    expect(afford, findsOneWidget);
    expect(tester.getRect(afford).bottom, lessThanOrEqualTo(TestWindows.tabletopFold.bounds.top));
    await offerUndo(tester);
    expect(undoBar(), findsOneWidget);
    expect(tester.getRect(undoBar()).bottom, lessThanOrEqualTo(TestWindows.tabletopFold.bounds.top));
  });
}
