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
  String get paceAtThisPace => 'At this pace';

  @override
  String get paceToday => 'Today';

  @override
  String paceGapUnder(String amount) {
    return '$amount under steady pace.';
  }

  @override
  String paceGapOver(String amount) {
    return '$amount over steady pace.';
  }

  @override
  String paceSpare(String amount) {
    return 'At this pace about $amount spare.';
  }

  @override
  String paceRunsOut(String date) {
    return 'At this pace it runs out on $date.';
  }

  @override
  String get whereItWent => 'Where it went';

  @override
  String percentShare(int percent) {
    return '$percent%';
  }

  @override
  String pastLimit(String amount) {
    return '$amount over limit';
  }

  @override
  String limitLeft(String amount) {
    return '$amount left';
  }

  @override
  String get hatchKey => 'Striped part is over the limit.';

  @override
  String limitOf(String amount) {
    return 'limit $amount';
  }

  @override
  String nothingSpentIn(String cycle, String when) {
    String _temp0 = intl.Intl.selectLogic(when, {
      'past': 'Nothing was spent in $cycle.',
      'other': 'Nothing spent in $cycle yet.',
    });
    return '$_temp0';
  }

  @override
  String get tipsTitle => 'Worth knowing';

  @override
  String insightCategoryUp(String category, String amount, String cycle) {
    return '$category spending is $amount more than in $cycle.';
  }

  @override
  String insightBiggestSpend(String category, String amount, String date) {
    return 'Your biggest $category spend was $amount on $date.';
  }

  @override
  String insightSteadiest(String category) {
    return '$category spending stays about the same every week.';
  }

  @override
  String insightLimitOffer(String cycle, String step) {
    return 'Set limits from $cycle\'s spending? Each one is rounded up to the next $step.';
  }

  @override
  String seeEntries(String category) {
    return 'See $category entries';
  }

  @override
  String get useTheseLimits => 'Use these limits';

  @override
  String get seeAll => 'See all';

  @override
  String get everyEntry => 'Every entry';

  @override
  String everyEntryIn(String cycle) {
    return 'Every entry in $cycle';
  }

  @override
  String get allCategories => 'All';

  @override
  String noEntriesIn(String cycle) {
    return 'No entries in $cycle.';
  }

  @override
  String noCategoryEntriesIn(String category, String cycle) {
    return 'No $category entries in $cycle.';
  }

  @override
  String filteredBy(String category) {
    return '· $category';
  }

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
          'It happens. The $amount comes out of tomorrow, so it\'s a little smaller.',
    );
    return '$_temp0';
  }

  @override
  String overCycleCard(String date) {
    return 'It happens. This month\'s money is used up. It starts again on payday, $date.';
  }

  @override
  String overCycleCardMonthEnd(String date) {
    return 'It happens. This month\'s money is used up. It starts again on $date.';
  }

  @override
  String overCycleCardWeek(String date) {
    return 'It happens. This week\'s money is used up. It starts again on payday, $date.';
  }

  @override
  String get safeToSpendThisWeek => 'Safe to spend this week';

  @override
  String todayBarSpent(String amount) {
    return '$amount spent';
  }

  @override
  String todayBarOfShare(String amount) {
    return 'of $amount for today';
  }

  @override
  String weekSpent(String amount) {
    return 'Spent $amount this week';
  }

  @override
  String get weekAllWithin => 'every day within its share';

  @override
  String weekDayOver(String day, String amount) {
    return '$day was $amount over its share';
  }

  @override
  String weekTodayOver(String amount) {
    return 'Today is $amount over its share';
  }

  @override
  String weekMoreDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more days',
      one: 'and 1 more day',
    );
    return '$_temp0';
  }

  @override
  String overShare(String amount) {
    return '$amount over its share';
  }

  @override
  String weekDaySpoken(String day, String amount) {
    return '$day, $amount';
  }

  @override
  String weekTodaySpoken(String amount) {
    return 'Today, $amount so far';
  }

  @override
  String spokenSentences(String first, String second) {
    return '$first. $second';
  }

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
    return 'Yesterday was $amount under its share, so every day got $more more.';
  }

  @override
  String savedYesterdayOnly(String amount) {
    return 'Yesterday was $amount under its share.';
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
  String daysLeftInMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left this month',
      one: 'Last day of the month',
    );
    return '$_temp0';
  }

  @override
  String spokenAmount(String amount) {
    return '$amount rupees';
  }

  @override
  String get startupFailed =>
      'hisaab couldn\'t open your data. Close the app and open it again.';

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
  String get deleteLastDigit =>
      'Delete last digit. Touch and hold to clear all';

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
      'salary': 'Money in',
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
  String get incomeHint =>
      'Pay, business, pension or family money. If it changes, a low month is a safe guess. Paid weekly? Add up a month.';

  @override
  String get startingGuessNote => 'Starting guess';

  @override
  String get incomePrivacy =>
      'What you type stays on this phone. The app never uses the internet.';

  @override
  String dailyPreview(String amount) {
    return 'That\'s about $amount a day';
  }

  @override
  String get dailyPreviewCaption => 'Every day gets its own share';

  @override
  String get paydayQuestion => 'When does it come?';

  @override
  String get paydayHint =>
      'Your month runs from one payday to the next. No fixed day? Pick \"It changes\".';

  @override
  String get payFirstOfMonth => '1st of the month';

  @override
  String get payLastDay => 'Last day of the month';

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
      'Same amount, same day, every month. You can add more later in Settings.';

  @override
  String billName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rent': 'Rent',
      'emi': 'EMI',
      'phone': 'Phone',
      'internet': 'Internet',
      'schoolFees': 'School fees',
      'subscriptions': 'Subscriptions',
      'creditCard': 'Credit card',
      'electricity': 'Electricity',
      'other': 'Bill',
    });
    return '$_temp0';
  }

  @override
  String billAmountQuestion(String bill) {
    return 'How much for $bill each month?';
  }

  @override
  String billDayQuestion(String bill) {
    return 'Which day of the month for $bill?';
  }

  @override
  String billDetail(String amount, int day) {
    return '$amount on day $day';
  }

  @override
  String removeBill(String bill) {
    return 'Delete $bill';
  }

  @override
  String get todayTitle => 'Today';

  @override
  String get todayList => 'Today';

  @override
  String get entryFixedBill => 'Bill';

  @override
  String get lastsTillPayday => 'Lasts till payday';

  @override
  String get lastsTillMonthEnd => 'Lasts till month end';

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
  String get stillLastsMonthEnd => 'still lasts till month end';

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String newMonthIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'new month in $count days',
      one: 'new month tomorrow',
    );
    return '$_temp0';
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
    return 'From tomorrow: $amount a day';
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
  String get noIncomeTitle => 'Add the money that came in';

  @override
  String get noIncomeBody =>
      'Your daily share starts once there\'s money to share.';

  @override
  String get addMoney => 'Add money';

  @override
  String get emptyToday => 'Nothing spent today. Tap Add when you do.';

  @override
  String entryDeleted(String amount) {
    return '$amount deleted';
  }

  @override
  String get loadFailed => 'Couldn\'t open this.';

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
    return 'tomorrow\'s share $amount';
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
    return '$bill, $amount, due $_temp0';
  }

  @override
  String get dueSoonOpensBill => 'Opens the bill.';

  @override
  String get settingsMoney => 'Money';

  @override
  String get settingsLook => 'Look';

  @override
  String get lookTile => 'Light or dark';

  @override
  String get lookMatchPhone => 'Match phone';

  @override
  String get lookMatchPhoneSemantics =>
      'Match phone, light or dark like your phone';

  @override
  String get lookLight => 'Light';

  @override
  String get lookDark => 'Dark';

  @override
  String get fixedBills => 'Bills';

  @override
  String get fixedBillsHint =>
      'hisaab adds most bills to your spends on their day. If the amount changes, Home asks how much.';

  @override
  String get addBill => 'Add a bill';

  @override
  String get noBills =>
      'No bills added yet. Add rent, EMI or anything that goes out every month.';

  @override
  String get savings => 'Savings';

  @override
  String get savingsHint =>
      'Money you put in on the same day every month, like an RD. hisaab adds it on its day for you. Today\'s share already leaves room for it.';

  @override
  String get addSaving => 'Add a saving';

  @override
  String get noSavings =>
      'No savings added yet. Add an RD, SIP or anything you put in every month.';

  @override
  String savingName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rd': 'RD',
      'sip': 'SIP',
      'goldScheme': 'Gold scheme',
      'chit': 'Chit',
      'other': 'Saving',
    });
    return '$_temp0';
  }

  @override
  String get savingNameQuestion => 'What do you save in?';

  @override
  String get savingNameHint => 'RD, SIP, gold scheme…';

  @override
  String savingAmountQuestion(String saving) {
    return 'How much do you put in $saving each month?';
  }

  @override
  String savingDayQuestion(String saving) {
    return 'Which day of the month for $saving?';
  }

  @override
  String get savingSheetEyebrow => 'Saving';

  @override
  String get deleteSaving => 'Delete saving';

  @override
  String savingSkipped(String saving) {
    return '$saving skipped this month';
  }

  @override
  String savingDeleted(String saving) {
    return '$saving deleted';
  }

  @override
  String savingStampDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due tomorrow',
    );
    return '$_temp0';
  }

  @override
  String savingStampCounted(String date) {
    return 'Put in $date';
  }

  @override
  String get savingStampCountedToday => 'Put in today';

  @override
  String savingNextGoesIn(String date) {
    return 'Next due on $date';
  }

  @override
  String savingSlipSpoken(String saving, String amount, int day) {
    return '$saving, $amount, every month on day $day';
  }

  @override
  String savingGoesIn(String saving, String amount, int days, String weekday) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'on $weekday',
      one: 'tomorrow',
    );
    return '$saving, $amount, due $_temp0';
  }

  @override
  String get dueSoonOpensSaving => 'Opens the saving.';

  @override
  String get entrySaved => 'Saved';

  @override
  String get entryPutInExtra => 'Put in extra';

  @override
  String savedSince(String amount, String month) {
    return '$amount put in since $month';
  }

  @override
  String get putInExtra => 'Put in extra';

  @override
  String get putInQuestion => 'How much extra are you putting in?';

  @override
  String putInEachDayLess(String end, String amount) {
    String _temp0 = intl.Intl.selectLogic(end, {
      'monthEnd': 'Each day till month end gets $amount less',
      'other': 'Each day till payday gets $amount less',
    });
    return '$_temp0';
  }

  @override
  String putInLastDay(String end) {
    String _temp0 = intl.Intl.selectLogic(end, {
      'monthEnd': 'The month ends today.',
      'other': 'Payday\'s tomorrow.',
    });
    return '$_temp0';
  }

  @override
  String get putInNothingLeft => 'Nothing left to put in for now.';

  @override
  String spentAndSaved(String spent, String saved) {
    return 'Spent $spent · Saved $saved';
  }

  @override
  String billEveryMonth(int day) {
    return 'Every month on day $day';
  }

  @override
  String billAmountAbout(String amount) {
    return 'about $amount';
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
    return '$bill deleted';
  }

  @override
  String get billSheetEyebrow => 'Bill';

  @override
  String billStampDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due tomorrow',
    );
    return '$_temp0';
  }

  @override
  String billStampCounted(String date) {
    return 'Went out $date';
  }

  @override
  String billStampPaid(String date) {
    return 'Paid $date';
  }

  @override
  String get billStampPaidToday => 'Paid today';

  @override
  String get billStampWaiting => 'Waiting';

  @override
  String billWaitingVaries(String date) {
    return 'Went out on $date. Home asks how much.';
  }

  @override
  String billWaitingCard(String date) {
    return 'Was due on $date. Home asks what you paid.';
  }

  @override
  String get billStampCountedToday => 'Went out today';

  @override
  String get billAnswerAmount => 'Amount';

  @override
  String get billAnswerDay => 'Day of the month';

  @override
  String get billAnswerName => 'Name';

  @override
  String get billAnswerIcon => 'Icon';

  @override
  String billChangeSpoken(String answer, String value) {
    return 'Change $answer, $value';
  }

  @override
  String billNextGoesOut(String date) {
    return 'Next due on $date';
  }

  @override
  String get billSaved => 'Changed.';

  @override
  String get deleteBill => 'Delete bill';

  @override
  String get save => 'Save';

  @override
  String billWas(String amount) {
    return 'Was $amount';
  }

  @override
  String billIconQuestion(String bill) {
    return 'Pick an icon for $bill';
  }

  @override
  String billIconFromName(String icon) {
    return 'From the name: $icon';
  }

  @override
  String get billIconNoMatch => 'No icon matches the name';

  @override
  String billNameIconFollows(String icon) {
    return 'Icon from the name: $icon';
  }

  @override
  String billNameIconKept(String icon) {
    return 'Icon stays $icon. Change it on the bill.';
  }

  @override
  String billIconName(String icon) {
    String _temp0 = intl.Intl.selectLogic(icon, {
      'home': 'Home',
      'power': 'Power',
      'phone': 'Phone',
      'internet': 'Internet',
      'loan': 'Loan',
      'card': 'Card',
      'tv': 'TV & apps',
      'school': 'School',
      'water': 'Water',
      'gas': 'Gas',
      'insurance': 'Insurance',
      'help': 'House help',
      'milk': 'Milk',
      'society': 'Society',
      'car': 'Car',
      'other': 'Bill',
    });
    return '$_temp0';
  }

  @override
  String billSlipSpoken(String bill, String icon, String amount, int day) {
    return '$bill, $icon, $amount, every month on day $day';
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
  String get askGoalLastsMonth => 'Will my money last the month?';

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

  @override
  String billAmountQuestionVaries(String bill) {
    return 'About how much for $bill each month?';
  }

  @override
  String billAmountQuestionCard(String bill) {
    return 'About how much for $bill each month?';
  }

  @override
  String get billCardHint =>
      'Add what you buy on the card on the day you buy it. This bill only reminds you to pay. It isn\'t counted again.';

  @override
  String get billModeRow => 'Kind of bill';

  @override
  String get billModeQuestion => 'What kind of bill is it?';

  @override
  String get billModeFixed => 'Same every month';

  @override
  String get billModeVaries => 'Changes every month';

  @override
  String get billModeCard => 'Credit card';

  @override
  String waitingVariesToday(String bill) {
    return '$bill went out today. How much?';
  }

  @override
  String waitingVariesOn(String bill, String date) {
    return '$bill went out on $date. How much?';
  }

  @override
  String waitingCardToday(String bill) {
    return '$bill bill is due today. How much did you pay?';
  }

  @override
  String waitingCardOn(String bill, String date) {
    return '$bill bill was due on $date. How much did you pay?';
  }

  @override
  String get waitingOpensHint => 'Opens the keypad.';

  @override
  String billGoesOutAbout(String bill, String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'tomorrow',
    );
    return '$bill, about $amount, due $_temp0';
  }

  @override
  String billAmountTitle(String bill, String date) {
    return '$bill · $date';
  }

  @override
  String billAmountLastTime(String amount) {
    return 'Last time $amount';
  }

  @override
  String billAmountYourGuess(String amount) {
    return 'You said about $amount';
  }

  @override
  String get billDidntGoOut => 'Didn\'t go out this month';

  @override
  String billAmountAdded(String bill, String amount) {
    return '$bill $amount added';
  }

  @override
  String billSkipped(String bill) {
    return '$bill skipped this month';
  }

  @override
  String get entryCardPaid => 'Paid, not counted again';

  @override
  String reminderTitleVaries(String bill) {
    return '$bill went out today';
  }

  @override
  String reminderTitleCard(String bill) {
    return '$bill bill is due today';
  }

  @override
  String get reminderText => 'Tap to add how much';

  @override
  String get reminderChannel => 'Bill reminders';

  @override
  String get reminderChannelDescription =>
      'On the day a changing bill or card bill is due';

  @override
  String get remindAskTitle => 'Remind you on the day it\'s due?';

  @override
  String get remindAskYes => 'Remind me';

  @override
  String get remindAskNo => 'Not now';

  @override
  String get remindRefused =>
      'Reminders are off. Home still shows bills that need an amount.';

  @override
  String get moneyComingIn => 'Money coming in';

  @override
  String incomeRowMonthly(String amount, int day) {
    return '$amount · on day $day';
  }

  @override
  String incomeRowLastDay(String amount) {
    return '$amount · last day of the month';
  }

  @override
  String incomeRowWeekly(String amount, String weekday) {
    return '$amount · every $weekday';
  }

  @override
  String get incomeRowIrregular => 'Changes each month';

  @override
  String incomeComesOnDay(int day) {
    return 'Comes every month on day $day';
  }

  @override
  String get incomeComesLastDay => 'Comes on the last day of the month';

  @override
  String incomeComesWeekly(String weekday, String amount) {
    return 'Comes every $weekday, about $amount a week';
  }

  @override
  String get incomeAnswerWhen => 'When it comes';

  @override
  String incomeWhenDay(int day) {
    return 'Day $day';
  }

  @override
  String get incomeWhenLastDay => 'Last day';

  @override
  String incomeStampCame(String date) {
    return 'Came $date';
  }

  @override
  String incomeNextPayday(String date) {
    return 'Next payday $date';
  }

  @override
  String incomeFromPayday(String date) {
    return 'From payday, $date.';
  }

  @override
  String incomeStays(String period, String amount) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'week': 'This week\'s',
      'other': 'This month\'s',
    });
    return '$_temp0 $amount stays as it came.';
  }

  @override
  String incomeChangeThisToo(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'week': 'Change this week too',
      'other': 'Change this month too',
    });
    return '$_temp0';
  }

  @override
  String incomeNowIs(String period, String amount) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'week': 'This week\'s',
      'other': 'This month\'s',
    });
    return '$_temp0 pay is now $amount.';
  }

  @override
  String get incomeIrregularEvery => 'Each month runs from the 1st';

  @override
  String get incomeIrregularFoot =>
      'Add money when it comes. Tap Add, then Got.';

  @override
  String incomeSlipSpoken(String amount, String when) {
    return 'Money coming in, $amount, $when';
  }

  @override
  String incomeLastsTill(String date) {
    return 'This money lasts till $date.';
  }

  @override
  String incomeLastsDays(int days, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'That\'s $days days, about $amount a day.',
      one: 'That\'s 1 day, about $amount a day.',
    );
    return '$_temp0';
  }

  @override
  String incomeWhenSpoken(String value) {
    return 'Change When it comes, $value';
  }

  @override
  String incomeComesEvery(String weekday) {
    return 'Comes every $weekday';
  }

  @override
  String get settingsYourHisaab => 'Your hisaab';

  @override
  String get backUpRow => 'Back up';

  @override
  String backUpLast(String date) {
    return 'Last backed up $date';
  }

  @override
  String get backUpToday => 'Backed up today';

  @override
  String get backUpNever => 'Not backed up yet';

  @override
  String get backUpBusy => 'Backing up…';

  @override
  String get backUpNoLock =>
      'The backup file has no password. Anyone who has it can read your entries and notes, so keep it safe.';

  @override
  String backUpDone(String fileName) {
    return 'Backed up as $fileName';
  }

  @override
  String get backUpDoneNoName => 'Backed up';

  @override
  String get backUpFailed => 'Couldn\'t back up there. Try another folder.';

  @override
  String get backUpReadFailed =>
      'Couldn\'t make the backup. Nothing changed. Try again.';

  @override
  String get restoreRow => 'Restore';

  @override
  String get restoreRowHint => 'Bring back from a backup file';

  @override
  String get restoreChecking => 'Checking the backup…';

  @override
  String get restoreRevertRow => 'Undo restore';

  @override
  String restoreRevertHint(String date) {
    return 'Go back to what you had before $date';
  }

  @override
  String restoreRevertLoses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count entries added since will go.',
      one: 'The 1 entry added since will go.',
    );
    return '$_temp0';
  }

  @override
  String get restoreNotBackup =>
      'That\'s not a hisaab backup. Pick a file whose name starts with hisaab-backup.';

  @override
  String get restoreBroken =>
      'This backup can\'t be opened. It may be cut short. Try another copy.';

  @override
  String get restoreNewer =>
      'This backup is from a newer hisaab. Update hisaab from Play Store, then try again.';

  @override
  String get restoreOpenFailed =>
      'Couldn\'t open that file. Try again or pick another.';

  @override
  String get restoreConfirmTitle => 'Replace with this backup?';

  @override
  String restoreConfirmFrom(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Made on $date, with $count entries.',
      one: 'Made on $date, with 1 entry.',
      zero: 'Made on $date, with no entries.',
    );
    return '$_temp0';
  }

  @override
  String restoreConfirmReplaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'It replaces everything on this phone now, including $count entries. You can undo right after.',
      one: 'It replaces everything on this phone now, including 1 entry. You can undo right after.',
      zero:
          'It replaces everything on this phone now. You can undo right after.',
    );
    return '$_temp0';
  }

  @override
  String get restoreConfirmYes => 'Replace';

  @override
  String get restoreConfirmNo => 'Keep what\'s here';

  @override
  String get restoreWorking => 'Bringing back your hisaab…';

  @override
  String restoreDone(String date) {
    return 'Backup from $date restored';
  }

  @override
  String get restoreUndone => 'Back to what you had before';

  @override
  String get restoreFailed => 'Couldn\'t restore. Nothing changed. Try again.';

  @override
  String get restoreUndoFailed =>
      'Couldn\'t go back. The backup is still in use.';

  @override
  String get restoreLink => 'Restore a backup';

  @override
  String get restoreLinkSpoken => 'Restore a backup from another phone';

  @override
  String get deleteAllRow => 'Delete everything';

  @override
  String get deleteAllRowHint => 'Clear it all and start again';

  @override
  String get deleteAllTitle => 'Delete everything';

  @override
  String get deleteAllLead =>
      'This clears hisaab on this phone. It opens again at the first step, like new.';

  @override
  String get deleteAllListTitle => 'This goes:';

  @override
  String get deleteAllItemEntries => 'Every entry you added';

  @override
  String get deleteAllItemIncome => 'Money coming in';

  @override
  String get deleteAllItemBills => 'Bills and their reminders';

  @override
  String get deleteAllItemSavings => 'Savings';

  @override
  String get deleteAllItemCategories => 'Categories you added or changed';

  @override
  String get deleteAllItemSettings => 'Look and your other settings';

  @override
  String get deleteAllNoUndo =>
      'Once it\'s deleted, there\'s no getting it back.';

  @override
  String get deleteAllStays => 'Backup files you made stay where you put them.';

  @override
  String get deleteAllPhoneSafe =>
      'Only hisaab is cleared. Your phone and other apps stay as they are.';

  @override
  String get deleteAllNoBackup =>
      'Not backed up yet. Back up first to keep a copy.';

  @override
  String get deleteAllBackUpFirst => 'Back up first';

  @override
  String get deleteAllHold => 'Hold to delete everything';

  @override
  String get deleteAllHoldFull => 'Let go to delete';

  @override
  String get deleteAllHoldCaption => 'Press and hold to delete.';

  @override
  String get deleteAllHoldShort => 'Keep holding till it fills up.';

  @override
  String get deleteAllHoldSpoken => 'Delete everything in hisaab';

  @override
  String get deleteAllHoldArmed => 'Double-tap again to delete everything';

  @override
  String get deleteAllHoldHint => 'Double-tap twice to delete';

  @override
  String get deleteAllUndo => 'Undo';

  @override
  String deleteAllUndoCaption(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Deleting in $seconds seconds. Tap Undo to stop.',
      one: 'Deleting in 1 second. Tap Undo to stop.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllUndoSpoken => 'Undo. Keep everything';

  @override
  String deleteAllUndoAnnounced(int seconds) {
    return 'Deleting everything in $seconds seconds. Double-tap to undo.';
  }

  @override
  String get deleteAllUndone => 'Stopped. Nothing was deleted.';

  @override
  String get deleteAllWorking => 'Deleting…';

  @override
  String get deleteAllDoneSpoken =>
      'Everything deleted. hisaab is starting again.';

  @override
  String get deleteAllFailed => 'Couldn\'t delete. Nothing changed. Try again.';

  @override
  String get newCategoryTile => 'New';

  @override
  String get newCategory => 'New category';

  @override
  String get ownCategoriesRule => 'Your own';

  @override
  String get ownCategoriesFull =>
      '4 of your own is the most. Hide one in Settings to make room.';

  @override
  String get newCategoryQuestion => 'What\'s it called?';

  @override
  String get newCategoryHint => 'Petrol, kids, gym…';

  @override
  String get newCategoryFieldLabel => 'Name for the new category';

  @override
  String categoryIconFromName(String icon) {
    return 'Icon from the name: $icon';
  }

  @override
  String categoryIconPicked(String icon) {
    return 'Icon: $icon';
  }

  @override
  String get categoryIconNoMatch => 'Icon: Tag. No match yet';

  @override
  String get categoryIconWaiting => 'The name picks an icon';

  @override
  String get changeIcon => 'Change';

  @override
  String categoryIconSemantics(String icon) {
    return 'Icon, $icon. Double tap to change';
  }

  @override
  String categoryExists(String name) {
    return 'You have $name already. It saves there.';
  }

  @override
  String categoryComesBack(String name) {
    return 'You hid $name. Saving brings it back.';
  }

  @override
  String saveInCategory(String name) {
    return 'Save in $name';
  }

  @override
  String pickIconFor(String name) {
    return 'Pick an icon for $name';
  }

  @override
  String categoryIconFromNameShort(String icon) {
    return 'From the name: $icon';
  }

  @override
  String categoryIconName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'groceries': 'Groceries',
      'vegetables': 'Vegetables',
      'fruit': 'Fruit',
      'milk': 'Milk',
      'chai': 'Chai',
      'coffee': 'Coffee',
      'snacks': 'Snacks',
      'eating_out': 'Eating out',
      'cigarettes': 'Cigarettes',
      'beer': 'Beer',
      'cold_drink': 'Cold drink',
      'drinks': 'Drinks',
      'sweets': 'Sweets',
      'gaming': 'Gaming',
      'cards': 'Cards',
      'lottery': 'Lottery',
      'paan': 'Paan',
      'hookah': 'Hookah',
      'fuel': 'Fuel',
      'auto': 'Auto',
      'cab': 'Cab',
      'bike': 'Bike',
      'car': 'Car',
      'metro': 'Metro',
      'train': 'Train',
      'parking': 'Parking',
      'trip': 'Trip',
      'kids': 'Kids',
      'school': 'School',
      'family': 'Family',
      'pet': 'Pet',
      'cleaning': 'Cleaning',
      'laundry': 'Laundry',
      'repair': 'Repair',
      'plants': 'Plants',
      'medicine': 'Medicine',
      'gym': 'Gym',
      'yoga': 'Yoga',
      'salon': 'Salon',
      'prayer': 'Prayer',
      'giving': 'Giving',
      'gift': 'Gift',
      'wedding': 'Wedding',
      'clothes': 'Clothes',
      'shoes': 'Shoes',
      'jewellery': 'Jewellery',
      'phone': 'Phone',
      'recharge': 'Recharge',
      'movies': 'Movies',
      'books': 'Books',
      'other': 'Tag',
    });
    return '$_temp0';
  }

  @override
  String categoryIconGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'food': 'Food and drink',
      'habits': 'Treats and habits',
      'around': 'Getting around',
      'home': 'Home and family',
      'care': 'Care and giving',
      'other': 'Things and fun',
    });
    return '$_temp0';
  }

  @override
  String newCategorySuggestion(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'groceries': 'Groceries',
      'kids': 'Kids',
      'family': 'Family',
      'pets': 'Pets',
      'petrol': 'Petrol',
      'other': 'Salon',
    });
    return '$_temp0';
  }

  @override
  String get settingsCategories => 'Categories';

  @override
  String categoriesOwnCount(int count, int max) {
    return '$count of $max';
  }

  @override
  String get addCategory => 'Add a category';

  @override
  String get categoriesSpending => 'Spending';

  @override
  String get categoriesSpendingHint =>
      'These 8 keep their places. Rename one or change its icon.';

  @override
  String get categoriesMoneyIn => 'Money in';

  @override
  String get categoryBuiltIn => 'Built in';

  @override
  String get categoryNameRow => 'Name';

  @override
  String get categoryIconRow => 'Icon';

  @override
  String hideCategory(String name) {
    return 'Hide $name';
  }

  @override
  String get hideCategoryNote =>
      'Its entries stay in Spends. It leaves the Add tray.';

  @override
  String builtInRenamedNote(String name) {
    return 'Built in as $name. The new name shows on its past entries too.';
  }

  @override
  String get builtInNote =>
      'Built in. You can rename it or change its icon. It always keeps its place.';

  @override
  String categoryHidden(String name) {
    return '$name hidden';
  }

  @override
  String get renameCategoryQuestion => 'What should it be called?';

  @override
  String addCategoryKey(String name) {
    return 'Add $name';
  }

  @override
  String bringBackCategory(String name) {
    return 'Bring back $name';
  }

  @override
  String get categoryNameTaken => 'Another category is already called that.';

  @override
  String get categoryNameInvalid =>
      'Use 1 to 16 letters, and not Savings or Card bill.';

  @override
  String builtInAs(String name) {
    return 'Built in as $name';
  }

  @override
  String get usualTag => 'your usual';

  @override
  String usualSuggestionSpoken(String category, String amount) {
    return 'Add $category, $amount, your usual';
  }

  @override
  String usualAdded(String amount, String category) {
    return 'Added $amount to $category';
  }

  @override
  String get usualRowTitle => 'Your usual';

  @override
  String usualRowDetail(String amount, String days, String time) {
    String _temp0 = intl.Intl.selectLogic(days, {
      'weekdays': 'weekdays around',
      'weekends': 'weekends around',
      'other': 'around',
    });
    return '$amount, $_temp0 $time';
  }

  @override
  String get usualForget => 'Forget';

  @override
  String usualForgetSpoken(String category) {
    return 'Forget your usual $category';
  }

  @override
  String get usualForgotten => 'Forgotten';

  @override
  String get usualHow => 'Worked out on this phone from what you add.';

  @override
  String get widgetLeftToday => 'left today';

  @override
  String get widgetAddSpoken => 'Add a spend';

  @override
  String get widgetSetUp => 'Set up';

  @override
  String get widgetSetUpBody =>
      'Set up hisaab to see what\'s safe to spend today.';

  @override
  String get widgetStale => 'Open hisaab to update';

  @override
  String widgetDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String widgetDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get widgetName => 'hisaab';

  @override
  String get widgetDescription => 'What\'s safe to spend today, and an Add key';

  @override
  String get tileAddSpend => 'Add a spend';

  @override
  String get shortcutAddSpend => 'Add a spend';

  @override
  String get settingsShortcuts => 'Shortcuts';

  @override
  String get settingsAddWidget => 'Add a widget';

  @override
  String get settingsAddWidgetHint =>
      'See what\'s safe to spend from your home screen';

  @override
  String get settingsAddTile => 'Add to quick settings';

  @override
  String get settingsAddTileHint => 'Add a spend from the pull-down';
}

/// The translations for English, as used in India (`en_IN`).
class AppLocalizationsEnIn extends AppLocalizationsEn {
  AppLocalizationsEnIn() : super('en_IN');
}
