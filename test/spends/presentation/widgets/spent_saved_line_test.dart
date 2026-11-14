import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/spends/presentation/widgets/spent_saved_line.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

/// The Spends line as up to three parts, in a fixed order (SPEC FR-SP-4a, D187, mockup 42 option B).
void main() {
  Widget line({int spent = 27570, int saved = 1000, int notLogged = 4200}) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SpentSavedLine(spent: Money.fromMajor(spent), saved: Money.fromMajor(saved), notLogged: Money.fromMajor(notLogged)),
        ),
      );

  const Size narrow = TestWindows.smallPhone;

  group('SpentSavedLine when it fits', () {
    testWidgets('is one run: Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200', (WidgetTester tester) async {
      await pumpApp(tester, line());

      expect(find.text('Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200'), findsOneWidget);
    });

    testWidgets('keeps the two-part wording the Spends page always had', (WidgetTester tester) async {
      await pumpApp(tester, line(notLogged: 0));

      expect(find.text('Spent ₹27,570 · Saved ₹1,000'), findsOneWidget);
    });

    testWidgets('a part shows only above ₹0: no Saved part, no stray dot', (WidgetTester tester) async {
      await pumpApp(tester, line(saved: 0));

      expect(find.text('Spent ₹27,570 · Not logged ₹4,200'), findsOneWidget);
    });

    testWidgets('a lone part has no dot at all', (WidgetTester tester) async {
      await pumpApp(tester, line(spent: 0, saved: 0));

      expect(find.text('Not logged ₹4,200'), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
    });

    testWidgets('with no part above ₹0 it draws nothing', (WidgetTester tester) async {
      await pumpApp(tester, line(spent: 0, saved: 0, notLogged: 0));

      expect(find.byType(Text), findsNothing);
    });
  });

  group('SpentSavedLine when it does not fit', () {
    testWidgets('wraps between parts at 320dp and 2x text, never inside one, with nothing overflowing', (WidgetTester tester) async {
      await pumpApp(tester, line(), size: narrow, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('·'), findsNWidgets(2));
      final double spentTop = tester.getTopLeft(find.text('Spent ₹27,570')).dy;
      final double notLoggedTop = tester.getTopLeft(find.text('Not logged ₹4,200')).dy;
      expect(notLoggedTop > spentTop, isTrue, reason: 'the parts take separate lines');
      for (final String text in <String>['Spent ₹27,570', 'Saved ₹1,000', 'Not logged ₹4,200']) {
        expect(tester.getSize(find.text(text)).height < 80, isTrue, reason: '$text stays on one line');
      }
    });

    testWidgets('the order never changes: Spent, then Saved, then Not logged', (WidgetTester tester) async {
      await pumpApp(tester, line(), size: narrow, textScale: 2);

      final Offset spent = tester.getTopLeft(find.text('Spent ₹27,570'));
      final Offset saved = tester.getTopLeft(find.text('Saved ₹1,000'));
      final Offset notLogged = tester.getTopLeft(find.text('Not logged ₹4,200'));
      expect(spent.dy <= saved.dy && saved.dy <= notLogged.dy, isTrue);
    });
  });

  group('SpentSavedLine everywhere', () {
    testWidgets('at every window size the line fits', (WidgetTester tester) async {
      for (final Size size in <Size>[TestWindows.phone, TestWindows.smallPhone, TestWindows.splitScreen, TestWindows.book, TestWindows.tablet]) {
        for (final double scale in <double>[1, 1.5, 2]) {
          await pumpApp(tester, line(), size: size, textScale: scale);

          expect(tester.takeException(), isNull, reason: '$size at ${scale}x');
        }
      }
    });

    testWidgets('TalkBack reads one sentence, with no dots', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, line());

      expect(find.bySemanticsLabel('Spent 27,570 rupees. Saved 1,000 rupees. Not logged, spent 4,200 rupees.'), findsOneWidget);
      handle.dispose();
    });
  });
}
