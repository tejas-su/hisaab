import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_editor_bloc.dart';
import 'package:expense_tracker/settings/presentation/pages/bill_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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
  late int deletes;

  BillEditorBloc build(Option<RecurringRule> editing) {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return BillEditorBloc(
      addBill: AddBill(recurring: recurring, categories: FakeCategoryRepository(), clock: clock),
      editBill: EditBill(recurring: recurring, clock: clock),
      haptics: FakeHaptics(),
      editing: editing,
    );
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    deletes = 0;
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  /// Opens the editor on top of a blank page, so saving and back can pop it.
  Future<void> open(
    WidgetTester tester, {
    Option<RecurringRule> editing = const Option<RecurringRule>.none(),
    Size size = TestWindows.phone,
    double textScale = 1,
  }) async {
    bloc = await tester.buildBloc(() => build(editing));
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale);
    tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => BlocProvider<BillEditorBloc>.value(
          value: bloc,
          child: BillEditorPage(onDelete: editing.isSome() ? () => deletes++ : null),
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

    testWidgets('a chip names the bill and moves straight to the amount', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
      await tester.settle();
      expect(find.text('How much is Rent?'), findsOneWidget);
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

  group('BillEditorPage: changing a bill', () {
    testWidgets('starts with the name filled in and offers Delete', (WidgetTester tester) async {
      await open(tester, editing: Option<RecurringRule>.of(WorkedExample.electricity));
      expect(find.widgetWithText(TextField, 'Electricity'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('delete-bill')));
      expect(deletes, 1);
    });

    testWidgets('keeps the amount', (WidgetTester tester) async {
      await open(tester, editing: Option<RecurringRule>.of(WorkedExample.electricity));
      await next(tester);
      expect(find.text('₹1,200'), findsOneWidget);
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
      expect(tester.takeException(), isNull);
      await keys(tester, '9');
      await next(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await open(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
