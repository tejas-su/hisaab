// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'hisaab';

  @override
  String get navHome => 'Home';

  @override
  String get navSpends => 'Spends';

  @override
  String get settings => 'Settings';

  @override
  String get safeToSpendToday => 'Safe to spend today';

  @override
  String get earlierCycle => 'Earlier';

  @override
  String get laterCycle => 'Later';

  @override
  String get spentSoFar => 'Spent so far';

  @override
  String ofAmount(String amount) {
    return 'of $amount';
  }

  @override
  String get wordGap => ' ';

  @override
  String spentSoFarSpoken(String amount) {
    return 'Spent so far: $amount';
  }

  @override
  String categoryRowSpoken(String category, String amount, int percent) {
    return '$category: $amount, $percent%';
  }

  @override
  String get paceYou => 'You';

  @override
  String get paceSteady => 'Steady pace';

  @override
  String get belowPace => 'Spending slower';

  @override
  String get abovePace => 'Spending faster';

  @override
  String paceSpoken(String spent, String budget, String verdict) {
    return '$spent spent so far of $budget. $verdict.';
  }

  @override
  String get whereItWent => 'Where it went';

  @override
  String percentShare(int percent) {
    return '$percent%';
  }

  @override
  String pastLimit(String amount) {
    return '$amount past limit';
  }

  @override
  String limitOf(String amount) {
    return 'limit $amount';
  }

  @override
  String nothingSpentIn(String cycle) {
    return 'Nothing spent in $cycle yet.';
  }

  @override
  String get tipsTitle => 'Worth knowing';

  @override
  String insightCategoryUp(String category, String amount, String cycle) {
    return '$category is $amount more than in $cycle.';
  }

  @override
  String insightBiggestSpend(String category, String amount, String date) {
    return 'Your biggest $category spend was $amount on $date.';
  }

  @override
  String insightSteadiest(String category) {
    return '$category costs about the same every week.';
  }

  @override
  String insightLimitOffer(String cycle) {
    return 'Set limits from $cycle\'s spending? Each one is rounded up to the next ₹500.';
  }

  @override
  String seeEntries(String category) {
    return 'See $category entries';
  }

  @override
  String get useTheseLimits => 'Use these limits';

  @override
  String get seeEveryEntry => 'See every entry';

  @override
  String get seeAll => 'See all';

  @override
  String get everyEntry => 'Every entry';

  @override
  String get allCategories => 'All';

  @override
  String get noEntriesHere => 'Nothing here yet.';

  @override
  String get seeWhereItWent => 'See where it went';

  @override
  String overTodayCard(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'It happens. The $amount is spread across the next $days days, so each one is a little smaller.',
      one:
          'It happens. The $amount comes out of tomorrow, so it is a little smaller.',
    );
    return '$_temp0';
  }

  @override
  String overCycleCard(String date) {
    return 'It happens. This month\'s money is used up. It starts again on payday, $date.';
  }

  @override
  String get safeToSpendThisWeek => 'Safe to spend this week';

  @override
  String get showThisWeek => 'show this week';

  @override
  String get showToday => 'show today';

  @override
  String amountOverThisWeek(String amount) {
    return '$amount over this week';
  }

  @override
  String savedYesterday(String amount, String more) {
    return 'You saved $amount yesterday, so every day got $more more.';
  }

  @override
  String savedYesterdayOnly(String amount) {
    return 'You saved $amount yesterday.';
  }

  @override
  String daysToPayday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days to payday',
      one: '1 day to payday',
    );
    return '$_temp0';
  }

  @override
  String spokenAmount(String amount) {
    return '$amount rupees';
  }

  @override
  String get startupFailed =>
      'hisaab couldn\'t open its data. Close the app and open it again.';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get delete => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get tryAgain => 'Try again';

  @override
  String get couldntSave => 'Couldn\'t save. Try again.';

  @override
  String get separator => ' · ';

  @override
  String spokenPair(String first, String second) {
    return '$first, $second';
  }

  @override
  String get deleteLastDigit => 'Delete last digit. Long-press to clear';

  @override
  String categoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'food': 'Food',
      'travel': 'Travel',
      'shopping': 'Shopping',
      'bills': 'Bills',
      'fun': 'Fun',
      'health': 'Health',
      'home': 'Home',
      'salary': 'Salary',
      'other_income': 'Other income',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String onboardingProgress(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get incomeQuestion => 'How much money comes in each month?';

  @override
  String get incomeHint => 'Your salary after tax. You can change it any time.';

  @override
  String dailyPreview(String amount) {
    return 'That\'s about $amount a day';
  }

  @override
  String get dailyPreviewCaption => 'One block for every day of the month';

  @override
  String get paydayQuestion => 'When does it come?';

  @override
  String get paydayHint => 'Your month runs from one payday to the next.';

  @override
  String get payFirstOfMonth => '1st of the month';

  @override
  String get payLastDay => 'Last day';

  @override
  String get payPickDate => 'Pick a date';

  @override
  String get payEveryWeek => 'Every week';

  @override
  String get payItChanges => 'It changes';

  @override
  String get pickPaydayQuestion => 'Which day of the month?';

  @override
  String get pickWeekdayQuestion => 'Which day of the week?';

  @override
  String get billsQuestion => 'Any fixed bills?';

  @override
  String get billsHint =>
      'Money that goes out on the same day every month. Add them now or later.';

  @override
  String billName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rent': 'Rent',
      'emi': 'EMI',
      'phone': 'Phone',
      'internet': 'Internet',
      'schoolFees': 'School fees',
      'subscriptions': 'Subscriptions',
      'other': 'Bill',
    });
    return '$_temp0';
  }

  @override
  String billAmountQuestion(String bill) {
    return 'How much is $bill?';
  }

  @override
  String billDayQuestion(String bill) {
    return 'Which day does $bill go out?';
  }

  @override
  String billDetail(String amount, int day) {
    return '$amount on day $day';
  }

  @override
  String removeBill(String bill) {
    return 'Remove $bill';
  }

  @override
  String get todayTitle => 'Today';

  @override
  String get todayList => 'Today';

  @override
  String get lastsTillPayday => 'Lasts till payday';

  @override
  String aboutSpare(String amount) {
    return 'about $amount spare';
  }

  @override
  String runsOutOn(String date) {
    return 'At this pace it runs out on $date';
  }

  @override
  String runsOutOnLower(String date) {
    return 'at this pace it runs out on $date';
  }

  @override
  String get slowDown => 'Slow down';

  @override
  String get shareAlmostUsed => 'today\'s share is almost used';

  @override
  String get overToday => 'Over today';

  @override
  String get stillLasts => 'still lasts till payday';

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String paydayIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'payday in $count days',
      one: 'payday tomorrow',
    );
    return '$_temp0';
  }

  @override
  String amountOverToday(String amount) {
    return '$amount over today';
  }

  @override
  String amountOver(String amount) {
    return '$amount over';
  }

  @override
  String eachDayAfter(String amount) {
    return 'Each day after: $amount';
  }

  @override
  String moreDays(int count) {
    return '+$count';
  }

  @override
  String heroSpoken(String label, String amount, String days, String line) {
    return '$label: $amount. $days. $line.';
  }

  @override
  String get noIncomeTitle => 'Add money you got this month';

  @override
  String get noIncomeBody =>
      'Your daily share starts once there\'s money to share.';

  @override
  String get addMoney => 'Add money';

  @override
  String get emptyToday => 'Nothing spent today. Tap Add when you do.';

  @override
  String entryDeleted(String amount) {
    return 'Deleted $amount';
  }

  @override
  String get loadFailed => 'Couldn\'t load your money.';

  @override
  String gotAmount(String amount) {
    return '+$amount';
  }

  @override
  String get add => 'Add';

  @override
  String get spent => 'Spent';

  @override
  String get got => 'Got';

  @override
  String get moneyOutOrIn => 'Money out or in';

  @override
  String quickAdd(String amount) {
    return '+$amount';
  }

  @override
  String quickAddSpoken(String amount) {
    return 'Add $amount';
  }

  @override
  String leavesForToday(String amount) {
    return 'Leaves $amount for today';
  }

  @override
  String overTodayShare(String amount) {
    return '$amount over today\'s share';
  }

  @override
  String tomorrowShare(String amount) {
    return 'tomorrow $amount';
  }

  @override
  String get whatWasItFor => 'What was it for?';

  @override
  String get whereFrom => 'Where did it come from?';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get addNote => 'Add a note';

  @override
  String get noteHint => 'A few words';

  @override
  String saveToCategory(String category) {
    return '$category. Save';
  }

  @override
  String get backToAmount => 'Back to amount';

  @override
  String billGoesOut(String bill, String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'tomorrow',
    );
    return '$bill $amount goes out $_temp0';
  }

  @override
  String get settingsMoney => 'Money';

  @override
  String get fixedBills => 'Fixed bills';

  @override
  String get fixedBillsHint =>
      'They go out by themselves on their day. Today\'s share already leaves room for them.';

  @override
  String get addBill => 'Add a bill';

  @override
  String get noBills =>
      'No fixed bills yet. Add rent, EMI or anything that goes out every month.';

  @override
  String billEveryMonth(int day) {
    return 'Every month on day $day';
  }

  @override
  String billRowSpoken(String bill, String amount, String when) {
    return '$bill, $amount, $when';
  }

  @override
  String get billNameQuestion => 'What\'s the bill called?';

  @override
  String get billNameLabel => 'Name';

  @override
  String get billNameHint => 'Electricity, water, tuition…';

  @override
  String billDeleted(String bill) {
    return 'Deleted $bill';
  }

  @override
  String get askAiTitle => 'Ask AI';

  @override
  String get askAiQuestion => 'What do you want to know?';

  @override
  String get askGoalReview => 'How did I do?';

  @override
  String get askGoalSave => 'Where can I save?';

  @override
  String get askGoalBudget => 'What should my limits be?';

  @override
  String get askGoalOnTrack => 'Will my money last till payday?';

  @override
  String get askGoalOwn => 'Ask something else';

  @override
  String get askOwnHint => 'Like: can I afford a new phone this month?';

  @override
  String askPeriodThis(String cycle) {
    return '$cycle';
  }

  @override
  String askPeriodThree(String from, String to) {
    return '$from – $to';
  }

  @override
  String askPreviewTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'What the AI will see · $_temp0';
  }

  @override
  String get askPrivacyNote => 'Nothing leaves your phone until you share it.';

  @override
  String get askPreviewGrouped =>
      'Older weeks are shown as totals to keep it short.';

  @override
  String get askShowFull => 'Show full text';

  @override
  String get askShowLess => 'Show less';

  @override
  String get askHideNotes => 'Leave out my notes';

  @override
  String get askOpenChatGpt => 'Copy & open ChatGPT';

  @override
  String get askOtherAi => 'Other apps';

  @override
  String get askCopyOnly => 'Copy only';

  @override
  String get askCopiedToast => 'Copied. In the chat, long-press and tap Paste.';

  @override
  String get askPasteNeeded =>
      'ChatGPT will open empty. Long-press the message box and tap Paste.';

  @override
  String askAiCardTitle(String cycle) {
    return 'Ask an AI about $cycle';
  }

  @override
  String get askAiCardNote => 'You\'ll see exactly what it gets.';
}

/// The translations for English, as used in India (`en_IN`).
class AppLocalizationsEnIn extends AppLocalizationsEn {
  AppLocalizationsEnIn() : super('en_IN');
}
