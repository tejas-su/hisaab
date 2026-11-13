import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/widgets/hisaab_chip.dart';
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

  Future<void> open(WidgetTester tester, {EntryKind kind = EntryKind.saved, Size size = TestWindows.phone, double textScale = 1}) async {
    bloc = await tester.buildBloc(
      () => BillEditorBloc(
        addBill: AddBill(recurring: recurring, categories: FakeCategoryRepository(), clock: FakeClock(WorkedExample.now)),
        haptics: FakeHaptics(),
        kind: kind,
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

  List<String> pillLabels(WidgetTester tester) =>
      tester.widgetList<HisaabChip>(find.byType(HisaabChip)).map((HisaabChip chip) => chip.label).toList();

  group('BillNameStep saving pills (AC-Y1)', () {
    testWidgets('are RD, SIP, Gold scheme, Chit in that order, then Insurance, School fees, Festival', (WidgetTester tester) async {
      await open(tester);

      expect(pillLabels(tester), <String>['RD', 'SIP', 'Gold scheme', 'Chit', 'Insurance', 'School fees', 'Festival']);
    });

    testWidgets('keep the first four in place at large text, where one column is used', (WidgetTester tester) async {
      await open(tester, textScale: 1.5);

      expect(pillLabels(tester).take(4), <String>['RD', 'SIP', 'Gold scheme', 'Chit']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a spent bill keeps its own pills and none of the savings', (WidgetTester tester) async {
      await open(tester, kind: EntryKind.spent);

      expect(find.byKey(const ValueKey<String>('bill-rent')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('saving-insurance')), findsNothing);
    });

    testWidgets('typing a letter narrows the pills to the ones it could become', (WidgetTester tester) async {
      await open(tester);

      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'S');
      await tester.settle();

      expect(pillLabels(tester), <String>['SIP', 'School fees']);
    });

    testWidgets('tapping Insurance fills the name and Next moves on to the amount', (WidgetTester tester) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey<String>('saving-insurance')));
      await tester.settle();
      expect(tester.widget<TextField>(find.byKey(const ValueKey<String>('bill-name'))).controller?.text, 'Insurance');

      await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
      await tester.settle();
      expect(find.text('How much do you put in Insurance each month?'), findsOneWidget);
    });
  });
}
