import 'dart:ui';

import 'package:expense_tracker/core/design/hisaab_dimensions.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_editor_bloc.dart';
import 'package:expense_tracker/settings/presentation/pages/bill_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeRecurringRepository recurring;
  late BillEditorBloc bloc;

  BillEditorBloc build({EntryKind kind = EntryKind.spent}) {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return BillEditorBloc(
      addBill: AddBill(recurring: recurring, categories: FakeCategoryRepository(), clock: clock),
      haptics: FakeHaptics(),
      kind: kind,
    );
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  /// Opens the editor on top of a blank page, so saving and back can pop it.
  Future<void> open(
    WidgetTester tester, {
    Size size = TestWindows.phone,
    double textScale = 1,
    EntryKind kind = EntryKind.spent,
  }) async {
    bloc = await tester.buildBloc(() => build(kind: kind));
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale);
    tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => BlocProvider<BillEditorBloc>.value(
          value: bloc,
          child: const BillEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final String key in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
      await tester.settle();
    }
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
    await tester.settle();
  }

  Future<void> saveOn(WidgetTester tester, int day) async {
    await tester.tap(find.byKey(ValueKey<String>('day-$day')));
    await tester.settle();
  }

  group('BillEditorPage: adding (FR-SE-1)', () {
    testWidgets('⌫ drops the last digit and a long-press clears the amount', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
      await tester.settle();
      await next(tester);
      await keys(tester, '820');
      await tester.tap(find.bySemanticsLabel('Delete last digit. Long-press to clear'));
      await tester.settle();
      expect(find.text('₹82'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Long-press to clear'));
      await tester.settle();
      expect(find.text('₹82'), findsNothing);
    });

    testWidgets('name → amount → day saves the bill and closes', (WidgetTester tester) async {
      await open(tester);
      expect(find.text("What's the bill called?"), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'Water');
      await tester.settle();
      await next(tester);
      expect(find.text('How much is Water?'), findsOneWidget);
      await keys(tester, '300');
      expect(find.text('₹300'), findsOneWidget);
      await next(tester);
      expect(find.text('Which day does Water go out?'), findsOneWidget);
      await saveOn(tester, 3);
      expect(find.byType(BillEditorPage), findsNothing);
      expect(recurring.rules.last.label, 'Water');
      expect(recurring.rules.last.categoryId, SeedCategoryIds.bills);
    });

    testWidgets('the keyboard\'s Next moves on, and tapping outside hides the keyboard', (WidgetTester tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'Water');
      await tester.settle();
      await tester.tapAt(const Offset(200, 120));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.showKeyboard(find.byKey(const ValueKey<String>('bill-name')));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.settle();
      expect(find.text('How much is Water?'), findsOneWidget);
    });

    testWidgets('a chip fills the field and is picked, closing the keyboard; Next moves on (D86)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await tester.showKeyboard(find.byKey(const ValueKey<String>('bill-name')));
      await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
      await tester.settle();
      expect(find.text("What's the bill called?"), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const ValueKey<String>('bill-name'))).controller?.text, 'Rent');
      expect(tester.getSemantics(find.byKey(const ValueKey<String>('bill-rent'))).flagsCollection.isSelected, Tristate.isTrue);
      expect(tester.testTextInput.isVisible, isFalse);
      await next(tester);
      expect(find.text('How much is Rent?'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Next stays off until there is a name, and until the amount is above ₹0', (WidgetTester tester) async {
      await open(tester);
      await next(tester);
      expect(find.text("What's the bill called?"), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'Water');
      await tester.settle();
      await next(tester);
      await next(tester);
      expect(find.text('How much is Water?'), findsOneWidget);
    });

    testWidgets('Back steps back with the name kept, then closes', (WidgetTester tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'Water');
      await tester.settle();
      await next(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.settle();
      expect(find.text('Water'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.settle();
      expect(find.byType(BillEditorPage), findsNothing);
      expect(recurring.rules, WorkedExample.rules);
    });

    testWidgets('a failed save stays on the day and says so', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-emi')));
      await tester.settle();
      await next(tester);
      await keys(tester, '5000');
      await next(tester);
      recurring.failure = DatabaseFailure('locked');
      await saveOn(tester, 7);
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.byType(BillEditorPage), findsOneWidget);
    });

    testWidgets('adding offers no Delete', (WidgetTester tester) async {
      await open(tester);
      expect(find.byKey(const ValueKey<String>('delete-bill')), findsNothing);
    });
  });

  for (final (String name, Size size, double scale) in <(String, Size, double)>[
    ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
    ('a phone in landscape', TestWindows.phoneLandscape, 1),
    ('an unfolded foldable', TestWindows.foldableUnfolded, 1),
    ('a tablet', TestWindows.tablet, 1),
  ]) {
    testWidgets('every step lays out without overflow on $name', (WidgetTester tester) async {
      await open(tester, size: size, textScale: scale);
      await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
      await tester.settle();
      await next(tester);
      expect(tester.takeException(), isNull);
      await keys(tester, '9');
      await next(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every step\'s question starts at the gutter, under the back button', (WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
    await tester.settle();
    expect(tester.getRect(find.text("What's the bill called?")).left, HisaabSpacing.gutter);
    await next(tester);
    expect(tester.getRect(find.text('How much is Rent?')).left, HisaabSpacing.gutter);
    await keys(tester, '9');
    await next(tester);
    expect(tester.getRect(find.text('Which day does Rent go out?')).left, HisaabSpacing.gutter);
  });

  group('BillEditorPage: the name pills', () {
    testWidgets('are all six while the field is empty', (WidgetTester tester) async {
      await open(tester);
      for (final String kind in <String>['rent', 'emi', 'phone', 'internet', 'schoolFees', 'subscriptions']) {
        expect(find.byKey(ValueKey<String>('bill-$kind')), findsOneWidget);
      }
    });

    testWidgets('stay all six, with that one picked, when a bill\'s full name is typed', (WidgetTester tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'rent');
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('bill-subscriptions')), findsOneWidget);
      expect(tester.getSemantics(find.byKey(const ValueKey<String>('bill-rent'))).flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('sit right under the field, not down by Next (D85)', (WidgetTester tester) async {
      await open(tester);
      final Rect field = tester.getRect(find.byKey(const ValueKey<String>('bill-name')));
      final Rect pill = tester.getRect(find.byKey(const ValueKey<String>('bill-rent')));
      expect(pill.top - field.bottom, HisaabSpacing.l);
    });

    testWidgets('start at the field\'s left edge when fewer than two are left', (WidgetTester tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'ph');
      await tester.settle();
      final Rect field = tester.getRect(find.byKey(const ValueKey<String>('bill-name')));
      expect(tester.getRect(find.byKey(const ValueKey<String>('bill-phone'))).left, field.left);
    });

    testWidgets('narrow to the ones that start with what is typed, and go when none does', (WidgetTester tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'ph');
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('bill-phone')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('bill-rent')), findsNothing);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), "Mom's rent");
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('bill-phone')), findsNothing);
      expect(find.byKey(const ValueKey<String>('bill-next')), findsOneWidget);
    });

    testWidgets('and Next fit above the open keyboard at 2× text on a small phone', (WidgetTester tester) async {
      await open(tester, size: TestWindows.smallPhone, textScale: 2);
      await tester.showKeyboard(find.byKey(const ValueKey<String>('bill-name')));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('drop a picked bill once its name is edited past it', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-emi')));
      await tester.settle();
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'EMI home');
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('bill-emi')), findsNothing);
    });

    testWidgets('come back when the typed name is cleared', (WidgetTester tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'W');
      await tester.settle();
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), '');
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('bill-rent')), findsOneWidget);
    });

    testWidgets('show again, with the pick selected, after going back from the amount', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-emi')));
      await tester.settle();
      await next(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('bill-emi')), findsOneWidget);
    });

    testWidgets('share the field\'s left and right edges in two columns', (WidgetTester tester) async {
      await open(tester);
      final Rect field = tester.getRect(find.byKey(const ValueKey<String>('bill-name')));
      final Rect first = tester.getRect(find.byKey(const ValueKey<String>('bill-rent')));
      final Rect second = tester.getRect(find.byKey(const ValueKey<String>('bill-emi')));
      expect(first.left, field.left);
      expect(second.right, field.right);
      expect(first.top, second.top);
    });

    testWidgets('stack in one column at large text, so rows never differ in height', (WidgetTester tester) async {
      await open(tester, textScale: 2);
      final Rect first = tester.getRect(find.byKey(const ValueKey<String>('bill-rent')));
      final Rect second = tester.getRect(find.byKey(const ValueKey<String>('bill-emi')));
      expect(first.left, second.left);
      expect(second.top, greaterThan(first.top));
    });

    testWidgets('and Next still fit above the open keyboard', (WidgetTester tester) async {
      await open(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final double keyboardTop = tester.view.physicalSize.height / tester.view.devicePixelRatio - 300;
      expect(tester.getRect(find.byKey(const ValueKey<String>('bill-next'))).bottom, lessThanOrEqualTo(keyboardTop));
    });
  });

  testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await open(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  group('BillEditorPage: adding a saving (D120)', () {
    testWidgets('the saving questions say goes in', (WidgetTester tester) async {
      await open(tester, kind: EntryKind.saved);
      expect(find.text('What do you save in?'), findsOneWidget);
      for (final String pill in <String>['rd', 'sip', 'goldScheme', 'chit']) {
        expect(find.byKey(ValueKey<String>('saving-$pill')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey<String>('bill-rent')), findsNothing);
      await tester.tap(find.byKey(const ValueKey<String>('saving-rd')));
      await tester.settle();
      await next(tester);
      expect(find.text('How much goes into RD?'), findsOneWidget);
      await keys(tester, '5000');
      await next(tester);
      expect(find.text('Which day does RD go in?'), findsOneWidget);
    });
  });
}
