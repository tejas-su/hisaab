import 'dart:ui';

import 'package:hisaab/ask_ai/ask_ai.dart';
import 'package:hisaab/ask_ai/domain/ask_goal.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/month_start.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const List<String> _goals = <String>['How did I do?', 'Where can I save?', 'What should my limits be?', 'Will my money last till payday?'];

const DisplayFeature _tabletopFold = DisplayFeature(
  bounds: Rect.fromLTRB(0, 350, 841, 350),
  type: DisplayFeatureType.fold,
  state: DisplayFeatureState.postureHalfOpened,
);

const DisplayFeature _bookHinge = DisplayFeature(
  bounds: Rect.fromLTRB(330, 0, 343, 841),
  type: DisplayFeatureType.hinge,
  state: DisplayFeatureState.postureFlat,
);

void main() {
  late FakeServices services;
  late AskAiBloc bloc;

  setUp(() {
    services = FakeServices();
    bloc = services.askAiBloc();
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool load = true,
    Size size = TestWindows.phone,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
    double textScale = 1,
    ThemeMode theme = ThemeMode.light,
  }) async {
    if (load) {
      await tester.runAsync(() => bloc.dispatch(const AskAiLoadRequested()));
    }
    await pumpApp(
      tester,
      BlocProvider<AskAiBloc>.value(value: bloc, child: const AskAiPage()),
      size: size,
      displayFeatures: displayFeatures,
      textScale: textScale,
      themeMode: theme,
    );
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  group('AskAiPage (FR-AI)', () {
    testWidgets('loading shows the title only', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.text('Ask AI'), findsOneWidget);
      expect(find.text('How did I do?'), findsNothing);
    });

    testWidgets('a failed load offers Try again, which loads again', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('disk');
      await pump(tester);
      expect(find.text("Couldn't open this."), findsOneWidget);
      services.ledger.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.settle();
      expect(find.text('How did I do?'), findsOneWidget);
    });

    testWidgets('shows four goals, own question, both periods and the preview title', (WidgetTester tester) async {
      await pump(tester);
      for (final String goal in <String>[..._goals, 'Ask something else', 'October', 'Aug – Oct']) {
        expect(find.text(goal), findsOneWidget);
      }
      await scrollTo(tester, find.text('What the AI will see · 6 entries'));
      expect(find.text('What the AI will see · 6 entries'), findsOneWidget);
    });

    testWidgets('tapping Where can I save? selects it', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Where can I save?'));
      await tester.settle();
      expect(
        tester.getSemantics(find.byKey(const ValueKey<String>('goal-helpMeSave'))),
        isSemantics(label: 'Where can I save?', isButton: true, isSelected: true),
      );
      expect((bloc.state as AskAiReady).choice.goal, AskGoal.helpMeSave);
    });

    testWidgets('the period chip and the notes switch change the choice', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Aug – Oct'));
      await tester.settle();
      await scrollTo(tester, find.text('Leave out my notes'));
      await tester.tap(find.text('Leave out my notes'));
      await tester.settle();
      final AskAiReady state = bloc.state as AskAiReady;
      expect(state.choice.period, AskPeriod.lastThreeCycles);
      expect(state.choice.hideNotes, isTrue);
    });

    testWidgets('own question with an empty field disables every action', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Ask something else'));
      await tester.settle();
      expect(find.byKey(const ValueKey<String>('own-question')), findsOneWidget);
      for (final String action in <String>['Copy & open ChatGPT', 'Other apps', 'Copy only']) {
        await scrollTo(tester, find.text(action));
        await tester.tap(find.text(action), warnIfMissed: false);
        await tester.settle();
      }
      expect(services.handoff.copied, isEmpty);
      expect(services.handoff.shared, isEmpty);
    });

    testWidgets('typing a question enables the actions and ends the prompt with it', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Ask something else'));
      await tester.settle();
      await tester.enterText(find.byKey(const ValueKey<String>('own-question')), 'Can I buy a bike?');
      await tester.settle();
      await scrollTo(tester, find.text('Copy only'));
      await tester.tap(find.text('Copy only'));
      await tester.settle();
      expect(services.handoff.copied.single, endsWith('My question: Can I buy a bike?'));
    });

    testWidgets('Copy only shows "Copied. In the chat, long-press and tap Paste."', (WidgetTester tester) async {
      await pump(tester);
      await scrollTo(tester, find.text('Copy only'));
      await tester.tap(find.text('Copy only'));
      await tester.settle();
      expect(find.text('Copied. In the chat, long-press and tap Paste.'), findsOneWidget);
    });

    testWidgets('Copy & open ChatGPT and Other apps hand off the prompt', (WidgetTester tester) async {
      await pump(tester);
      await scrollTo(tester, find.text('Other apps'));
      await tester.tap(find.text('Copy & open ChatGPT'));
      await tester.settle();
      await tester.tap(find.text('Other apps'));
      await tester.settle();
      expect(services.handoff.opened, hasLength(1));
      expect(services.handoff.shared, hasLength(1));
    });

    group('paste caption (BR-15, D74)', () {
      void longPrompt() => services.ledger.entries.addAll(
        List<Entry>.generate(
          40,
          (int i) => Entry(
            id: 100 + i,
            amount: Money.fromMajor(150),
            kind: EntryKind.spent,
            categoryId: SeedCategoryIds.food,
            date: WorkedExample.today,
            createdAt: WorkedExample.now,
            note: 'Lunch',
          ),
        ),
      );

      testWidgets('a prompt short enough to prefill shows no caption', (WidgetTester tester) async {
        services.ledger.entries
          ..clear()
          ..add(WorkedExample.entries.last);
        services.recurring.rules = <RecurringRule>[];
        await pump(tester);
        expect(find.text('ChatGPT will open empty. Long-press the message box and tap Paste.'), findsNothing);
      });

      testWidgets('a long prompt says to paste right above the pinned actions', (WidgetTester tester) async {
        longPrompt();
        await pump(tester);
        final Finder caption = find.byKey(const ValueKey<String>('paste-needed'));
        expect(find.text('ChatGPT will open empty. Long-press the message box and tap Paste.'), findsOneWidget);
        final Rect text = tester.getRect(caption);
        final Rect key = tester.getRect(find.byKey(const ValueKey<String>('open-chatgpt')));
        expect(text.bottom, lessThanOrEqualTo(key.top));
        expect(key.top - text.bottom, lessThanOrEqualTo(8));
        expect(text.left, key.left);
        final Text style = tester.widget<Text>(caption);
        expect(style.style?.color, HisaabColors.light.ink2);
      });

      testWidgets('then Copy & open ChatGPT shows no toast', (WidgetTester tester) async {
        longPrompt();
        await pump(tester);
        await tester.tap(find.text('Copy & open ChatGPT'));
        await tester.settle();
        await tester.pump();
        expect(services.handoff.opened, hasLength(1));
        expect(find.text('Copied. In the chat, long-press and tap Paste.'), findsNothing);
      });

      for (final (String name, Size size) in <(String, Size)>[
        ('small phone', TestWindows.smallPhone),
        ('phone landscape', TestWindows.phoneLandscape),
        ('foldable unfolded', TestWindows.foldableUnfolded),
        ('tablet', TestWindows.tablet),
      ]) {
        testWidgets('the caption fits on a $name at 1.5× text', (WidgetTester tester) async {
          longPrompt();
          await pump(tester, size: size, textScale: 1.5);
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey<String>('paste-needed')), findsOneWidget);
        });
      }
    });

    group('Will my money last till payday? (FR-AI-1)', () {
      testWidgets('shows for the current cycle with a payday', (WidgetTester tester) async {
        await pump(tester);
        expect(find.byKey(const ValueKey<String>('goal-onTrack')), findsOneWidget);
      });

      testWidgets('a month that starts on the 1st asks whether it lasts the month (D117)', (WidgetTester tester) async {
        services.settings.settings = const BudgetSettings(monthStart: MonthStart.firstOfMonth);
        await pump(tester);
        expect(find.text('Will my money last the month?'), findsOneWidget);
        expect(find.text('Will my money last till payday?'), findsNothing);
      });

      testWidgets('is hidden once the cycle is past, leaving three goals and the own question', (WidgetTester tester) async {
        services.clock.current = DateTime(2026, 11, 5, 9);
        await pump(tester);
        expect(find.text('Will my money last till payday?'), findsNothing);
        expect(find.byKey(const ValueKey<String>('goal-onTrack')), findsNothing);
        for (final String goal in <String>['How did I do?', 'Where can I save?', 'What should my limits be?']) {
          expect(find.text(goal), findsOneWidget);
        }
        final Iterable<Divider> dividers = tester.widgetList<Divider>(
          find.descendant(of: find.byKey(const ValueKey<String>('ask-ai-choices')), matching: find.byType(Divider)),
        );
        expect(dividers, hasLength(3));
      });
    });

    group('own-question placeholder (D73)', () {
      testWidgets('reads Ask something else, then an example while focused and empty', (WidgetTester tester) async {
        await pump(tester);
        TextField field() => tester.widget<TextField>(find.byKey(const ValueKey<String>('own-question')));
        expect(field().decoration?.hintText, 'Ask something else');
        await tester.tap(find.byKey(const ValueKey<String>('own-question')));
        await tester.settle();
        expect(field().decoration?.hintText, 'Like: can I afford a new phone this month?');
        expect(find.text('Like: can I afford a new phone this month?'), findsOneWidget);
        await tester.tapAt(tester.getTopLeft(find.byKey(const ValueKey<String>('ask-ai-back'))) + const Offset(200, 10));
        await tester.settle();
        expect(field().decoration?.hintText, 'Ask something else');
      });

      for (final (String name, Size size) in <(String, Size)>[
        ('small phone', TestWindows.smallPhone),
        ('phone landscape', TestWindows.phoneLandscape),
        ('tablet', TestWindows.tablet),
      ]) {
        testWidgets('the example fits on a $name at 1.5× text', (WidgetTester tester) async {
          await pump(tester, size: size, textScale: 1.5);
          await tester.ensureVisible(find.byKey(const ValueKey<String>('own-question')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey<String>('own-question')));
          await tester.settle();
          expect(tester.takeException(), isNull);
          expect(find.text('Like: can I afford a new phone this month?'), findsOneWidget);
        });
      }
    });

    group('period labels (FR-AI-2)', () {
      for (final (String name, Size size) in <(String, Size)>[
        ('phone', TestWindows.phone),
        ('small phone', TestWindows.smallPhone),
        ('phone landscape', TestWindows.phoneLandscape),
        ('foldable unfolded', TestWindows.foldableUnfolded),
        ('foldable landscape', TestWindows.foldableLandscape),
        ('tablet', TestWindows.tablet),
      ]) {
        testWidgets('name the shown cycle and the three-cycle span on a $name at 1.5× text', (WidgetTester tester) async {
          await pump(tester, size: size, textScale: 1.5);
          expect(tester.takeException(), isNull);
          expect(find.descendant(of: find.byKey(const ValueKey<String>('period-thisCycle')), matching: find.text('October')), findsOneWidget);
          expect(
            find.descendant(of: find.byKey(const ValueKey<String>('period-lastThreeCycles')), matching: find.text('Aug – Oct')),
            findsOneWidget,
          );
        });
      }
    });

    testWidgets('the privacy note sits under the preview title as a grey caption', (WidgetTester tester) async {
      await pump(tester);
      await scrollTo(tester, find.text('Nothing leaves your phone until you share it.'));
      final Rect title = tester.getRect(find.text('What the AI will see · 6 entries'));
      final Rect note = tester.getRect(find.text('Nothing leaves your phone until you share it.'));
      expect(note.top, greaterThanOrEqualTo(title.bottom));
      expect(note.left, title.left);
      expect(tester.widget<Text>(find.text('Nothing leaves your phone until you share it.')).style?.color, HisaabColors.light.ink2);
    });

    testWidgets('Back pops the page', (WidgetTester tester) async {
      await tester.runAsync(() => bloc.dispatch(const AskAiLoadRequested()));
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) => BlocProvider<AskAiBloc>.value(value: bloc, child: const AskAiPage()),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('ask-ai-back')));
      await tester.pumpAndSettle();
      expect(find.byType(AskAiPage), findsNothing);
    });

    testWidgets('goals are one column of rows sharing both edges, top to bottom', (WidgetTester tester) async {
      await pump(tester);
      final List<Rect> rows = <String>[
        'reviewMonth',
        'helpMeSave',
        'makeBudget',
        'onTrack',
        'ownQuestion',
      ].map((String goal) => tester.getRect(find.byKey(ValueKey<String>('goal-$goal')))).toList();
      for (final Rect row in rows) {
        expect(row.left, rows.first.left);
        expect(row.right, rows.first.right);
      }
      for (int i = 1; i < rows.length; i++) {
        expect(rows[i].top, greaterThanOrEqualTo(rows[i - 1].bottom));
      }
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('ask-ai-choices'))).dx, 20);
    });

    testWidgets('only the picked row carries the check', (WidgetTester tester) async {
      await pump(tester);
      final Finder check = find.byKey(const ValueKey<String>('goal-check'));
      expect(check, findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey<String>('goal-reviewMonth')), matching: check), findsOneWidget);
      await tester.tap(find.text('Will my money last till payday?'));
      await tester.settle();
      expect(find.descendant(of: find.byKey(const ValueKey<String>('goal-onTrack')), matching: check), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey<String>('period-track')), matching: find.byType(AppIcon)), findsNothing);
    });

    testWidgets('rows are split by hairlines indented to the text, like the Today list', (WidgetTester tester) async {
      await pump(tester);
      final Iterable<Divider> dividers = tester.widgetList<Divider>(
        find.descendant(of: find.byKey(const ValueKey<String>('ask-ai-choices')), matching: find.byType(Divider)),
      );
      expect(dividers, hasLength(4));
      expect(dividers.map((Divider d) => d.indent).toSet(), <double>{74});
      final double label = tester.getTopLeft(find.text('Where can I save?')).dx;
      final double card = tester.getTopLeft(find.byKey(const ValueKey<String>('ask-ai-choices'))).dx;
      expect(label - card, 74);
    });

    testWidgets('typing in the own-question row picks it', (WidgetTester tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('own-question')), 'Can I buy a bike?');
      await tester.settle();
      expect((bloc.state as AskAiReady).choice.goal, AskGoal.ownQuestion);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('goal-ownQuestion')),
          matching: find.byKey(const ValueKey<String>('goal-check')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the header stays put while the content scrolls', (WidgetTester tester) async {
      await pump(tester);
      final Offset before = tester.getTopLeft(find.byKey(const ValueKey<String>('ask-ai-back')));
      await tester.drag(find.byKey(const ValueKey<String>('ask-ai-choices')), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('ask-ai-back'))), before);
    });

    testWidgets('the actions are pinned to the bottom, visible without scrolling', (WidgetTester tester) async {
      await pump(tester);
      final Rect key = tester.getRect(find.byKey(const ValueKey<String>('open-chatgpt')));
      final Rect copy = tester.getRect(find.byKey(const ValueKey<String>('copy-only')));
      expect(copy.bottom, lessThanOrEqualTo(TestWindows.phone.height));
      expect(copy.bottom, greaterThan(TestWindows.phone.height - 120));
      expect(key.top, lessThan(copy.top));
      await tester.drag(find.byKey(const ValueKey<String>('ask-ai-choices')), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const ValueKey<String>('open-chatgpt'))), key);
    });

    testWidgets('light layers: near-white cards on the page, grey only in wells and the period track', (WidgetTester tester) async {
      await pump(tester);
      Color? fill(String key) => (tester.widget<Container>(find.byKey(ValueKey<String>(key))).decoration! as ShapeDecoration).color;
      expect(fill('ask-ai-choices'), HisaabColors.light.surface);
      expect(fill('period-track'), HisaabColors.light.sunk);
      expect(fill('period-thisCycle'), HisaabColors.light.surface);
      await scrollTo(tester, find.byKey(const ValueKey<String>('prompt-preview')));
      expect(fill('prompt-preview'), HisaabColors.light.surface);
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('prompt-preview'))).dx, 20);
    });

    testWidgets('a book-posture hinge puts the controls and the preview on either side', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.foldableUnfolded, displayFeatures: <DisplayFeature>[_bookHinge]);
      final Rect goals = tester.getRect(find.byKey(const ValueKey<String>('goal-ownQuestion')));
      final Rect preview = tester.getRect(find.byKey(const ValueKey<String>('prompt-preview')));
      expect(goals.right, lessThanOrEqualTo(_bookHinge.bounds.left));
      expect(preview.left, greaterThanOrEqualTo(_bookHinge.bounds.right));
    });

    testWidgets('a tabletop fold puts the controls above it and the preview below', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.foldableLandscape, displayFeatures: <DisplayFeature>[_tabletopFold]);
      final Rect header = tester.getRect(find.byKey(const ValueKey<String>('ask-ai-back')));
      final Rect preview = tester.getRect(find.byKey(const ValueKey<String>('prompt-preview')));
      expect(header.bottom, lessThanOrEqualTo(_tabletopFold.bounds.top));
      expect(preview.top, greaterThanOrEqualTo(_tabletopFold.bounds.bottom));
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('phone', TestWindows.phone),
      ('phone landscape', TestWindows.phoneLandscape),
      ('small phone', TestWindows.smallPhone),
      ('foldable unfolded', TestWindows.foldableUnfolded),
      ('foldable landscape', TestWindows.foldableLandscape),
      ('tablet', TestWindows.tablet),
    ]) {
      testWidgets('lays out without overflow on a $name at 1.5× text in dark', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: 1.5, theme: ThemeMode.dark);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('TalkBack reads Back and the notes switch by their labels', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      await scrollTo(tester, find.text('Leave out my notes'));
      expect(
        tester.getSemantics(find.byKey(const ValueKey<String>('hide-notes'))),
        isSemantics(label: 'Leave out my notes', hasToggledState: true, isToggled: false),
      );
      semantics.dispose();
    });

    for (final ThemeMode theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('meets the tap-target, label and contrast guidelines in ${theme.name}', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pump(tester, theme: theme);
        await tester.tap(find.text('Where can I save?'));
        await tester.settle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    group('typography (case study 02)', () {
      testWidgets('the card header is a title like Today, a level above the rows', (WidgetTester tester) async {
        await pump(tester);
        final TextTheme theme = Theme.of(tester.element(find.byType(AskAiPage))).textTheme;
        final TextStyle header = tester.widget<Text>(find.text('What do you want to know?')).style!;
        final TextStyle row = tester.widget<Text>(find.text('Where can I save?')).style!;
        expect(header.fontFamily, theme.titleLarge!.fontFamily);
        expect(header.fontSize, theme.titleLarge!.fontSize);
        expect(header.fontSize!, greaterThan(row.fontSize!));
      });

      testWidgets('rows are Regular body text and only the pick is Semibold', (WidgetTester tester) async {
        await pump(tester);
        final TextStyle picked = tester.widget<Text>(find.text('How did I do?')).style!;
        final TextStyle other = tester.widget<Text>(find.text('Where can I save?')).style!;
        expect(other.fontWeight, FontWeight.w400);
        expect(other.fontSize, 16);
        expect(picked.fontWeight, FontWeight.w600);
        expect(picked.fontSize, other.fontSize);
      });

      testWidgets('the own question types as Regular body text', (WidgetTester tester) async {
        await pump(tester);
        final TextField field = tester.widget<TextField>(find.byKey(const ValueKey<String>('own-question')));
        expect(field.style?.fontWeight, FontWeight.w400);
        expect(field.style?.fontSize, 16);
      });

      testWidgets('the period pick is Semibold ink; the other is Regular grey', (WidgetTester tester) async {
        await pump(tester);
        final TextStyle picked = tester.widget<Text>(find.text('October')).style!;
        final TextStyle other = tester.widget<Text>(find.text('Aug – Oct')).style!;
        expect(picked.fontWeight, FontWeight.w600);
        expect(picked.color, HisaabColors.light.ink);
        expect(other.fontWeight, FontWeight.w400);
        expect(other.color, HisaabColors.light.ink2);
      });

      testWidgets('the preview has a Semibold small heading over Regular grey text', (WidgetTester tester) async {
        await pump(tester);
        await scrollTo(tester, find.byKey(const ValueKey<String>('prompt-preview')));
        final TextStyle title = tester.widget<Text>(find.text('What the AI will see · 6 entries')).style!;
        final TextStyle body = tester.widget<Text>(find.textContaining('You are a friendly money coach')).style!;
        expect(title.fontWeight, FontWeight.w600);
        expect(title.fontSize, 14);
        expect(body.fontWeight, FontWeight.w400);
        expect(body.color, HisaabColors.light.ink2);
      });
    });
  });
}
