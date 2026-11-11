import 'dart:async';
import 'dart:ui';

import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/onboarding/data/mapper/onboarding_draft_mapper.dart';
import 'package:hisaab/onboarding/data/repository/onboarding_draft_repository_impl.dart';
import 'package:hisaab/onboarding/domain/entities/bill_draft.dart';
import 'package:hisaab/onboarding/domain/entities/onboarding_draft.dart';
import 'package:hisaab/onboarding/domain/entities/onboarding_step.dart';
import 'package:hisaab/onboarding/onboarding.dart';
import 'package:hisaab/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:hisaab/onboarding/presentation/widgets/onboarding_illustration.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late OnboardingBloc bloc;
  late int finished;

  setUp(() {
    services = FakeServices(onboardingDone: false, entries: <Entry>[], rules: <RecurringRule>[]);
    bloc = OnboardingBloc(
      drafts: OnboardingDraftRepositoryImpl(preferences: services.preferences),
      completeOnboarding: CompleteOnboarding(
        categories: services.categories,
        recurring: services.recurring,
        preferences: services.preferences,
        postDue: services.postDue,
        clock: services.clock,
      ),
      haptics: services.haptics,
    );
    finished = 0;
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = TestWindows.phone,
    double textScale = 1,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
    Widget? restore,
  }) async {
    await tester.runAsync(() => bloc.dispatch(const OnboardingStarted()));
    await pumpApp(
      tester,
      BlocProvider<OnboardingBloc>.value(value: bloc, child: OnboardingPage(onFinished: () => finished++, restore: restore)),
      size: size,
      textScale: textScale,
      displayFeatures: displayFeatures,
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> tapKeys(WidgetTester tester, String digits) async {
    for (final String key in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
      await settle(tester);
    }
  }

  group('OnboardingPage (FR-ON)', () {

    testWidgets('the first question carries the Restore a backup way out at the top (FR-ON-1, D139)', (WidgetTester tester) async {
      await pump(tester, restore: const Text('restore-slot'));

      expect(find.text('restore-slot'), findsOneWidget);
      expect(tester.getTopLeft(find.text('restore-slot')).dy, lessThan(tester.getTopLeft(find.text('How much money comes in each month?')).dy));
    });

    testWidgets('the way out fits a 320dp phone at 2× text', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.smallPhone, textScale: 2, restore: const Text('restore-slot'));

      expect(tester.takeException(), isNull);
    });
    testWidgets('⌫ drops the last digit and a long-press clears the income', (WidgetTester tester) async {
      await pump(tester);
      await tapKeys(tester, '450');
      await tester.tap(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await settle(tester);
      expect(find.text('₹45'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await settle(tester);
      expect(find.text('₹45'), findsNothing);
    });

    testWidgets('the income question names money, not salary, and says it stays on the phone (D116)', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('Pay, business, pension or family money. If it changes, a low month is a safe guess. Paid weekly? Add up a month.'), findsOneWidget);
      expect(find.text('What you type stays on this phone. The app never uses the internet.'), findsOneWidget);
      await tapKeys(tester, '45000');
      expect(find.text('Every day gets its own share'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await settle(tester);
      expect(find.text('Your month runs from one payday to the next. No fixed day? Pick "It changes".'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('privacy-note')), findsNothing);
    });

    testWidgets('It changes saves the guess as an entry noted "Starting guess" (D117)', (WidgetTester tester) async {
      await pump(tester);
      await tapKeys(tester, '30000');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('payday-changes')));
      await settle(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(services.recurring.setups.single.entries.single.note, 'Starting guess');
    });

    testWidgets('the bills step offers only the six fixed bills, no Credit card or Electricity (D125)', (WidgetTester tester) async {
      await pump(tester);
      await tapKeys(tester, '45000');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('payday-date')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-4')));
      await settle(tester);
      expect(find.byKey(const ValueKey<String>('bill-subscriptions')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('bill-creditCard')), findsNothing);
      expect(find.byKey(const ValueKey<String>('bill-electricity')), findsNothing);
    });

    testWidgets('a bill amount has no privacy note', (WidgetTester tester) async {
      await pump(tester);
      await tapKeys(tester, '45000');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('payday-date')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-4')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
      await settle(tester);
      expect(find.text('How much for Rent each month?'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('privacy-note')), findsNothing);
    });

    testWidgets('three questions to Home: income, payday, a bill, Done', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('How much money comes in each month?'), findsOneWidget);
      await tapKeys(tester, '45000');
      expect(find.text('₹45,000'), findsOneWidget);
      expect(find.text("That's about ₹1,500 a day"), findsOneWidget);

      await tester.tap(find.text('Next'));
      await settle(tester);
      expect(find.text('When does it come?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('payday-date')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-4')));
      await settle(tester);
      expect(find.text('Any fixed bills?'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('bill-rent')));
      await settle(tester);
      expect(find.text('How much for Rent each month?'), findsOneWidget);
      await tapKeys(tester, '8200');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-5')));
      await settle(tester);
      expect(find.text('₹8,200 on day 5'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(finished, 1);
      expect(services.preferences.done, isTrue);
      expect(services.recurring.setups.single.rules.map((RecurringDraft r) => r.label), <String>['Money in', 'Rent']);
    });

    testWidgets('Every week asks for the weekday', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000)),
      );
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('payday-week')));
      await settle(tester);
      expect(find.text('Which day of the week?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('weekday-5')));
      await settle(tester);
      expect(bloc.state, isA<OnboardingInProgress>().having((OnboardingInProgress s) => s.draft.payRule, 'rule', const Option<PayRule>.of(WeeklyOn(5))));
    });

    final List<(String, PayRule)> quickChoices = <(String, PayRule)>[
      ('payday-first', const MonthlyOnDay(1)),
      ('payday-last', const LastDayOfMonth()),
      ('payday-changes', const IrregularIncome()),
    ];
    for (final (String key, PayRule rule) in quickChoices) {
      testWidgets('$key answers step 2 in one tap', (WidgetTester tester) async {
        services.preferences.draftJson = OnboardingDraftMapper.toJson(
          OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000)),
        );
        await pump(tester);
        await tester.tap(find.byKey(ValueKey<String>(key)));
        await settle(tester);
        expect(find.text('Any fixed bills?'), findsOneWidget);
        expect((bloc.state as OnboardingInProgress).draft.payRule, Option<PayRule>.of(rule));
      });
    }

    testWidgets('resumes where it stopped and Skip finishes with no bills (FR-ON-6)', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      await pump(tester);
      expect(find.text('Any fixed bills?'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(finished, 1);
    });

    testWidgets('the bill chips start on the same edge as the question and the finish key', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      await pump(tester);
      final double questionLeft = tester.getTopLeft(find.text('Any fixed bills?')).dx;
      final double keyLeft = tester.getTopLeft(find.byKey(const ValueKey<String>('finish-onboarding'))).dx;
      final double chipLeft = tester.getTopLeft(find.byKey(const ValueKey<String>('bill-rent'))).dx;
      expect(keyLeft, questionLeft);
      expect(chipLeft, questionLeft);
    });

    testWidgets('the six bill chips sit in an even grid of two rows, edge to edge with the finish key', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      await pump(tester);
      Rect chip(String kind) => tester.getRect(find.byKey(ValueKey<String>('bill-$kind')));
      final Rect key = tester.getRect(find.byKey(const ValueKey<String>('finish-onboarding')));
      expect(<double>[chip('emi').top, chip('phone').top], everyElement(chip('rent').top));
      expect(<double>[chip('schoolFees').top, chip('subscriptions').top], everyElement(chip('internet').top));
      expect(chip('internet').top, greaterThan(chip('rent').bottom));
      expect(<double>[chip('emi').width, chip('phone').width, chip('subscriptions').width], everyElement(closeTo(chip('rent').width, 0.01)));
      expect(chip('internet').left, chip('rent').left);
      expect(chip('phone').right, closeTo(key.right, 0.01));
      expect(chip('subscriptions').right, closeTo(key.right, 0.01));
    });

    for (final (String name, Size size, double textScale) in <(String, Size, double)>[
      ('a phone', TestWindows.phone, 1),
      ('a small phone', TestWindows.smallPhone, 1),
      ('a phone at 2× text', TestWindows.phone, 2),
    ]) {
      testWidgets('an added Subscriptions bill shows its amount in the grid, with no check, on $name', (WidgetTester tester) async {
        services.preferences.draftJson = OnboardingDraftMapper.toJson(
          OnboardingDraft(
            step: OnboardingStep.bills,
            income: Money.fromMajor(45000),
            payRule: const Option<PayRule>.of(MonthlyOnDay(4)),
            bills: <BillDraft>[BillDraft(kind: BillKind.subscriptions, amount: Money.fromMajor(12000), dueDay: 15)],
          ),
        );
        await pump(tester, size: size, textScale: textScale);
        final Finder chip = find.byKey(const ValueKey<String>('bill-subscriptions'));
        expect(find.descendant(of: chip, matching: find.text('₹12,000 on day 15')), findsOneWidget);
        expect(find.descendant(of: chip, matching: find.byType(AppIcon)), findsNothing);
        expect(tester.getRect(find.byKey(const ValueKey<String>('bill-internet'))).height, tester.getRect(chip).height);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a failed save keeps the answers and says so', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      services.recurring.startFreshFailure = const _Failure();
      await pump(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(finished, 0);
    });

    testWidgets('while saving, the finish key is disabled', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      services.preferences.markDoneGate = Completer<void>();
      await pump(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(bloc.state, isA<OnboardingFinishing>());
      expect(tester.widget<SignalKey>(find.byKey(const ValueKey<String>('finish-onboarding'))).onPressed, isNull);
      services.preferences.markDoneGate?.complete();
      await settle(tester);
      expect(finished, 1);
    });

    testWidgets('an added bill can be removed', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-phone')));
      await settle(tester);
      await tapKeys(tester, '299');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-2')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-phone')));
      await settle(tester);
      await tester.tap(find.text('Delete Phone'));
      await settle(tester);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('system back steps back a question', (WidgetTester tester) async {
      await pump(tester);
      await tapKeys(tester, '5');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('How much money comes in each month?'), findsOneWidget);
    });

    final List<(String, Size, double, List<DisplayFeature>)> windows = <(String, Size, double, List<DisplayFeature>)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2, const <DisplayFeature>[]),
      ('a phone in landscape', TestWindows.phoneLandscape, 1, const <DisplayFeature>[]),
      ('a split-screen window (E18)', const Size(412, 400), 1, const <DisplayFeature>[]),
      ('a tablet', TestWindows.tablet, 1, const <DisplayFeature>[]),
      (
        'tabletop posture (E17)',
        const Size(701, 841),
        1,
        const <DisplayFeature>[
          DisplayFeature(bounds: Rect.fromLTRB(0, 420, 701, 420), type: DisplayFeatureType.fold, state: DisplayFeatureState.postureHalfOpened),
        ],
      ),
    ];
    for (final (String name, Size size, double scale, List<DisplayFeature> features) in windows) {
      testWidgets('step 1 lays out without overflow on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale, displayFeatures: features);
        await tapKeys(tester, '45000');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tabletop: the keypad is below the fold (E17)', (WidgetTester tester) async {
      await pump(
        tester,
        size: const Size(701, 841),
        displayFeatures: const <DisplayFeature>[
          DisplayFeature(bounds: Rect.fromLTRB(0, 420, 701, 420), type: DisplayFeatureType.fold, state: DisplayFeatureState.postureHalfOpened),
        ],
      );
      expect(tester.getRect(find.byKey(const ValueKey<String>('keypad-1'))).top, greaterThanOrEqualTo(420));
      expect(tester.getRect(find.text('How much money comes in each month?')).bottom, lessThanOrEqualTo(420));
    });

    OnboardingPicture shownPicture(WidgetTester tester) => tester.widget<OnboardingIllustration>(find.byType(OnboardingIllustration)).picture;

    testWidgets('When does it come? shows the calendar in hand (D144)', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000)),
      );
      await pump(tester);

      expect(shownPicture(tester), OnboardingPicture.payday);
      expect(find.byType(Image), findsOneWidget);
    });

    final List<(String, String)> pickers = <(String, String)>[
      ('payday-date', 'Which day of the month?'),
      ('payday-week', 'Which day of the week?'),
    ];
    for (final (String key, String question) in pickers) {
      testWidgets('$question shows the pencil ringing a day (D144)', (WidgetTester tester) async {
        services.preferences.draftJson = OnboardingDraftMapper.toJson(
          OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000)),
        );
        await pump(tester);
        await tester.tap(find.byKey(ValueKey<String>(key)));
        await settle(tester);

        expect(find.text(question), findsOneWidget);
        expect(shownPicture(tester), OnboardingPicture.pickDay);
      });
    }

    testWidgets('Any fixed bills? shows the receipt in hand (D144)', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000), payRule: const Option<PayRule>.of(MonthlyOnDay(4))),
      );
      await pump(tester);

      expect(shownPicture(tester), OnboardingPicture.bills);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('on a 320dp phone at 2× text the picture steps aside and nothing overflows (D144)', (WidgetTester tester) async {
      services.preferences.draftJson = OnboardingDraftMapper.toJson(
        OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000)),
      );
      await pump(tester, size: TestWindows.smallPhone, textScale: 2);

      expect(find.byType(Image), findsNothing);
      expect(find.byKey(const ValueKey<String>('payday-changes')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await tapKeys(tester, '45000');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}

final class _Failure extends Failure {
  const _Failure() : super('disk full');
}
