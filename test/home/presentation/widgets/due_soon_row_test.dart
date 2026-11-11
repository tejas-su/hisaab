import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/home/presentation/widgets/due_soon_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final DueSoonBill electricity = DueSoonBill(rule: WorkedExample.electricity, dueDate: const CalendarDate(2026, 10, 29), daysAway: 3);

  group('DueSoonRow (FR-HO-3, D118)', () {
    testWidgets('a 56dp button with the bill\'s icon, the sentence, its date and a chevron', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: DueSoonRow(bill: electricity, onOpenBill: (RecurringRule _) {})));
      expect(tester.getSize(find.byType(DueSoonRow)).height, greaterThanOrEqualTo(56));
      expect(find.text('Electricity, ₹1,200, due in 3 days'), findsOneWidget);
      expect(find.text('Thu, 29 Oct'), findsOneWidget);
      final List<AppIconData> glyphs = tester.widgetList<AppIcon>(find.byType(AppIcon)).map((AppIcon i) => i.icon).toList();
      expect(glyphs, <AppIconData>[BillIcon.power.glyph, AppIcons.next]);
    });

    testWidgets('reads the sentence with the spoken amount, then that it opens the bill', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, Scaffold(body: DueSoonRow(bill: electricity, onOpenBill: (RecurringRule _) {})));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Electricity, 1,200 rupees, due in 3 days')),
        isSemantics(
          label: 'Electricity, 1,200 rupees, due in 3 days',
          hint: 'Opens the bill.',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a tap opens its bill', (WidgetTester tester) async {
      RecurringRule? opened;
      await pumpApp(tester, Scaffold(body: DueSoonRow(bill: electricity, onOpenBill: (RecurringRule rule) => opened = rule)));
      await tester.tap(find.byType(DueSoonRow));
      expect(opened, WorkedExample.electricity);
    });

    testWidgets('holds at 2× text on a small phone', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: DueSoonRow(bill: electricity, onOpenBill: (RecurringRule _) {})),
        size: TestWindows.smallPhone,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DueSoonRow for a saving (D120)', () {
    final RecurringRule rd29 = WorkedExample.rd.copyWith(
      schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 29)),
      nextDue: const CalendarDate(2026, 10, 29),
    );

    testWidgets('a saving goes in on its weekday', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, Scaffold(body: DueSoonRow(bill: DueSoonBill(rule: rd29, dueDate: const CalendarDate(2026, 10, 29), daysAway: 3), onOpenBill: (RecurringRule _) {})));
      expect(find.text('RD, ₹5,000, due on Thu'), findsOneWidget);
      expect(tester.getSemantics(find.byType(DueSoonRow)), isSemantics(hint: 'Opens the saving.', isButton: true, hasTapAction: true));
      final List<AppIconData> glyphs = tester.widgetList<AppIcon>(find.byType(AppIcon)).map((AppIcon i) => i.icon).toList();
      expect(glyphs.first, AppIcons.saving);
      handle.dispose();
    });

    testWidgets('a saving tomorrow', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: DueSoonRow(bill: DueSoonBill(rule: rd29, dueDate: const CalendarDate(2026, 10, 27), daysAway: 1), onOpenBill: (RecurringRule _) {})));
      expect(find.text('RD, ₹5,000, due tomorrow'), findsOneWidget);
    });
  });
}
