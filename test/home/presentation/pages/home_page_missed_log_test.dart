import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/due_soon_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late HomeBloc bloc;

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester, {required List<RecurringRule> rules}) async {
    services = FakeServices(rules: rules);
    bloc = await tester.buildBloc(services.homeBloc);
    await tester.runAsync(() => bloc.dispatch(const HomeLoadRequested()));
    await pumpApp(
      tester,
      BlocProvider<HomeBloc>.value(
        value: bloc,
        child: Scaffold(
          body: HomePage(
            onAdd: (EntryKind _) {},
            onEdit: (Entry _) {},
            onOpenSettings: () {},
            onOpenBill: (RecurringRule _) {},
            onEnterBill: (Occurrence _) {},
            missedLogSlot: (BuildContext _) => const Text('missed-log slot'),
          ),
        ),
      ),
    );
  }

  group('HomePage nudge slot, the missed-log line last (FR-HO-3)', () {
    testWidgets('with no bill line the slot is the missed-log line', (WidgetTester tester) async {
      await pump(tester, rules: <RecurringRule>[WorkedExample.salary]);

      expect(find.text('missed-log slot'), findsOneWidget);
    });

    testWidgets('a due-soon bill holds the slot: the missed-log line is not built', (WidgetTester tester) async {
      await pump(tester, rules: WorkedExample.rules);

      expect(find.byType(DueSoonRow), findsOneWidget);
      expect(find.text('missed-log slot'), findsNothing);
    });
  });
}
