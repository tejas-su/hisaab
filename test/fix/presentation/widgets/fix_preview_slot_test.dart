import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/widgets/hisaab_chip.dart';
import 'package:hisaab/fix/presentation/bloc/fix_state.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/fix/presentation/widgets/fix_preview_slot.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/fix_summaries.dart';
import '../../../helpers/pump_app.dart';

FixReady _ready(int? typed, {FixNotice notice = FixNotice.none, bool guard = false, int spentBefore = 27150, int spentToday = 420, int bills = 1200}) =>
    FixReady(
      summary: fixSummary(spentBefore: spentBefore, spentToday: spentToday, bills: bills),
      typed: typed == null ? const Option<int>.none() : Option<int>.of(typed),
      notice: notice,
      guard: guard
          ? Option<FixGuard>.of(FixGuard(openedAt: DateTime(2026, 10, 26), seenGapRupees: -30000))
          : const Option<FixGuard>.none(),
    );

Future<void> _pump(WidgetTester tester, FixState state, {Size size = TestWindows.smallPhone, double textScale = 1, String period = 'month'}) =>
    pumpApp(
      tester,
      Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: FixPreviewSlot(state: state, period: period, onRetry: () {}, debounce: Duration.zero))),
      size: size,
      textScale: textScale,
    );

/// FR-FX-3: every row of the table, both lines, exactly.
void main() {
  final Map<String, (FixState, String, String)> table = <String, (FixState, String, String)>{
    'lower': (_ready(13230), 'hisaab thought ₹17,430.', "That's ₹4,200 less. Each day gets about ₹467 less."),
    'higher': (_ready(18430), 'hisaab thought ₹17,430.', "That's ₹1,000 more. Each day gets about ₹111 more."),
    'short': (_ready(1000), 'hisaab thought ₹17,430.', "That's ₹16,430 less, and ₹200 short of what's still due."),
    'over today': (_ready(2430), 'hisaab thought ₹17,430.', "That's ₹15,000 less. Today is ₹237 over its share."),
    'equal': (_ready(17430), 'hisaab thought ₹17,430.', 'That matches. Nothing to fix.'),
    'close': (_ready(17400), 'hisaab thought ₹17,430.', "That's close enough. Nothing to fix."),
    'large': (_ready(47430), 'hisaab thought ₹17,430.', "That's ₹30,000 more. One question first."),
    'guard': (_ready(47430, guard: true), 'hisaab thought ₹17,430.', "That's ₹30,000 more. Is all of it from this month?"),
    'changed': (_ready(13230, notice: FixNotice.changed), 'Things changed. Check the new amount.', "That's ₹4,200 less. Each day gets about ₹467 less."),
    'save failed': (_ready(13230, notice: FixNotice.saveFailed), "Couldn't save. Try again.", "That's ₹4,200 less. Each day gets about ₹467 less."),
    'zero amount': (_ready(1000, spentBefore: 45000, spentToday: 0, bills: 0), 'hisaab thought nothing was left.', "That's ₹1,000 more. Each day gets about ₹111 more."),
    'below zero': (_ready(2000, spentBefore: 45300, spentToday: 0, bills: 0), 'hisaab thought you were ₹300 short.', "That's ₹2,300 more. Each day gets about ₹222 more."),
  };

  group('FixPreviewSlot copy', () {
    for (final MapEntry<String, (FixState, String, String)> row in table.entries) {
      for (final double scale in <double>[1, 1.5, 2]) {
        testWidgets('${row.key} at ${scale}x', (WidgetTester tester) async {
          await _pump(tester, row.value.$1, textScale: scale);

          expect(find.text(row.value.$2), findsOneWidget);
          expect(find.text(row.value.$3), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('empty shows the helper alone, with this month', (WidgetTester tester) async {
      await _pump(tester, _ready(null));

      expect(find.text("Bank and cash together. Leave out money from before this month."), findsOneWidget);
      expect(find.textContaining('hisaab thought'), findsNothing);
    });

    testWidgets('a weekly cycle says this week in the helper', (WidgetTester tester) async {
      await _pump(tester, _ready(null), period: 'week');

      expect(find.text("Bank and cash together. Leave out money from before this week."), findsOneWidget);
    });

    testWidgets('loading keeps the helper', (WidgetTester tester) async {
      await _pump(tester, const FixLoading());

      expect(find.textContaining('Bank and cash together'), findsOneWidget);
    });

    testWidgets('after No: the count-only notice over nothing else', (WidgetTester tester) async {
      await _pump(tester, _ready(null, notice: FixNotice.countOnly));

      expect(find.text("Count only this month's money."), findsOneWidget);
      expect(find.textContaining('hisaab thought'), findsNothing);
    });

    testWidgets('a failed read says so with a 48dp Try again', (WidgetTester tester) async {
      await _pump(tester, FixFailed(DatabaseFailure('down')));

      expect(find.text("Couldn't check your number."), findsOneWidget);
      expect(tester.getSize(find.byType(HisaabChip)).height >= 48, isTrue);
    });

    testWidgets('last day: lower says today takes all of it, higher says today gets all of it', (WidgetTester tester) async {
      final CycleSummary last = fixSummary(spentBefore: 43150, bills: 0, today: workedPayCycle.end);

      await _pump(tester, FixReady(summary: last, typed: const Option<int>.of(930)));
      expect(find.text("That's ₹500 less. Today takes all of it."), findsOneWidget);

      await _pump(tester, FixReady(summary: last, typed: const Option<int>.of(2000)));
      expect(find.text("That's ₹570 more. Today gets all of it."), findsOneWidget);
    });

    testWidgets('amounts use full Indian grouping, never compact', (WidgetTester tester) async {
      await _pump(tester, FixReady(summary: fixSummary(income: 9000000, spentBefore: 0, spentToday: 0, bills: 0), typed: const Option<int>.of(1)));

      expect(find.textContaining('₹90,00,000'), findsOneWidget);
      expect(find.textContaining('L'), findsNothing);
    });

    testWidgets('"hisaab" is lower case at the start of line 1', (WidgetTester tester) async {
      await _pump(tester, _ready(13230));

      expect(find.textContaining('hisaab thought'), findsOneWidget);
      expect(find.textContaining('Hisaab thought'), findsNothing);
    });

    testWidgets('every state names its direction in words', (WidgetTester tester) async {
      for (final String direction in <String>['less', 'more']) {
        final FixState state = direction == 'less' ? _ready(13230) : _ready(18430);
        await _pump(tester, state);

        expect(find.textContaining(direction), findsOneWidget);
      }
    });
  });

  group('FixPreviewSlot semantics', () {
    testWidgets('only the visible state is in the semantics tree, with amounts spoken in words', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _ready(13230));

      expect(find.bySemanticsLabel(RegExp('hisaab thought 17,430 rupees')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('That matches')), findsNothing);
      handle.dispose();
    });

    testWidgets('the live region speaks the short text, 1.2 s after the last key, and at once on a change of state', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final SemanticsHandle handle = tester.ensureSemantics();
      Widget slot(FixState state) =>
          Scaffold(body: FixPreviewSlot(state: state, period: 'month', onRetry: () {}));
      await pumpApp(tester, slot(_ready(13230)));
      expect(find.bySemanticsLabel('4,200 rupees less.'), findsOneWidget);

      await pumpApp(tester, slot(_ready(13231)), settle: false);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.bySemanticsLabel('4,200 rupees less.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.bySemanticsLabel('4,199 rupees less.'), findsOneWidget);

      await pumpApp(tester, slot(_ready(18430)), settle: false);
      await tester.pump();
      expect(find.bySemanticsLabel('1,000 rupees more.'), findsOneWidget);
      handle.dispose();
    });
  });
}
