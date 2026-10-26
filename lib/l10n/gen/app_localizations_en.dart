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
  String get screenInProgress => 'This screen is being built.';

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
}

/// The translations for English, as used in India (`en_IN`).
class AppLocalizationsEnIn extends AppLocalizationsEn {
  AppLocalizationsEnIn() : super('en_IN');
}
