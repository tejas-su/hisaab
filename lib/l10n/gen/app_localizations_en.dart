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
          'It happens. The $amount comes out of tomorrow, so it is a little smaller.',
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
      'Pay, business, pension or family money. If it changes, a low month is a safe guess.';

  @override
  String get startingGuessNote => 'Starting guess';

  @override
  String get incomePrivacy =>
      'It stays on this phone. The app never uses the internet.';

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
      'Your month runs from one payday to the next. No fixed day? Pick It changes.';

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
      'creditCard': 'Credit card',
      'electricity': 'Electricity',
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
  String get dueSoonOpensBill => 'Opens the bill.';

  @override
  String get settingsMoney => 'Money';

  @override
  String get fixedBills => 'Bills';

  @override
  String get fixedBillsHint =>
      'Most go out by themselves on their day. If the amount changes, Home asks how much.';

  @override
  String get addBill => 'Add a bill';

  @override
  String get noBills =>
      'No bills added yet. Add rent, EMI or anything that goes out every month.';

  @override
  String get savings => 'Savings';

  @override
  String get savingsHint =>
      'Money you put away on the same day every month, like an RD. It goes in by itself on its day. Today\'s share already leaves room for it.';

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
    return 'How much goes into $saving?';
  }

  @override
  String savingDayQuestion(String saving) {
    return 'Which day does $saving go in?';
  }

  @override
  String get savingSheetEyebrow => 'Saving';

  @override
  String get deleteSaving => 'Delete saving';

  @override
  String get savingSkipped => 'Skipped this month';

  @override
  String savingDeleted(String saving) {
    return 'Deleted $saving';
  }

  @override
  String savingStampDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Goes in $days days from now',
      one: 'Goes in tomorrow',
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
    return 'Next goes in on $date';
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
    return '$saving $amount goes in $_temp0';
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
    return 'Deleted $bill';
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
    return 'Counted $date';
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
  String get billStampCountedToday => 'Counted today';

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
    return 'Next goes out on $date';
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
    return 'About how much is $bill?';
  }

  @override
  String billAmountQuestionCard(String bill) {
    return 'About how much is the $bill bill?';
  }

  @override
  String get billCardHint =>
      'Add what you buy on the card on the day you buy it. This bill only reminds you to pay. It isn\'t counted again.';

  @override
  String get billModeRow => 'Amount changes?';

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
    return '$bill about $amount goes out $_temp0';
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
      'One note on the day a bill that changes, or a card bill, is due';

  @override
  String get remindAskTitle => 'Remind you on the day it\'s due?';

  @override
  String get remindAskYes => 'Remind me';

  @override
  String get remindAskNo => 'Not now';
}

/// The translations for English, as used in India (`en_IN`).
class AppLocalizationsEnIn extends AppLocalizationsEn {
  AppLocalizationsEnIn() : super('en_IN');
}
