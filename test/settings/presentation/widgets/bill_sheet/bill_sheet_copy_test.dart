import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/widgets/bill_sheet/bill_sheet_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('BillSheetCopy.stampText (SPEC BR-9 bill stamp)', () {
    const CalendarDate next = CalendarDate(2026, 11, 26);

    final List<(String, BillStatus, String?)> cases = <(String, BillStatus, String?)>[
      ('due tomorrow', const BillStatus(nextDate: CalendarDate(2026, 10, 27), daysAway: 1, stamp: BillStampDue(1)), 'Due tomorrow'),
      ('due in 5 days', const BillStatus(nextDate: CalendarDate(2026, 10, 31), daysAway: 5, stamp: BillStampDue(5)), 'Due in 5 days'),
      ('counted earlier', const BillStatus(nextDate: next, daysAway: 31, stamp: BillStampCounted(CalendarDate(2026, 10, 5))), 'Went out 5 Oct'),
      ('counted today', const BillStatus(nextDate: next, daysAway: 31, stamp: BillStampCounted(CalendarDate(2026, 10, 26))), 'Went out today'),
      ('no stamp', const BillStatus(nextDate: next, daysAway: 31, stamp: BillStampNone()), null),
    ];
    for (final (String name, BillStatus status, String? expected) in cases) {
      testWidgets(name, (WidgetTester tester) async {
        await pumpApp(tester, const Scaffold());
        expect(tester.element(find.byType(Scaffold)).stampText(status), expected);
      });
    }
  });

  group('BillSheetCopy, card and waiting bills (D123)', () {
    const CalendarDate next = CalendarDate(2026, 11, 26);
    const BillStatus counted = BillStatus(nextDate: next, daysAway: 31, stamp: BillStampCounted(CalendarDate(2026, 10, 5)));
    const BillStatus countedToday = BillStatus(nextDate: next, daysAway: 31, stamp: BillStampCounted(CalendarDate(2026, 10, 26)));
    const BillStatus waiting = BillStatus(nextDate: CalendarDate(2026, 10, 24), daysAway: -2, stamp: BillStampWaiting(CalendarDate(2026, 10, 24)));

    final List<(String, BillStatus, AmountMode, String?)> stamps = <(String, BillStatus, AmountMode, String?)>[
      ('a card bill paid earlier says paid', counted, AmountMode.card, 'Paid 5 Oct'),
      ('a card bill paid today says paid today', countedToday, AmountMode.card, 'Paid today'),
      ('a changing bill entered earlier is counted', counted, AmountMode.varies, 'Went out 5 Oct'),
      ('a changing bill waiting says waiting', waiting, AmountMode.varies, 'Waiting'),
      ('a card bill waiting says waiting', waiting, AmountMode.card, 'Waiting'),
    ];
    for (final (String name, BillStatus status, AmountMode mode, String? expected) in stamps) {
      testWidgets(name, (WidgetTester tester) async {
        await pumpApp(tester, const Scaffold());
        expect(tester.element(find.byType(Scaffold)).stampText(status, mode: mode), expected);
      });
    }

    final List<(String, BillStatus, AmountMode, String)> feet = <(String, BillStatus, AmountMode, String)>[
      ('a waiting changing bill says when it went out', waiting, AmountMode.varies, 'Went out on 24 Oct. Home asks how much.'),
      ('a waiting card bill says when it was due', waiting, AmountMode.card, 'Was due on 24 Oct. Home asks what you paid.'),
      ('an answered bill gives its next date', counted, AmountMode.varies, 'Next due on 26 Nov'),
    ];
    for (final (String name, BillStatus status, AmountMode mode, String expected) in feet) {
      testWidgets(name, (WidgetTester tester) async {
        await pumpApp(tester, const Scaffold());
        expect(tester.element(find.byType(Scaffold)).footText(status, kind: EntryKind.spent, mode: mode), expected);
      });
    }
  });
}
