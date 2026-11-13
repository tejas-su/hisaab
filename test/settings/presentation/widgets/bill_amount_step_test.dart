import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_editor_bloc.dart';
import 'package:hisaab/settings/presentation/pages/bill_editor_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeRecurringRepository recurring;
  late BillEditorBloc bloc;

  setUp(() => recurring = FakeRecurringRepository(WorkedExample.rules));

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  Future<void> open(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1}) async {
    bloc = await tester.buildBloc(
      () => BillEditorBloc(
        addBill: AddBill(recurring: recurring, categories: FakeCategoryRepository(), clock: FakeClock(WorkedExample.now)),
        haptics: FakeHaptics(),
        kind: EntryKind.saved,
      ),
    );
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale);
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute<void>(
            builder: (BuildContext _) => BlocProvider<BillEditorBloc>.value(value: bloc, child: const BillEditorPage()),
          ),
        );
    await tester.pumpAndSettle();
  }

  Future<void> pickAndNext(WidgetTester tester, String pillKey) async {
    await tester.ensureVisible(find.byKey(ValueKey<String>(pillKey)));
    await tester.tap(find.byKey(ValueKey<String>(pillKey)));
    await tester.settle();
    await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
    await tester.settle();
  }

  Future<void> typeAndNext(WidgetTester tester, String name) async {
    await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), name);
    await tester.settle();
    await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
    await tester.settle();
  }

  final Finder caption = find.byKey(const ValueKey<String>('saving-yearly-caption'));
  final Finder usedHint = find.byKey(const ValueKey<String>('saving-yearly-used-hint'));

  group('BillAmountStep yearly caption (AC-Y2)', () {
    for (final String pill in <String>['insurance', 'schoolFees', 'festival']) {
      testWidgets('the amount question shows the two sentences after the $pill pill', (WidgetTester tester) async {
        await open(tester);

        await pickAndNext(tester, 'saving-$pill');

        expect(tester.widget<Text>(caption).data, 'Paid once a year? Each month, put in the cost divided by 12.');
        expect(tester.widget<Text>(usedHint).data, 'When you pay it, tap Used some of it.');
      });
    }

    for (final String pill in <String>['rd', 'sip', 'goldScheme', 'chit']) {
      testWidgets('the $pill pill shows no caption', (WidgetTester tester) async {
        await open(tester);

        await pickAndNext(tester, 'saving-$pill');

        expect(caption, findsNothing);
        expect(usedHint, findsNothing);
      });
    }

    testWidgets('a hand-typed "Insurance" does not show it; a pill does', (WidgetTester tester) async {
      await open(tester);

      await typeAndNext(tester, 'Insurance');

      expect(caption, findsNothing);
    });

    testWidgets('a pill then a retyped name does not show it', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('saving-insurance')));
      await tester.settle();

      await typeAndNext(tester, 'Insurance 2');

      expect(caption, findsNothing);
    });

    testWidgets('no yearly-amount field, no divide key, no due date, no reminder is offered', (WidgetTester tester) async {
      await open(tester);

      await pickAndNext(tester, 'saving-insurance');

      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('÷'), findsNothing);
      expect(find.textContaining('reminder', findRichText: true), findsNothing);
      expect(find.textContaining(RegExp('due', caseSensitive: false)), findsNothing);
    });

    testWidgets('the tap path is unchanged: name, Next, digits, Next, day', (WidgetTester tester) async {
      await open(tester);
      await pickAndNext(tester, 'saving-insurance');

      for (final String key in '12000'.split('')) {
        await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
        await tester.settle();
      }
      await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
      await tester.settle();

      expect(find.text('Which day of the month for Insurance?'), findsOneWidget);
    });

    testWidgets('the body scrolls above the pinned keypad at 320x568 and 2.0x text', (WidgetTester tester) async {
      await open(tester, size: TestWindows.smallPhone, textScale: 2);

      await pickAndNext(tester, 'saving-insurance');

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(usedHint, 50, scrollable: find.byType(Scrollable).first);
      expect(usedHint, findsOneWidget);
      expect(tester.getRect(find.byKey(const ValueKey<String>('bill-next'))).bottom, lessThanOrEqualTo(TestWindows.smallPhone.height));
    });
  });
}
