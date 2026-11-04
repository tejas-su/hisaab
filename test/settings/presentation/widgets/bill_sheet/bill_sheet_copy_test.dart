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
      ('counted earlier', const BillStatus(nextDate: next, daysAway: 31, stamp: BillStampCounted(CalendarDate(2026, 10, 5))), 'Counted 5 Oct'),
      ('counted today', const BillStatus(nextDate: next, daysAway: 31, stamp: BillStampCounted(CalendarDate(2026, 10, 26))), 'Counted today'),
      ('no stamp', const BillStatus(nextDate: next, daysAway: 31, stamp: BillStampNone()), null),
    ];
    for (final (String name, BillStatus status, String? expected) in cases) {
      testWidgets(name, (WidgetTester tester) async {
        await pumpApp(tester, const Scaffold());
        expect(tester.element(find.byType(Scaffold)).stampText(status), expected);
      });
    }
  });
}
