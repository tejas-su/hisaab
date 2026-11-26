import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/settings/presentation/widgets/bill_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const String _nbsp = ' ';

/// One row of the BR-23 display table: the saving's target and set-aside, and the line drawn and read.
typedef _Form = ({String name, int target, int setAside, String shown, String spoken});

/// The Savings list row's third line with a target (SPEC BR-23 display states, FR-SE-1 AC-T5, AC-T7,
/// AC-T12 B4). Insurance puts in ₹1,000 on the 5th, next on 5 Nov 2026; today is 26 Oct 2026.
void main() {
  const List<_Form> forms = <_Form>[
    (
      name: 'estimate',
      target: 12000,
      setAside: 7000,
      shown: '₹7,000 set aside$_nbsp· done by Mar 2027',
      spoken: '7,000 rupees set aside, done by March 2027',
    ),
    (
      name: 'estimate within this year',
      target: 3000,
      setAside: 1000,
      shown: '₹1,000 set aside$_nbsp· done by Dec',
      spoken: '1,000 rupees set aside, done by December',
    ),
    (
      name: 'estimate with nothing set aside',
      target: 12000,
      setAside: 0,
      shown: 'Up to ₹12,000$_nbsp· done by Oct 2027',
      spoken: 'Up to 12,000 rupees, done by October 2027',
    ),
    (
      name: 'reached',
      target: 12000,
      setAside: 12000,
      shown: '₹12,000 set aside$_nbsp· reached ₹12,000',
      spoken: '12,000 rupees set aside, reached 12,000 rupees',
    ),
    (
      name: 'far',
      target: 200000,
      setAside: 500,
      shown: '₹500 set aside$_nbsp· over 10 years to go',
      spoken: '500 rupees set aside, over 10 years to go',
    ),
    (
      name: 'far with nothing set aside',
      target: 200000,
      setAside: 0,
      shown: 'Up to ₹2,00,000$_nbsp· over 10 years to go',
      spoken: 'Up to 2,00,000 rupees, over 10 years to go',
    ),
  ];

  Future<void> pumpRow(WidgetTester tester, {required int target, required int setAside, Size size = TestWindows.phone, double textScale = 1}) =>
      pumpApp(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: BillRow(
              bill: WorkedExample.insurance.copyWith(target: Option<Money>.of(Money.fromMajor(target))),
              setAside: Money.fromMajor(setAside),
              today: const Option<CalendarDate>.of(WorkedExample.today),
              onEdit: () {},
              onDelete: () {},
              onThresholdReached: () {},
            ),
          ),
        ),
        size: size,
        textScale: textScale,
      );

  final Finder thirdLine = find.byKey(const ValueKey<String>('set-aside'));

  group('BillRow target line (AC-T5)', () {
    for (final _Form form in forms) {
      testWidgets('${form.name}: "${form.shown}", under the schedule line', (WidgetTester tester) async {
        await pumpRow(tester, target: form.target, setAside: form.setAside);

        expect(tester.widget<Text>(thirdLine).data, form.shown);
        expect(tester.getTopLeft(find.text('Every month on day 5')).dy, lessThan(tester.getTopLeft(thirdLine).dy));
      });

      testWidgets('${form.name}: TalkBack reads one sentence with no dot or no-break space (AC-T7, B4)', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpRow(tester, target: form.target, setAside: form.setAside);

        final String label = tester.getSemantics(find.byType(BillRow)).label;
        expect(label, endsWith(', ${form.spoken}'));
        expect(label, isNot(contains('·')));
        expect(label, isNot(contains(_nbsp)));
        handle.dispose();
      });
    }

    testWidgets('the line uses ink2 (UI_DESIGN §5.6)', (WidgetTester tester) async {
      await pumpRow(tester, target: 12000, setAside: 7000);

      final BuildContext context = tester.element(thirdLine);
      expect(tester.widget<Text>(thirdLine).style?.color, Theme.of(context).textTheme.bodySmall?.color);
    });

    for (final double scale in <double>[1.5, 2.0]) {
      testWidgets('wraps on a small phone at $scale x text, never ellipsised and never overflowing', (WidgetTester tester) async {
        await pumpRow(tester, target: 12000, setAside: 0, size: TestWindows.smallPhone, textScale: scale);

        expect(tester.takeException(), isNull);
        final Text line = tester.widget<Text>(thirdLine);
        expect(line.overflow, isNot(TextOverflow.ellipsis));
        expect(line.maxLines, isNull);
      });
    }

    testWidgets('without today the month carries its year', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: BillRow(
            bill: WorkedExample.insurance.copyWith(target: Option<Money>.of(Money.fromMajor(3000))),
            setAside: Money.fromMajor(1000),
            onEdit: () {},
            onDelete: () {},
            onThresholdReached: () {},
          ),
        ),
      );

      expect(tester.widget<Text>(thirdLine).data, '₹1,000 set aside$_nbsp· done by Dec 2026');
    });

    testWidgets('a saving with no target is unchanged: "{amount} set aside" above ₹0 only', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: BillRow(
            bill: WorkedExample.insurance,
            setAside: Money.fromMajor(4000),
            today: const Option<CalendarDate>.of(WorkedExample.today),
            onEdit: () {},
            onDelete: () {},
            onThresholdReached: () {},
          ),
        ),
      );

      expect(tester.widget<Text>(thirdLine).data, '₹4,000 set aside');
    });
  });
}
