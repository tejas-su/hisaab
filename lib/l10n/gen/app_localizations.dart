import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'IN'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'hisaab'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSpends.
  ///
  /// In en, this message translates to:
  /// **'Spends'**
  String get navSpends;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @safeToSpendToday.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend today'**
  String get safeToSpendToday;

  /// No description provided for @earlierCycle.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlierCycle;

  /// No description provided for @laterCycle.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterCycle;

  /// No description provided for @spentSoFar.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get spentSoFar;

  /// After the big spent-so-far number on Spends: "₹27,570 of ₹45,000"
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String ofAmount(String amount);

  /// The space between the spent amount and "of ₹45,000"
  ///
  /// In en, this message translates to:
  /// **' '**
  String get wordGap;

  /// No description provided for @spentSoFarSpoken.
  ///
  /// In en, this message translates to:
  /// **'Spent so far: {amount}'**
  String spentSoFarSpoken(String amount);

  /// TalkBack for a Where it went row
  ///
  /// In en, this message translates to:
  /// **'{category}: {amount}, {percent}%'**
  String categoryRowSpoken(String category, String amount, int percent);

  /// No description provided for @paceYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get paceYou;

  /// No description provided for @paceSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady pace'**
  String get paceSteady;

  /// No description provided for @belowPace.
  ///
  /// In en, this message translates to:
  /// **'Below pace'**
  String get belowPace;

  /// No description provided for @abovePace.
  ///
  /// In en, this message translates to:
  /// **'Above pace'**
  String get abovePace;

  /// TalkBack sentence for the whole pace chart card
  ///
  /// In en, this message translates to:
  /// **'{spent} spent so far of {budget}. {verdict}.'**
  String paceSpoken(String spent, String budget, String verdict);

  /// No description provided for @whereItWent.
  ///
  /// In en, this message translates to:
  /// **'Where it went'**
  String get whereItWent;

  /// No description provided for @percentShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentShare(int percent);

  /// No description provided for @pastLimit.
  ///
  /// In en, this message translates to:
  /// **'{amount} past limit'**
  String pastLimit(String amount);

  /// TalkBack detail for a category row with a limit
  ///
  /// In en, this message translates to:
  /// **'limit {amount}'**
  String limitOf(String amount);

  /// No description provided for @nothingSpentIn.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent in {cycle} yet.'**
  String nothingSpentIn(String cycle);

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worth knowing'**
  String get tipsTitle;

  /// No description provided for @insightCategoryUp.
  ///
  /// In en, this message translates to:
  /// **'{category} is up {amount} from last month.'**
  String insightCategoryUp(String category, String amount);

  /// No description provided for @insightBiggestSpend.
  ///
  /// In en, this message translates to:
  /// **'Your biggest {category} spend was {amount} on {date}.'**
  String insightBiggestSpend(String category, String amount, String date);

  /// No description provided for @insightSteadiest.
  ///
  /// In en, this message translates to:
  /// **'{category} is your steadiest spend.'**
  String insightSteadiest(String category);

  /// No description provided for @insightLimitOffer.
  ///
  /// In en, this message translates to:
  /// **'Use last month\'s spending as limits? Each is rounded up to the next ₹500.'**
  String get insightLimitOffer;

  /// No description provided for @seeEntries.
  ///
  /// In en, this message translates to:
  /// **'See entries'**
  String get seeEntries;

  /// No description provided for @useTheseLimits.
  ///
  /// In en, this message translates to:
  /// **'Use these limits'**
  String get useTheseLimits;

  /// No description provided for @seeEveryEntry.
  ///
  /// In en, this message translates to:
  /// **'See every entry'**
  String get seeEveryEntry;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @everyEntry.
  ///
  /// In en, this message translates to:
  /// **'Every entry'**
  String get everyEntry;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @noEntriesHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get noEntriesHere;

  /// No description provided for @seeWhereItWent.
  ///
  /// In en, this message translates to:
  /// **'See where it went'**
  String get seeWhereItWent;

  /// Calm card under the hero when today is overspent (SPEC FR-HO-5); days is at least 1, since on the last day any overspend is over the cycle
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{It happens. The {amount} comes out of tomorrow, so it is a little smaller.} other{It happens. The {amount} is spread across the next {days} days, so each one is a little smaller.}}'**
  String overTodayCard(String amount, int days);

  /// Calm card under the hero when the whole cycle is overspent (SPEC FR-HO-5)
  ///
  /// In en, this message translates to:
  /// **'It happens. This month\'s money is used up. It starts again on payday, {date}.'**
  String overCycleCard(String date);

  /// No description provided for @safeToSpendThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend this week'**
  String get safeToSpendThisWeek;

  /// TalkBack hint for tapping the hero card while it shows today: "Double tap to show this week"
  ///
  /// In en, this message translates to:
  /// **'show this week'**
  String get showThisWeek;

  /// TalkBack hint for tapping the hero card while it shows this week
  ///
  /// In en, this message translates to:
  /// **'show today'**
  String get showToday;

  /// No description provided for @amountOverThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{amount} over this week'**
  String amountOverThisWeek(String amount);

  /// Home's morning note after an underspend (SPEC BR-8)
  ///
  /// In en, this message translates to:
  /// **'You saved {amount} yesterday, so every day got {more} more.'**
  String savedYesterday(String amount, String more);

  /// Home's morning note when the saving adds under one rupee to each day
  ///
  /// In en, this message translates to:
  /// **'You saved {amount} yesterday.'**
  String savedYesterdayOnly(String amount);

  /// No description provided for @daysToPayday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day to payday} other{{count} days to payday}}'**
  String daysToPayday(int count);

  /// Screen-reader form of an amount; amount is digits with Indian grouping, e.g. 1,430
  ///
  /// In en, this message translates to:
  /// **'{amount} rupees'**
  String spokenAmount(String amount);

  /// Shown only when the local database cannot be opened at start-up
  ///
  /// In en, this message translates to:
  /// **'hisaab couldn\'t open its data. Close the app and open it again.'**
  String get startupFailed;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @couldntSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again.'**
  String get couldntSave;

  /// Joins two parts of one line, e.g. "Lasts till payday · about ₹9,300 spare"
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get separator;

  /// Screen-reader form of two parts of one line
  ///
  /// In en, this message translates to:
  /// **'{first}, {second}'**
  String spokenPair(String first, String second);

  /// No description provided for @deleteLastDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit. Long-press to clear'**
  String get deleteLastDigit;

  /// Default name of a seeded category, by its stored key
  ///
  /// In en, this message translates to:
  /// **'{key, select, food{Food} travel{Travel} shopping{Shopping} bills{Bills} fun{Fun} health{Health} home{Home} salary{Salary} other_income{Other income} other{Other}}'**
  String categoryName(String key);

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingProgress(int step, int total);

  /// No description provided for @incomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much money comes in each month?'**
  String get incomeQuestion;

  /// No description provided for @incomeHint.
  ///
  /// In en, this message translates to:
  /// **'Your salary after tax. You can change it any time.'**
  String get incomeHint;

  /// Rough daily share while typing income (amount ÷ 30)
  ///
  /// In en, this message translates to:
  /// **'That\'s about {amount} a day'**
  String dailyPreview(String amount);

  /// No description provided for @dailyPreviewCaption.
  ///
  /// In en, this message translates to:
  /// **'One block for every day of the month'**
  String get dailyPreviewCaption;

  /// No description provided for @paydayQuestion.
  ///
  /// In en, this message translates to:
  /// **'When does it come?'**
  String get paydayQuestion;

  /// No description provided for @paydayHint.
  ///
  /// In en, this message translates to:
  /// **'Your month runs from one payday to the next.'**
  String get paydayHint;

  /// No description provided for @payFirstOfMonth.
  ///
  /// In en, this message translates to:
  /// **'1st of the month'**
  String get payFirstOfMonth;

  /// No description provided for @payLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get payLastDay;

  /// No description provided for @payPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get payPickDate;

  /// No description provided for @payEveryWeek.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get payEveryWeek;

  /// No description provided for @payItChanges.
  ///
  /// In en, this message translates to:
  /// **'It changes'**
  String get payItChanges;

  /// No description provided for @pickPaydayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which day of the month?'**
  String get pickPaydayQuestion;

  /// No description provided for @pickWeekdayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which day of the week?'**
  String get pickWeekdayQuestion;

  /// No description provided for @billsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Any fixed bills?'**
  String get billsQuestion;

  /// No description provided for @billsHint.
  ///
  /// In en, this message translates to:
  /// **'Money that goes out on the same day every month. Add them now or later.'**
  String get billsHint;

  /// Name of a fixed bill chip, by its kind
  ///
  /// In en, this message translates to:
  /// **'{kind, select, rent{Rent} emi{EMI} phone{Phone} internet{Internet} schoolFees{School fees} subscriptions{Subscriptions} other{Bill}}'**
  String billName(String kind);

  /// No description provided for @billAmountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much is {bill}?'**
  String billAmountQuestion(String bill);

  /// No description provided for @billDayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which day does {bill} go out?'**
  String billDayQuestion(String bill);

  /// Chip detail for an added bill
  ///
  /// In en, this message translates to:
  /// **'{amount} on day {day}'**
  String billDetail(String amount, int day);

  /// No description provided for @removeBill.
  ///
  /// In en, this message translates to:
  /// **'Remove {bill}'**
  String removeBill(String bill);

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @todayList.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayList;

  /// No description provided for @lastsTillPayday.
  ///
  /// In en, this message translates to:
  /// **'Lasts till payday'**
  String get lastsTillPayday;

  /// Forecast: money left at payday, rounded to ₹100
  ///
  /// In en, this message translates to:
  /// **'about {amount} spare'**
  String aboutSpare(String amount);

  /// No description provided for @runsOutOn.
  ///
  /// In en, this message translates to:
  /// **'At this pace it runs out on {date}'**
  String runsOutOn(String date);

  /// No description provided for @runsOutOnLower.
  ///
  /// In en, this message translates to:
  /// **'at this pace it runs out on {date}'**
  String runsOutOnLower(String date);

  /// No description provided for @slowDown.
  ///
  /// In en, this message translates to:
  /// **'Slow down'**
  String get slowDown;

  /// No description provided for @shareAlmostUsed.
  ///
  /// In en, this message translates to:
  /// **'today\'s share is almost used'**
  String get shareAlmostUsed;

  /// No description provided for @overToday.
  ///
  /// In en, this message translates to:
  /// **'Over today'**
  String get overToday;

  /// No description provided for @stillLasts.
  ///
  /// In en, this message translates to:
  /// **'still lasts till payday'**
  String get stillLasts;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overBy(String amount);

  /// No description provided for @paydayIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{payday tomorrow} other{payday in {count} days}}'**
  String paydayIn(int count);

  /// No description provided for @amountOverToday.
  ///
  /// In en, this message translates to:
  /// **'{amount} over today'**
  String amountOverToday(String amount);

  /// No description provided for @amountOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String amountOver(String amount);

  /// No description provided for @eachDayAfter.
  ///
  /// In en, this message translates to:
  /// **'Each day after: {amount}'**
  String eachDayAfter(String amount);

  /// Label after the visible day blocks when there are too many to draw
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String moreDays(int count);

  /// Screen-reader sentence for the whole hero card
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}. {days}. {line}.'**
  String heroSpoken(String label, String amount, String days, String line);

  /// No description provided for @noIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add money you got this month'**
  String get noIncomeTitle;

  /// No description provided for @noIncomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily share starts once there\'s money to share.'**
  String get noIncomeBody;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get addMoney;

  /// No description provided for @emptyToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent today. Tap Add when you do.'**
  String get emptyToday;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {amount}'**
  String entryDeleted(String amount);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your money.'**
  String get loadFailed;

  /// An amount of money that came in
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String gotAmount(String amount);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @got.
  ///
  /// In en, this message translates to:
  /// **'Got'**
  String get got;

  /// No description provided for @moneyOutOrIn.
  ///
  /// In en, this message translates to:
  /// **'Money out or in'**
  String get moneyOutOrIn;

  /// Quick chip that adds this amount
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String quickAdd(String amount);

  /// No description provided for @quickAddSpoken.
  ///
  /// In en, this message translates to:
  /// **'Add {amount}'**
  String quickAddSpoken(String amount);

  /// No description provided for @leavesForToday.
  ///
  /// In en, this message translates to:
  /// **'Leaves {amount} for today'**
  String leavesForToday(String amount);

  /// No description provided for @overTodayShare.
  ///
  /// In en, this message translates to:
  /// **'{amount} over today\'s share'**
  String overTodayShare(String amount);

  /// No description provided for @tomorrowShare.
  ///
  /// In en, this message translates to:
  /// **'tomorrow {amount}'**
  String tomorrowShare(String amount);

  /// No description provided for @whatWasItFor.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get whatWasItFor;

  /// No description provided for @whereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where did it come from?'**
  String get whereFrom;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'A few words'**
  String get noteHint;

  /// No description provided for @saveToCategory.
  ///
  /// In en, this message translates to:
  /// **'{category}. Save'**
  String saveToCategory(String category);

  /// No description provided for @backToAmount.
  ///
  /// In en, this message translates to:
  /// **'Back to amount'**
  String get backToAmount;

  /// Home's due-soon nudge for the next fixed bill, e.g. "Electricity ₹1,200 goes out in 3 days"
  ///
  /// In en, this message translates to:
  /// **'{bill} {amount} goes out {days, plural, =1{tomorrow} other{in {days} days}}'**
  String billGoesOut(String bill, String amount, int days);

  /// Settings group heading for money setup
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get settingsMoney;

  /// No description provided for @fixedBills.
  ///
  /// In en, this message translates to:
  /// **'Fixed bills'**
  String get fixedBills;

  /// No description provided for @fixedBillsHint.
  ///
  /// In en, this message translates to:
  /// **'They go out by themselves on their day. Today\'s share already leaves room for them.'**
  String get fixedBillsHint;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add a bill'**
  String get addBill;

  /// No description provided for @noBills.
  ///
  /// In en, this message translates to:
  /// **'No fixed bills yet. Add rent, EMI or anything that goes out every month.'**
  String get noBills;

  /// When a fixed bill goes out
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day}'**
  String billEveryMonth(int day);

  /// Screen-reader label of one fixed bill row
  ///
  /// In en, this message translates to:
  /// **'{bill}, {amount}, {when}'**
  String billRowSpoken(String bill, String amount, String when);

  /// No description provided for @billNameQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s the bill called?'**
  String get billNameQuestion;

  /// No description provided for @billNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billNameLabel;

  /// Placeholder in the bill name field
  ///
  /// In en, this message translates to:
  /// **'Electricity, water, tuition…'**
  String get billNameHint;

  /// No description provided for @billDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {bill}'**
  String billDeleted(String bill);

  /// Title of the Ask AI screen
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAiTitle;

  /// Heading above the Ask AI goal cards
  ///
  /// In en, this message translates to:
  /// **'What do you want to know?'**
  String get askAiQuestion;

  /// Ask AI goal card
  ///
  /// In en, this message translates to:
  /// **'Review my month'**
  String get askGoalReview;

  /// Ask AI goal card
  ///
  /// In en, this message translates to:
  /// **'Help me save'**
  String get askGoalSave;

  /// Ask AI goal card
  ///
  /// In en, this message translates to:
  /// **'Make me a budget'**
  String get askGoalBudget;

  /// Ask AI goal card
  ///
  /// In en, this message translates to:
  /// **'Am I on track?'**
  String get askGoalOnTrack;

  /// Full-width Ask AI goal card that opens a text field
  ///
  /// In en, this message translates to:
  /// **'Ask my own question'**
  String get askGoalOwn;

  /// Placeholder in the Ask AI own-question field
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get askOwnHint;

  /// Ask AI period chip: the cycle Spends was showing
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get askPeriodThis;

  /// Ask AI period chip: that cycle and the two before it
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get askPeriodThree;

  /// Title of the Ask AI prompt preview
  ///
  /// In en, this message translates to:
  /// **'What will be sent · {count, plural, =1{1 entry} other{{count} entries}}'**
  String askPreviewTitle(int count);

  /// Shown under the preview title when the prompt summarised old weeks to stay short
  ///
  /// In en, this message translates to:
  /// **'Older entries are grouped by week to fit.'**
  String get askPreviewGrouped;

  /// Expands the Ask AI preview to the whole prompt
  ///
  /// In en, this message translates to:
  /// **'Show full text'**
  String get askShowFull;

  /// Collapses the Ask AI preview to its first lines
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get askShowLess;

  /// Switch that leaves entry notes out of the Ask AI prompt
  ///
  /// In en, this message translates to:
  /// **'Hide my notes'**
  String get askHideNotes;

  /// Primary Ask AI action: copies the prompt and opens ChatGPT
  ///
  /// In en, this message translates to:
  /// **'Copy & open ChatGPT'**
  String get askOpenChatGpt;

  /// Ask AI action that opens the Android share sheet
  ///
  /// In en, this message translates to:
  /// **'Other AI'**
  String get askOtherAi;

  /// Ask AI action that only copies the prompt
  ///
  /// In en, this message translates to:
  /// **'Copy only'**
  String get askCopyOnly;

  /// Toast after the prompt was copied and the user must paste it themselves
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it in the chat.'**
  String get askCopiedToast;

  /// Text of the Ask AI card at the top of Spends; cycle is a month name such as October
  ///
  /// In en, this message translates to:
  /// **'Ask AI about {cycle} — get a second opinion in one tap.'**
  String askAiCard(String cycle);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'IN':
            return AppLocalizationsEnIn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
