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
  /// **'Spending slower'**
  String get belowPace;

  /// No description provided for @abovePace.
  ///
  /// In en, this message translates to:
  /// **'Spending faster'**
  String get abovePace;

  /// TalkBack sentence for the whole pace chart card
  ///
  /// In en, this message translates to:
  /// **'{spent} spent so far of {budget}. {verdict}.'**
  String paceSpoken(String spent, String budget, String verdict);

  /// Pace chart legend key for the dashed forecast line (D133)
  ///
  /// In en, this message translates to:
  /// **'At this pace'**
  String get paceAtThisPace;

  /// Pace chart date row: today's mark (D133)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get paceToday;

  /// How far spending is below the steady line: the line under the pace chart (with ₹) and TalkBack after paceSpoken (with rupees) (D133, D135)
  ///
  /// In en, this message translates to:
  /// **'{amount} under steady pace.'**
  String paceGapUnder(String amount);

  /// How far spending is above the steady line: the line under the pace chart (with ₹) and TalkBack after paceSpoken (with rupees) (D133, D135)
  ///
  /// In en, this message translates to:
  /// **'{amount} over steady pace.'**
  String paceGapOver(String amount);

  /// After the gap, on the line under the pace chart and in TalkBack: the forecast's money left at the cycle's end, rounded to ₹100 (D133, D135)
  ///
  /// In en, this message translates to:
  /// **'At this pace about {amount} spare.'**
  String paceSpare(String amount);

  /// After the gap, on the line under the pace chart and in TalkBack: the day the forecast says the money runs out (D133, D135)
  ///
  /// In en, this message translates to:
  /// **'At this pace it runs out on {date}.'**
  String paceRunsOut(String date);

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
  /// **'{amount} over limit'**
  String pastLimit(String amount);

  /// Where it went row at or under its limit: what is left of the limit (BR-12)
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String limitLeft(String amount);

  /// Key under Where it went, shown only when a bar is hatched; visual only, hidden from TalkBack
  ///
  /// In en, this message translates to:
  /// **'Striped part is over the limit.'**
  String get hatchKey;

  /// TalkBack detail for a category row with a limit
  ///
  /// In en, this message translates to:
  /// **'limit {amount}'**
  String limitOf(String amount);

  /// Spends with nothing spent; when is 'past' for a finished cycle, else 'current'
  ///
  /// In en, this message translates to:
  /// **'{when, select, past{Nothing was spent in {cycle}.} other{Nothing spent in {cycle} yet.}}'**
  String nothingSpentIn(String cycle, String when);

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worth knowing'**
  String get tipsTitle;

  /// BR-14 #1; cycle names the previous cycle, as the cycle switcher does (October, or 26 Oct – 1 Nov)
  ///
  /// In en, this message translates to:
  /// **'{category} spending is {amount} more than in {cycle}.'**
  String insightCategoryUp(String category, String amount, String cycle);

  /// No description provided for @insightBiggestSpend.
  ///
  /// In en, this message translates to:
  /// **'Your biggest {category} spend was {amount} on {date}.'**
  String insightBiggestSpend(String category, String amount, String date);

  /// BR-14 #3
  ///
  /// In en, this message translates to:
  /// **'{category} spending stays about the same every week.'**
  String insightSteadiest(String category);

  /// BR-14 #4; cycle names the previous cycle, whose spending the limits come from; step is the rounding unit, e.g. ₹500
  ///
  /// In en, this message translates to:
  /// **'Set limits from {cycle}\'s spending? Each one is rounded up to the next {step}.'**
  String insightLimitOffer(String cycle, String step);

  /// Insight action that opens the entries of one category
  ///
  /// In en, this message translates to:
  /// **'See {category} entries'**
  String seeEntries(String category);

  /// No description provided for @useTheseLimits.
  ///
  /// In en, this message translates to:
  /// **'Use these limits'**
  String get useTheseLimits;

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

  /// TalkBack label of Where it went's See all link (FR-SP-6); cycle is the switcher's label, like October
  ///
  /// In en, this message translates to:
  /// **'Every entry in {cycle}'**
  String everyEntryIn(String cycle);

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// Every entry, nothing in the cycle
  ///
  /// In en, this message translates to:
  /// **'No entries in {cycle}.'**
  String noEntriesIn(String cycle);

  /// Every entry filtered to a category with nothing in the cycle
  ///
  /// In en, this message translates to:
  /// **'No {category} entries in {cycle}.'**
  String noCategoryEntriesIn(String category, String cycle);

  /// After the cycle name on Every entry, naming the category the list is narrowed to
  ///
  /// In en, this message translates to:
  /// **'· {category}'**
  String filteredBy(String category);

  /// No description provided for @seeWhereItWent.
  ///
  /// In en, this message translates to:
  /// **'See where it went'**
  String get seeWhereItWent;

  /// Calm card under the hero when today is overspent (SPEC FR-HO-5); days is at least 1, since on the last day any overspend is over the cycle
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{It happens. The {amount} comes out of tomorrow, so it\'s a little smaller.} other{It happens. The {amount} is spread across the next {days} days, so each one is a little smaller.}}'**
  String overTodayCard(String amount, int days);

  /// Calm card under the hero when the whole cycle is overspent (SPEC FR-HO-5)
  ///
  /// In en, this message translates to:
  /// **'It happens. This month\'s money is used up. It starts again on payday, {date}.'**
  String overCycleCard(String date);

  /// Over-cycle card for a calendar-month cycle, which has no payday; date is the 1st of the next month (D116)
  ///
  /// In en, this message translates to:
  /// **'It happens. This month\'s money is used up. It starts again on {date}.'**
  String overCycleCardMonthEnd(String date);

  /// Over-cycle card for a weekly pay cycle (D116)
  ///
  /// In en, this message translates to:
  /// **'It happens. This week\'s money is used up. It starts again on payday, {date}.'**
  String overCycleCardWeek(String date);

  /// No description provided for @safeToSpendThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend this week'**
  String get safeToSpendThisWeek;

  /// Hero caption under today's bar, at its start: what was spent today (BR-6)
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String todayBarSpent(String amount);

  /// Hero caption under today's bar, at its end: today's share (BR-6)
  ///
  /// In en, this message translates to:
  /// **'of {amount} for today'**
  String todayBarOfShare(String amount);

  /// Hero range slot in This week (BR-6a)
  ///
  /// In en, this message translates to:
  /// **'Spent {amount} this week'**
  String weekSpent(String amount);

  /// Detail after weekSpent when no day of the week went over its share
  ///
  /// In en, this message translates to:
  /// **'every day within its share'**
  String get weekAllWithin;

  /// Detail after weekSpent naming the most-over past day; day is a short weekday name such as Tue
  ///
  /// In en, this message translates to:
  /// **'{day} was {amount} over its share'**
  String weekDayOver(String day, String amount);

  /// Detail after weekSpent when today is the most-over day
  ///
  /// In en, this message translates to:
  /// **'Today is {amount} over its share'**
  String weekTodayOver(String amount);

  /// Added after weekDayOver when other days were over too
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more day} other{and {count} more days}}'**
  String weekMoreDays(int count);

  /// TalkBack detail for a week day that went over its share
  ///
  /// In en, this message translates to:
  /// **'{amount} over its share'**
  String overShare(String amount);

  /// TalkBack for one past day of the week; day is the full weekday name
  ///
  /// In en, this message translates to:
  /// **'{day}, {amount}'**
  String weekDaySpoken(String day, String amount);

  /// TalkBack for today in the week
  ///
  /// In en, this message translates to:
  /// **'Today, {amount} so far'**
  String weekTodaySpoken(String amount);

  /// Joins two spoken sentences
  ///
  /// In en, this message translates to:
  /// **'{first}. {second}'**
  String spokenSentences(String first, String second);

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
  /// **'Yesterday was {amount} under its share, so every day got {more} more.'**
  String savedYesterday(String amount, String more);

  /// Home's morning note when the saving adds under one rupee to each day
  ///
  /// In en, this message translates to:
  /// **'Yesterday was {amount} under its share.'**
  String savedYesterdayOnly(String amount);

  /// No description provided for @daysToPayday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day to payday} other{{count} days to payday}}'**
  String daysToPayday(int count);

  /// Days rail caption for a calendar-month cycle; count includes today, like daysToPayday (D116)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last day of the month} other{{count} days left this month}}'**
  String daysLeftInMonth(int count);

  /// Screen-reader form of an amount; amount is digits with Indian grouping, e.g. 1,430
  ///
  /// In en, this message translates to:
  /// **'{amount} rupees'**
  String spokenAmount(String amount);

  /// Shown only when the local database cannot be opened at start-up
  ///
  /// In en, this message translates to:
  /// **'hisaab couldn\'t open your data. Close the app and open it again.'**
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
  /// **'Delete last digit. Touch and hold to clear all'**
  String get deleteLastDigit;

  /// Spoken once, politely, when a key past the 9-digit cap is refused; the amount also keeps a ring until the next key is accepted (FR-AD-2)
  ///
  /// In en, this message translates to:
  /// **'That\'s the most you can type.'**
  String get amountCap;

  /// Default name of a seeded category, by its stored key
  ///
  /// In en, this message translates to:
  /// **'{key, select, food{Food} travel{Travel} shopping{Shopping} bills{Bills} fun{Fun} health{Health} home{Home} salary{Money in} other_income{Other income} other{Other}}'**
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

  /// Onboarding step 1 hint; names sources, not jobs, so it fits non-salaried users (D116)
  ///
  /// In en, this message translates to:
  /// **'Pay, business, pension or family money. If it changes, a low month is a safe guess. Paid weekly? Add up a month.'**
  String get incomeHint;

  /// Note on the income entry onboarding saves for It changes; the amount is the user's low-month guess (D117)
  ///
  /// In en, this message translates to:
  /// **'Starting guess'**
  String get startingGuessNote;

  /// Caption under the onboarding income keypad, beside a lock icon (D116)
  ///
  /// In en, this message translates to:
  /// **'What you type stays on this phone. The app never uses the internet.'**
  String get incomePrivacy;

  /// Rough daily share while typing income (amount ÷ 30)
  ///
  /// In en, this message translates to:
  /// **'That\'s about {amount} a day'**
  String dailyPreview(String amount);

  /// No description provided for @dailyPreviewCaption.
  ///
  /// In en, this message translates to:
  /// **'Every day gets its own share'**
  String get dailyPreviewCaption;

  /// No description provided for @paydayQuestion.
  ///
  /// In en, this message translates to:
  /// **'When does it come?'**
  String get paydayQuestion;

  /// No description provided for @paydayHint.
  ///
  /// In en, this message translates to:
  /// **'Your month runs from one payday to the next. No fixed day? Pick \"It changes\".'**
  String get paydayHint;

  /// No description provided for @payFirstOfMonth.
  ///
  /// In en, this message translates to:
  /// **'1st of the month'**
  String get payFirstOfMonth;

  /// No description provided for @payLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day of the month'**
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
  /// **'Same amount, same day, every month. You can add more later in Settings.'**
  String get billsHint;

  /// Name of a fixed bill chip, by its kind
  ///
  /// In en, this message translates to:
  /// **'{kind, select, rent{Rent} emi{EMI} phone{Phone} internet{Internet} schoolFees{School fees} subscriptions{Subscriptions} creditCard{Credit card} electricity{Electricity} other{Bill}}'**
  String billName(String kind);

  /// No description provided for @billAmountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much for {bill} each month?'**
  String billAmountQuestion(String bill);

  /// No description provided for @billDayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which day of the month for {bill}?'**
  String billDayQuestion(String bill);

  /// Chip detail for an added bill
  ///
  /// In en, this message translates to:
  /// **'{amount} on day {day}'**
  String billDetail(String amount, int day);

  /// No description provided for @removeBill.
  ///
  /// In en, this message translates to:
  /// **'Delete {bill}'**
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

  /// Second line of a list row for a bill the app posted on its day, shown when the row has no note
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get entryFixedBill;

  /// No description provided for @lastsTillPayday.
  ///
  /// In en, this message translates to:
  /// **'Lasts till payday'**
  String get lastsTillPayday;

  /// Range line for a calendar-month cycle, which has no payday (D116)
  ///
  /// In en, this message translates to:
  /// **'Lasts till month end'**
  String get lastsTillMonthEnd;

  /// Forecast: money left at the end of the cycle (payday or month end), rounded to ₹100
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

  /// No description provided for @stillLastsMonthEnd.
  ///
  /// In en, this message translates to:
  /// **'still lasts till month end'**
  String get stillLastsMonthEnd;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overBy(String amount);

  /// Over-cycle detail for a calendar-month cycle (D116)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{new month tomorrow} other{new month in {count} days}}'**
  String newMonthIn(int count);

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
  /// **'From tomorrow: {amount} a day'**
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
  /// **'Add the money that came in'**
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
  /// **'{amount} deleted'**
  String entryDeleted(String amount);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this.'**
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
  /// **'tomorrow\'s share {amount}'**
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
  /// **'{bill}, {amount}, due {days, plural, =1{tomorrow} other{in {days} days}}'**
  String billGoesOut(String bill, String amount, int days);

  /// TalkBack hint on Home's due-soon row, read after the sentence (D118)
  ///
  /// In en, this message translates to:
  /// **'Opens the bill.'**
  String get dueSoonOpensBill;

  /// Settings group heading for money setup
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get settingsMoney;

  /// Settings group heading for choosing light or dark colours (FR-SE-3). Sits under settingsMoney
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get settingsLook;

  /// Title of the one Look row in Settings; the current look shows under it and the phone, sun and moon buttons sit at its end
  ///
  /// In en, this message translates to:
  /// **'Light or dark'**
  String get lookTile;

  /// Look option and the default: the app goes light or dark when the phone does
  ///
  /// In en, this message translates to:
  /// **'Match phone'**
  String get lookMatchPhone;

  /// TalkBack label for the Match phone option, so it makes sense heard alone. Flutter adds 'selected' itself
  ///
  /// In en, this message translates to:
  /// **'Match phone, light or dark like your phone'**
  String get lookMatchPhoneSemantics;

  /// Look option: the app always uses light colours
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lookLight;

  /// Look option: the app always uses dark colours
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get lookDark;

  /// No description provided for @fixedBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get fixedBills;

  /// No description provided for @fixedBillsHint.
  ///
  /// In en, this message translates to:
  /// **'hisaab adds most bills to your spends on their day. If the amount changes, Home asks how much.'**
  String get fixedBillsHint;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add a bill'**
  String get addBill;

  /// No description provided for @noBills.
  ///
  /// In en, this message translates to:
  /// **'No bills added yet. Add rent, EMI or anything that goes out every month.'**
  String get noBills;

  /// Settings row and list title for money put away every month (D120)
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// Hint under the Savings title
  ///
  /// In en, this message translates to:
  /// **'Money you put in on the same day every month, like an RD. hisaab adds it on its day for you. Today\'s share already leaves room for it.'**
  String get savingsHint;

  /// Button on the Savings list
  ///
  /// In en, this message translates to:
  /// **'Add a saving'**
  String get addSaving;

  /// Empty Savings list
  ///
  /// In en, this message translates to:
  /// **'No savings added yet. Add an RD, SIP or anything you put in every month.'**
  String get noSavings;

  /// Name pill for a common saving
  ///
  /// In en, this message translates to:
  /// **'{kind, select, rd{RD} sip{SIP} goldScheme{Gold scheme} chit{Chit} insurance{Insurance} schoolFees{School fees} festival{Festival} other{Saving}}'**
  String savingName(String kind);

  /// First question when adding a saving
  ///
  /// In en, this message translates to:
  /// **'What do you save in?'**
  String get savingNameQuestion;

  /// Hint in the saving name field
  ///
  /// In en, this message translates to:
  /// **'RD, SIP, gold scheme…'**
  String get savingNameHint;

  /// Amount question for a saving
  ///
  /// In en, this message translates to:
  /// **'How much do you put in {saving} each month?'**
  String savingAmountQuestion(String saving);

  /// Day question for a saving
  ///
  /// In en, this message translates to:
  /// **'Which day of the month for {saving}?'**
  String savingDayQuestion(String saving);

  /// Small label at the top of a saving's sheet
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get savingSheetEyebrow;

  /// Delete key on a saving's sheet
  ///
  /// In en, this message translates to:
  /// **'Delete saving'**
  String get deleteSaving;

  /// Snackbar after swiping away a saving its rule put in. Deleting it skips this month, never 'missed' (case study 17).
  ///
  /// In en, this message translates to:
  /// **'{saving} skipped this month'**
  String savingSkipped(String saving);

  /// Snackbar after deleting a saving
  ///
  /// In en, this message translates to:
  /// **'{saving} deleted'**
  String savingDeleted(String saving);

  /// Stamp on a saving's sheet before its day
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Due tomorrow} other{Due in {days} days}}'**
  String savingStampDue(int days);

  /// Stamp on a saving's sheet once this month's went in
  ///
  /// In en, this message translates to:
  /// **'Put in {date}'**
  String savingStampCounted(String date);

  /// Stamp on a saving's sheet when it went in today
  ///
  /// In en, this message translates to:
  /// **'Put in today'**
  String get savingStampCountedToday;

  /// Foot of a saving's sheet
  ///
  /// In en, this message translates to:
  /// **'Next due on {date}'**
  String savingNextGoesIn(String date);

  /// TalkBack sentence for a saving's slip
  ///
  /// In en, this message translates to:
  /// **'{saving}, {amount}, every month on day {day}'**
  String savingSlipSpoken(String saving, String amount, int day);

  /// Home nudge before a saving's day
  ///
  /// In en, this message translates to:
  /// **'{saving}, {amount}, due {days, plural, =1{tomorrow} other{on {weekday}}}'**
  String savingGoesIn(String saving, String amount, int days, String weekday);

  /// TalkBack hint on the saving nudge
  ///
  /// In en, this message translates to:
  /// **'Opens the saving.'**
  String get dueSoonOpensSaving;

  /// Second line of a list row for money put into a saving
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get entrySaved;

  /// Second line of a list row for a one-off saving
  ///
  /// In en, this message translates to:
  /// **'Put in extra'**
  String get entryPutInExtra;

  /// Footer of the Savings list: everything put in, never what it is worth
  ///
  /// In en, this message translates to:
  /// **'{amount} put in since {month}'**
  String savedSince(String amount, String month);

  /// Button on the Savings list for a one-off saving today
  ///
  /// In en, this message translates to:
  /// **'Put in extra'**
  String get putInExtra;

  /// Question on the Put in extra keypad
  ///
  /// In en, this message translates to:
  /// **'How much extra are you putting in?'**
  String get putInQuestion;

  /// Preview under the Put in extra keypad
  ///
  /// In en, this message translates to:
  /// **'{end, select, monthEnd{Each day till month end gets {amount} less} other{Each day till payday gets {amount} less}}'**
  String putInEachDayLess(String end, String amount);

  /// Preview on the cycle's last day
  ///
  /// In en, this message translates to:
  /// **'{end, select, monthEnd{The month ends today.} other{Payday\'s tomorrow.}}'**
  String putInLastDay(String end);

  /// Put in extra when nothing is left
  ///
  /// In en, this message translates to:
  /// **'Nothing left to put in for now.'**
  String get putInNothingLeft;

  /// When a fixed bill goes out
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day}'**
  String billEveryMonth(int day);

  /// A changing or card bill's amount in the Bills list, an estimate, e.g. "about ₹1,200"
  ///
  /// In en, this message translates to:
  /// **'about {amount}'**
  String billAmountAbout(String amount);

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
  /// **'{bill} deleted'**
  String billDeleted(String bill);

  /// Small heading at the top of the bill sheet (D118)
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get billSheetEyebrow;

  /// Stamp on a bill that goes out within 5 days
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Due tomorrow} other{Due in {days} days}}'**
  String billStampDue(int days);

  /// Stamp on a bill the app counted as spent this month, e.g. "Counted 5 Oct"
  ///
  /// In en, this message translates to:
  /// **'Went out {date}'**
  String billStampCounted(String date);

  /// Stamp on a credit card bill recorded as paid this month, e.g. "Paid 5 Oct"; a card bill is never counted (D123)
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String billStampPaid(String date);

  /// Stamp on a credit card bill recorded as paid today
  ///
  /// In en, this message translates to:
  /// **'Paid today'**
  String get billStampPaidToday;

  /// Stamp on a changing or card bill that went out and waits for its amount (D123)
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get billStampWaiting;

  /// Bill sheet footer of a changing bill waiting for its amount, e.g. "Went out on 24 Oct. Home asks how much."
  ///
  /// In en, this message translates to:
  /// **'Went out on {date}. Home asks how much.'**
  String billWaitingVaries(String date);

  /// Bill sheet footer of a card bill waiting to be recorded as paid, e.g. "Was due on 24 Oct. Home asks what you paid."
  ///
  /// In en, this message translates to:
  /// **'Was due on {date}. Home asks what you paid.'**
  String billWaitingCard(String date);

  /// Stamp on a bill the app counted as spent today
  ///
  /// In en, this message translates to:
  /// **'Went out today'**
  String get billStampCountedToday;

  /// Bill sheet row label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get billAnswerAmount;

  /// Bill sheet row label
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get billAnswerDay;

  /// Bill sheet row label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billAnswerName;

  /// Bill sheet row label
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get billAnswerIcon;

  /// Screen-reader label of a bill sheet row, e.g. "Change Amount, ₹1,200"
  ///
  /// In en, this message translates to:
  /// **'Change {answer}, {value}'**
  String billChangeSpoken(String answer, String value);

  /// Bill sheet footer, e.g. "Next goes out on 29 Oct"
  ///
  /// In en, this message translates to:
  /// **'Next due on {date}'**
  String billNextGoesOut(String date);

  /// Bill sheet footer for 2.4 s after an answer is saved
  ///
  /// In en, this message translates to:
  /// **'Changed.'**
  String get billSaved;

  /// Full-width key at the foot of the bill sheet
  ///
  /// In en, this message translates to:
  /// **'Delete bill'**
  String get deleteBill;

  /// Key that saves the open answer
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Under the typed amount when it differs from the saved one
  ///
  /// In en, this message translates to:
  /// **'Was {amount}'**
  String billWas(String amount);

  /// Title of the icon question on the bill sheet, e.g. "Pick an icon for Electricity"
  ///
  /// In en, this message translates to:
  /// **'Pick an icon for {bill}'**
  String billIconQuestion(String bill);

  /// Under the bill on the icon question: the icon its name suggests
  ///
  /// In en, this message translates to:
  /// **'From the name: {icon}'**
  String billIconFromName(String icon);

  /// Under the bill on the icon question when the name suggests none
  ///
  /// In en, this message translates to:
  /// **'No icon matches the name'**
  String get billIconNoMatch;

  /// Under the name field: the icon will follow the typed name
  ///
  /// In en, this message translates to:
  /// **'Icon from the name: {icon}'**
  String billNameIconFollows(String icon);

  /// Under the name field when the user picked the icon by hand
  ///
  /// In en, this message translates to:
  /// **'Icon stays {icon}. Change it on the bill.'**
  String billNameIconKept(String icon);

  /// Name of a bill icon, by its stored value; "bill" falls to other
  ///
  /// In en, this message translates to:
  /// **'{icon, select, home{Home} power{Power} phone{Phone} internet{Internet} loan{Loan} card{Card} tv{TV & apps} school{School} water{Water} gas{Gas} insurance{Insurance} help{House help} milk{Milk} society{Society} car{Car} other{Bill}}'**
  String billIconName(String icon);

  /// Screen-reader label of the bill on the bill sheet
  ///
  /// In en, this message translates to:
  /// **'{bill}, {icon}, {amount}, every month on day {day}'**
  String billSlipSpoken(String bill, String icon, String amount, int day);

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

  /// Ask AI goal row: review the period
  ///
  /// In en, this message translates to:
  /// **'How did I do?'**
  String get askGoalReview;

  /// Ask AI goal row: find cuts
  ///
  /// In en, this message translates to:
  /// **'Where can I save?'**
  String get askGoalSave;

  /// Ask AI goal row: a limit per category for one pay cycle
  ///
  /// In en, this message translates to:
  /// **'What should my limits be?'**
  String get askGoalBudget;

  /// Ask AI goal row for the current cycle with a payday
  ///
  /// In en, this message translates to:
  /// **'Will my money last till payday?'**
  String get askGoalOnTrack;

  /// Ask AI goal row for the current cycle when it ends at month end, with no payday (D117)
  ///
  /// In en, this message translates to:
  /// **'Will my money last the month?'**
  String get askGoalLastsMonth;

  /// Placeholder of the always-visible own-question field, the last Ask AI goal row
  ///
  /// In en, this message translates to:
  /// **'Ask something else'**
  String get askGoalOwn;

  /// Placeholder of the own-question field while it has focus and is empty
  ///
  /// In en, this message translates to:
  /// **'Like: can I afford a new phone this month?'**
  String get askOwnHint;

  /// Ask AI period segment: the cycle Spends was showing, named as the cycle switcher names it
  ///
  /// In en, this message translates to:
  /// **'{cycle}'**
  String askPeriodThis(String cycle);

  /// Ask AI period segment: that cycle and the two before it, oldest to newest (Aug – Oct, or 12 Oct – 1 Nov)
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String askPeriodThree(String from, String to);

  /// Title of the Ask AI prompt preview
  ///
  /// In en, this message translates to:
  /// **'What the AI will see · {count, plural, =1{1 entry} other{{count} entries}}'**
  String askPreviewTitle(int count);

  /// Caption under the Ask AI preview title
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your phone until you share it.'**
  String get askPrivacyNote;

  /// Shown under the preview title when the prompt summarised old weeks to stay short
  ///
  /// In en, this message translates to:
  /// **'Older weeks are shown as totals to keep it short.'**
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
  /// **'Leave out my notes'**
  String get askHideNotes;

  /// Primary Ask AI action: copies the prompt and opens ChatGPT
  ///
  /// In en, this message translates to:
  /// **'Copy & open ChatGPT'**
  String get askOpenChatGpt;

  /// Ask AI action that opens the Android share sheet
  ///
  /// In en, this message translates to:
  /// **'Other apps'**
  String get askOtherAi;

  /// Ask AI action that only copies the prompt
  ///
  /// In en, this message translates to:
  /// **'Copy only'**
  String get askCopyOnly;

  /// Toast after Copy only, or when nothing could open ChatGPT, so the user must paste the prompt themselves
  ///
  /// In en, this message translates to:
  /// **'Copied. In the chat, long-press and tap Paste.'**
  String get askCopiedToast;

  /// Caption above the Ask AI actions when the prompt is too long to prefill ChatGPT
  ///
  /// In en, this message translates to:
  /// **'ChatGPT will open empty. Long-press the message box and tap Paste.'**
  String get askPasteNeeded;

  /// Title of the Ask AI card at the top of Spends; cycle is the cycle shown, such as October
  ///
  /// In en, this message translates to:
  /// **'Ask an AI about {cycle}'**
  String askAiCardTitle(String cycle);

  /// Second line of the Ask AI card on Spends: the prompt is previewed before it is shared
  ///
  /// In en, this message translates to:
  /// **'You\'ll see exactly what it gets.'**
  String get askAiCardNote;

  /// Wizard and bill sheet amount question for a bill that changes every month (D123).
  ///
  /// In en, this message translates to:
  /// **'About how much for {bill} each month?'**
  String billAmountQuestionVaries(String bill);

  /// Amount question for a credit card bill; {bill} is the card's name (D123).
  ///
  /// In en, this message translates to:
  /// **'About how much for {bill} each month?'**
  String billAmountQuestionCard(String bill);

  /// One line under a card bill's amount question and on its amount sheet: card buys are counted when made, so the bill isn't (D123).
  ///
  /// In en, this message translates to:
  /// **'Add what you buy on the card on the day you buy it. This bill only reminds you to pay. It isn\'t counted again.'**
  String get billCardHint;

  /// Bill sheet row label: whether the amount is fixed, changes, or is a card bill.
  ///
  /// In en, this message translates to:
  /// **'Kind of bill'**
  String get billModeRow;

  /// Bill sheet question title for the kind of bill (D123).
  ///
  /// In en, this message translates to:
  /// **'What kind of bill is it?'**
  String get billModeQuestion;

  /// Amount changes? answer: a fixed bill, posted by itself.
  ///
  /// In en, this message translates to:
  /// **'Same every month'**
  String get billModeFixed;

  /// Amount changes? answer: Home asks how much on its day.
  ///
  /// In en, this message translates to:
  /// **'Changes every month'**
  String get billModeVaries;

  /// Amount changes? answer: a card bill, recorded but never counted.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get billModeCard;

  /// Home line for a changing bill due today and not yet entered.
  ///
  /// In en, this message translates to:
  /// **'{bill} went out today. How much?'**
  String waitingVariesToday(String bill);

  /// Home line for a changing bill due earlier this cycle, not yet entered; {date} like 18 Nov.
  ///
  /// In en, this message translates to:
  /// **'{bill} went out on {date}. How much?'**
  String waitingVariesOn(String bill, String date);

  /// Home line for a card bill due today; {bill} is the card's name.
  ///
  /// In en, this message translates to:
  /// **'{bill} bill is due today. How much did you pay?'**
  String waitingCardToday(String bill);

  /// Home line for a card bill due earlier this cycle; {date} like 18 Nov.
  ///
  /// In en, this message translates to:
  /// **'{bill} bill was due on {date}. How much did you pay?'**
  String waitingCardOn(String bill, String date);

  /// TalkBack hint on the Home line for a waiting bill.
  ///
  /// In en, this message translates to:
  /// **'Opens the keypad.'**
  String get waitingOpensHint;

  /// Home due-soon nudge for a bill whose amount changes; mirrors billGoesOut.
  ///
  /// In en, this message translates to:
  /// **'{bill}, about {amount}, due {days, plural, =1{tomorrow} other{in {days} days}}'**
  String billGoesOutAbout(String bill, String amount, int days);

  /// Bill amount sheet title, e.g. Electricity · 18 Nov.
  ///
  /// In en, this message translates to:
  /// **'{bill} · {date}'**
  String billAmountTitle(String bill, String date);

  /// Bill amount sheet caption: the amount entered last time, prefilled.
  ///
  /// In en, this message translates to:
  /// **'Last time {amount}'**
  String billAmountLastTime(String amount);

  /// Bill amount sheet caption the first time: the estimate from setup, prefilled.
  ///
  /// In en, this message translates to:
  /// **'You said about {amount}'**
  String billAmountYourGuess(String amount);

  /// Bill amount sheet chip: skip this occurrence.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t go out this month'**
  String get billDidntGoOut;

  /// Snackbar after entering a bill's amount, with Undo.
  ///
  /// In en, this message translates to:
  /// **'{bill} {amount} added'**
  String billAmountAdded(String bill, String amount);

  /// Snackbar after Didn't go out this month, with Undo.
  ///
  /// In en, this message translates to:
  /// **'{bill} skipped this month'**
  String billSkipped(String bill);

  /// Line under a card bill's row: recorded, never counted (D123).
  ///
  /// In en, this message translates to:
  /// **'Paid, not counted again'**
  String get entryCardPaid;

  /// Due-day notification title for a changing bill, e.g. "Electricity went out today"; never an amount (spec §6)
  ///
  /// In en, this message translates to:
  /// **'{bill} went out today'**
  String reminderTitleVaries(String bill);

  /// Due-day notification title for a card bill, e.g. "Credit card bill is due today"
  ///
  /// In en, this message translates to:
  /// **'{bill} bill is due today'**
  String reminderTitleCard(String bill);

  /// Due-day notification text
  ///
  /// In en, this message translates to:
  /// **'Tap to add how much'**
  String get reminderText;

  /// Android notification channel name, shown in the system's notification settings
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get reminderChannel;

  /// Android notification channel description
  ///
  /// In en, this message translates to:
  /// **'On the day a changing bill or card bill is due'**
  String get reminderChannelDescription;

  /// Asked once, after the first changing or card bill is saved (spec §5)
  ///
  /// In en, this message translates to:
  /// **'Remind you on the day it\'s due?'**
  String get remindAskTitle;

  /// Yes to bill reminders; Android then asks for the permission
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindAskYes;

  /// No to bill reminders; never asked again
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get remindAskNo;

  /// Shown in the reminder ask after Android's permission is refused (E-i)
  ///
  /// In en, this message translates to:
  /// **'Reminders are off. Home still shows bills that need an amount.'**
  String get remindRefused;

  /// Settings row and income sheet eyebrow for the income (FR-SE-1, D137)
  ///
  /// In en, this message translates to:
  /// **'Money coming in'**
  String get moneyComingIn;

  /// Second line of the Money coming in row for a monthly payday
  ///
  /// In en, this message translates to:
  /// **'{amount} · on day {day}'**
  String incomeRowMonthly(String amount, int day);

  /// Second line of the Money coming in row when pay comes on the last day
  ///
  /// In en, this message translates to:
  /// **'{amount} · last day of the month'**
  String incomeRowLastDay(String amount);

  /// Second line of the Money coming in row for weekly pay; amount is the monthly figure, weekday a full name
  ///
  /// In en, this message translates to:
  /// **'{amount} · every {weekday}'**
  String incomeRowWeekly(String amount, String weekday);

  /// Second line of the Money coming in row for It changes (no fixed day)
  ///
  /// In en, this message translates to:
  /// **'Changes each month'**
  String get incomeRowIrregular;

  /// Line under the amount on the income slip, monthly payday
  ///
  /// In en, this message translates to:
  /// **'Comes every month on day {day}'**
  String incomeComesOnDay(int day);

  /// Line under the amount on the income slip, last-day payday
  ///
  /// In en, this message translates to:
  /// **'Comes on the last day of the month'**
  String get incomeComesLastDay;

  /// Line under the monthly amount on the income slip for weekly pay (D26)
  ///
  /// In en, this message translates to:
  /// **'Comes every {weekday}, about {amount} a week'**
  String incomeComesWeekly(String weekday, String amount);

  /// Row label on the income slip for the payday
  ///
  /// In en, this message translates to:
  /// **'When it comes'**
  String get incomeAnswerWhen;

  /// Value of the When it comes row for a monthly payday
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String incomeWhenDay(int day);

  /// Value of the When it comes row for a last-day payday
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get incomeWhenLastDay;

  /// Stamp on the income slip: the day the latest pay was added; date like 4 Oct
  ///
  /// In en, this message translates to:
  /// **'Came {date}'**
  String incomeStampCame(String date);

  /// Footer of the income slip; date like 4 Nov
  ///
  /// In en, this message translates to:
  /// **'Next payday {date}'**
  String incomeNextPayday(String date);

  /// When a new income amount counts; date is the next payday like 4 Nov (D137)
  ///
  /// In en, this message translates to:
  /// **'From payday, {date}.'**
  String incomeFromPayday(String date);

  /// Under From payday: the pay already added keeps its amount (D137)
  ///
  /// In en, this message translates to:
  /// **'{period, select, week{This week\'s} other{This month\'s}} {amount} stays as it came.'**
  String incomeStays(String period, String amount);

  /// Chip after a new income amount: also change the pay already added (D137)
  ///
  /// In en, this message translates to:
  /// **'{period, select, week{Change this week too} other{Change this month too}}'**
  String incomeChangeThisToo(String period);

  /// Footer after Change this month too, beside Undo
  ///
  /// In en, this message translates to:
  /// **'{period, select, week{This week\'s} other{This month\'s}} pay is now {amount}.'**
  String incomeNowIs(String period, String amount);

  /// Line on the income slip for It changes, under the title
  ///
  /// In en, this message translates to:
  /// **'Each month runs from the 1st'**
  String get incomeIrregularEvery;

  /// Footer of the income slip for It changes
  ///
  /// In en, this message translates to:
  /// **'Add money when it comes. Tap Add, then Got.'**
  String get incomeIrregularFoot;

  /// TalkBack for the income slip; when is the Comes… line
  ///
  /// In en, this message translates to:
  /// **'Money coming in, {amount}, {when}'**
  String incomeSlipSpoken(String amount, String when);

  /// Effect of a new payday before saving, and the footer after: the current cycle now ends on date, like 24 Nov (BR-1a, D140)
  ///
  /// In en, this message translates to:
  /// **'This money lasts till {date}.'**
  String incomeLastsTill(String date);

  /// Under incomeLastsTill: days left including today and today's share with the new payday (D140)
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{That\'s 1 day, about {amount} a day.} other{That\'s {days} days, about {amount} a day.}}'**
  String incomeLastsDays(int days, String amount);

  /// TalkBack for the When it comes row on the income slip
  ///
  /// In en, this message translates to:
  /// **'Change When it comes, {value}'**
  String incomeWhenSpoken(String value);

  /// Line on the amount question after picking a weekly payday for a new salary rule
  ///
  /// In en, this message translates to:
  /// **'Comes every {weekday}'**
  String incomeComesEvery(String weekday);

  /// Settings group heading for Back up, Restore and Delete everything (D139). 'Data' reads as the mobile internet pack, so the group names the user's money record
  ///
  /// In en, this message translates to:
  /// **'Your hisaab'**
  String get settingsYourHisaab;

  /// Settings row that opens the system Save screen to make a backup file
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backUpRow;

  /// Second line of the Back up row; date like 12 Oct
  ///
  /// In en, this message translates to:
  /// **'Last backed up {date}'**
  String backUpLast(String date);

  /// Second line of the Back up row when the last backup was today
  ///
  /// In en, this message translates to:
  /// **'Backed up today'**
  String get backUpToday;

  /// Second line of the Back up row when no backup was made on this phone
  ///
  /// In en, this message translates to:
  /// **'Not backed up yet'**
  String get backUpNever;

  /// Second line of the Back up row while the file is written
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get backUpBusy;

  /// Note under the Back up and Restore rows
  ///
  /// In en, this message translates to:
  /// **'The backup file has no password. Anyone who has it can read your entries and notes, so keep it safe.'**
  String get backUpNoLock;

  /// Snackbar after the backup file is written; fileName like hisaab-backup-2026-11-06.json
  ///
  /// In en, this message translates to:
  /// **'Backed up as {fileName}'**
  String backUpDone(String fileName);

  /// Snackbar after the backup file is written, when the picker gives no file name
  ///
  /// In en, this message translates to:
  /// **'Backed up'**
  String get backUpDoneNoName;

  /// Snackbar when writing the backup file fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t back up there. Try another folder.'**
  String get backUpFailed;

  /// Snackbar when hisaab can't read its own data to make the file
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make the backup. Nothing changed. Try again.'**
  String get backUpReadFailed;

  /// Settings row that opens the file picker to bring back a backup file
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreRow;

  /// Second line of the Restore row
  ///
  /// In en, this message translates to:
  /// **'Bring back from a backup file'**
  String get restoreRowHint;

  /// Second line of the Restore row while the picked file is read and checked
  ///
  /// In en, this message translates to:
  /// **'Checking the backup…'**
  String get restoreChecking;

  /// Settings row, for 7 days after a restore, that puts back what was there before
  ///
  /// In en, this message translates to:
  /// **'Undo restore'**
  String get restoreRevertRow;

  /// Second line of the Undo restore row; date is the restore day like 6 Nov
  ///
  /// In en, this message translates to:
  /// **'Go back to what you had before {date}'**
  String restoreRevertHint(String date);

  /// Second line of the Undo restore row when entries were added after the restore (E42)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The 1 entry added since will go.} other{The {count} entries added since will go.}}'**
  String restoreRevertLoses(int count);

  /// Snackbar when the picked file isn't a hisaab backup
  ///
  /// In en, this message translates to:
  /// **'That\'s not a hisaab backup. Pick a file whose name starts with hisaab-backup.'**
  String get restoreNotBackup;

  /// Snackbar when the file is a hisaab backup but parts are missing or broken
  ///
  /// In en, this message translates to:
  /// **'This backup can\'t be opened. It may be cut short. Try another copy.'**
  String get restoreBroken;

  /// Snackbar when the backup was made by a newer version; nothing is changed
  ///
  /// In en, this message translates to:
  /// **'This backup is from a newer hisaab. Update hisaab from Play Store, then try again.'**
  String get restoreNewer;

  /// Snackbar when the picked file can't be read at all
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that file. Try again or pick another.'**
  String get restoreOpenFailed;

  /// Title of the restore dialog, the app's only confirmation dialog (BR-16)
  ///
  /// In en, this message translates to:
  /// **'Replace with this backup?'**
  String get restoreConfirmTitle;

  /// Restore dialog line 1: when the backup was made and how many entries it holds; date like 12 Oct
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Made on {date}, with no entries.} =1{Made on {date}, with 1 entry.} other{Made on {date}, with {count} entries.}}'**
  String restoreConfirmFrom(int count, String date);

  /// Restore dialog line 2: what is on this phone now
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{It replaces everything on this phone now. You can undo right after.} =1{It replaces everything on this phone now, including 1 entry. You can undo right after.} other{It replaces everything on this phone now, including {count} entries. You can undo right after.}}'**
  String restoreConfirmReplaces(int count);

  /// Restore dialog key that restores the backup
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get restoreConfirmYes;

  /// Restore dialog key that closes it and changes nothing
  ///
  /// In en, this message translates to:
  /// **'Keep what\'s here'**
  String get restoreConfirmNo;

  /// Shown in the restore dialog while the restore runs
  ///
  /// In en, this message translates to:
  /// **'Bringing back your hisaab…'**
  String get restoreWorking;

  /// Snackbar after a restore, with Undo; date like 12 Oct
  ///
  /// In en, this message translates to:
  /// **'Backup from {date} restored'**
  String restoreDone(String date);

  /// Snackbar after Undo on a restore
  ///
  /// In en, this message translates to:
  /// **'Back to what you had before'**
  String get restoreUndone;

  /// Snackbar when the restore stops part way and is rolled back
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore. Nothing changed. Try again.'**
  String get restoreFailed;

  /// Snackbar when Undo of a restore fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t go back. The backup is still in use.'**
  String get restoreUndoFailed;

  /// Text chip on the first onboarding screen for someone moving from another phone
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get restoreLink;

  /// TalkBack label for the onboarding Restore a backup chip
  ///
  /// In en, this message translates to:
  /// **'Restore a backup from another phone'**
  String get restoreLinkSpoken;

  /// Settings row that opens the Delete everything page
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteAllRow;

  /// Second line of the Delete everything row
  ///
  /// In en, this message translates to:
  /// **'Clear it all and start again'**
  String get deleteAllRowHint;

  /// Title of the Delete everything page
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteAllTitle;

  /// First sentence on the Delete everything page
  ///
  /// In en, this message translates to:
  /// **'This clears hisaab on this phone. It opens again at the first step, like new.'**
  String get deleteAllLead;

  /// Heading over the list of what is deleted
  ///
  /// In en, this message translates to:
  /// **'This goes:'**
  String get deleteAllListTitle;

  /// Delete everything list item
  ///
  /// In en, this message translates to:
  /// **'Every entry you added'**
  String get deleteAllItemEntries;

  /// Delete everything list item: the income
  ///
  /// In en, this message translates to:
  /// **'Money coming in'**
  String get deleteAllItemIncome;

  /// Delete everything list item
  ///
  /// In en, this message translates to:
  /// **'Bills and their reminders'**
  String get deleteAllItemBills;

  /// Delete everything list item
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get deleteAllItemSavings;

  /// Delete everything list item; the built-in categories come back as new
  ///
  /// In en, this message translates to:
  /// **'Categories you added or changed'**
  String get deleteAllItemCategories;

  /// Delete everything list item
  ///
  /// In en, this message translates to:
  /// **'Look and your other settings'**
  String get deleteAllItemSettings;

  /// Line after the list of what is deleted
  ///
  /// In en, this message translates to:
  /// **'Once it\'s deleted, there\'s no getting it back.'**
  String get deleteAllNoUndo;

  /// Line saying backup files are not touched
  ///
  /// In en, this message translates to:
  /// **'Backup files you made stay where you put them.'**
  String get deleteAllStays;

  /// Line that answers the fear of wiping the phone
  ///
  /// In en, this message translates to:
  /// **'Only hisaab is cleared. Your phone and other apps stay as they are.'**
  String get deleteAllPhoneSafe;

  /// Last-backup line on the Delete everything page when there is no backup
  ///
  /// In en, this message translates to:
  /// **'Not backed up yet. Back up first to keep a copy.'**
  String get deleteAllNoBackup;

  /// Key on the Delete everything page that makes a backup and comes back
  ///
  /// In en, this message translates to:
  /// **'Back up first'**
  String get deleteAllBackUpFirst;

  /// Label on the hold key; it fills while pressed, and when let go full it counts down 5 s with Undo, then deletes
  ///
  /// In en, this message translates to:
  /// **'Hold to delete everything'**
  String get deleteAllHold;

  /// Label on the hold key once it is full
  ///
  /// In en, this message translates to:
  /// **'Let go to delete'**
  String get deleteAllHoldFull;

  /// Caption under the hold key at rest; names no duration, the fill shows it (D149)
  ///
  /// In en, this message translates to:
  /// **'Press and hold to delete.'**
  String get deleteAllHoldCaption;

  /// Caption after the hold key is let go early; nothing was deleted
  ///
  /// In en, this message translates to:
  /// **'Keep holding till it fills up.'**
  String get deleteAllHoldShort;

  /// TalkBack label for the hold key
  ///
  /// In en, this message translates to:
  /// **'Delete everything in hisaab'**
  String get deleteAllHoldSpoken;

  /// Hold key label for TalkBack and switch users after the first activation; a second within 10 s deletes
  ///
  /// In en, this message translates to:
  /// **'Double-tap again to delete everything'**
  String get deleteAllHoldArmed;

  /// TalkBack hint on the hold key
  ///
  /// In en, this message translates to:
  /// **'Double-tap twice to delete'**
  String get deleteAllHoldHint;

  /// Label on the hold key while its fill drains back for 5 s after a full hold; a tap stops the delete
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get deleteAllUndo;

  /// Caption under the hold key while it counts down to the delete; it counts down each second
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Deleting in 1 second. Tap Undo to stop.} other{Deleting in {seconds} seconds. Tap Undo to stop.}}'**
  String deleteAllUndoCaption(int seconds);

  /// TalkBack label for the hold key while it counts down to the delete
  ///
  /// In en, this message translates to:
  /// **'Undo. Keep everything'**
  String get deleteAllUndoSpoken;

  /// TalkBack announcement when the countdown to the delete starts
  ///
  /// In en, this message translates to:
  /// **'Deleting everything in {seconds} seconds. Double-tap to undo.'**
  String deleteAllUndoAnnounced(int seconds);

  /// Caption under the hold key after Undo stopped the delete
  ///
  /// In en, this message translates to:
  /// **'Stopped. Nothing was deleted.'**
  String get deleteAllUndone;

  /// Hold key label while everything is deleted
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleteAllWorking;

  /// TalkBack announcement as the app lands on onboarding after deleting
  ///
  /// In en, this message translates to:
  /// **'Everything deleted. hisaab is starting again.'**
  String get deleteAllDoneSpoken;

  /// Snackbar when the delete fails and is rolled back
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete. Nothing changed. Try again.'**
  String get deleteAllFailed;

  /// The dashed tile after the categories that makes a new one (FR-AD-9)
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCategoryTile;

  /// TalkBack label of the New tile
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// Small label over the row of the user's own categories in the Add tray
  ///
  /// In en, this message translates to:
  /// **'Your own'**
  String get ownCategoriesRule;

  /// Replaces the New tile when 4 of the user's own are shown (D138)
  ///
  /// In en, this message translates to:
  /// **'4 of your own is the most. Hide one in Settings to make room.'**
  String get ownCategoriesFull;

  /// Under the amount on the new-category name step
  ///
  /// In en, this message translates to:
  /// **'What\'s it called?'**
  String get newCategoryQuestion;

  /// Hint in the empty new-category name field
  ///
  /// In en, this message translates to:
  /// **'Petrol, kids, gym…'**
  String get newCategoryHint;

  /// TalkBack label of the name field
  ///
  /// In en, this message translates to:
  /// **'Name for the new category'**
  String get newCategoryFieldLabel;

  /// Icon line when the icon follows the name
  ///
  /// In en, this message translates to:
  /// **'Icon from the name: {icon}'**
  String categoryIconFromName(String icon);

  /// Icon line after the user picked an icon
  ///
  /// In en, this message translates to:
  /// **'Icon: {icon}'**
  String categoryIconPicked(String icon);

  /// Icon line when nothing in the name matches an icon
  ///
  /// In en, this message translates to:
  /// **'Icon: Tag. No match yet'**
  String get categoryIconNoMatch;

  /// Icon line while the name is empty
  ///
  /// In en, this message translates to:
  /// **'The name picks an icon'**
  String get categoryIconWaiting;

  /// Link at the end of the icon line; opens the icon step
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeIcon;

  /// TalkBack for the icon line
  ///
  /// In en, this message translates to:
  /// **'Icon, {icon}. Double tap to change'**
  String categoryIconSemantics(String icon);

  /// When the typed name matches a shown category
  ///
  /// In en, this message translates to:
  /// **'You have {name} already. It saves there.'**
  String categoryExists(String name);

  /// When the typed name matches a hidden category
  ///
  /// In en, this message translates to:
  /// **'You hid {name}. Saving brings it back.'**
  String categoryComesBack(String name);

  /// The marigold key on the name step
  ///
  /// In en, this message translates to:
  /// **'Save in {name}'**
  String saveInCategory(String name);

  /// Under the amount on the icon step
  ///
  /// In en, this message translates to:
  /// **'Pick an icon for {name}'**
  String pickIconFor(String name);

  /// Line on the icon step saying which icon the name suggests
  ///
  /// In en, this message translates to:
  /// **'From the name: {icon}'**
  String categoryIconFromNameShort(String icon);

  /// The word under a curated category icon, by its app-owned key (D138)
  ///
  /// In en, this message translates to:
  /// **'{key, select, groceries{Groceries} vegetables{Vegetables} fruit{Fruit} milk{Milk} chai{Chai} coffee{Coffee} snacks{Snacks} eating_out{Eating out} cigarettes{Cigarettes} beer{Beer} cold_drink{Cold drink} drinks{Drinks} sweets{Sweets} gaming{Gaming} cards{Cards} lottery{Lottery} paan{Paan} hookah{Hookah} fuel{Fuel} auto{Auto} cab{Cab} bike{Bike} car{Car} metro{Metro} train{Train} parking{Parking} trip{Trip} kids{Kids} school{School} family{Family} pet{Pet} cleaning{Cleaning} laundry{Laundry} repair{Repair} plants{Plants} medicine{Medicine} gym{Gym} yoga{Yoga} salon{Salon} prayer{Prayer} giving{Giving} gift{Gift} wedding{Wedding} clothes{Clothes} shoes{Shoes} jewellery{Jewellery} phone{Phone} recharge{Recharge} movies{Movies} books{Books} other{Tag}}'**
  String categoryIconName(String key);

  /// Heading of a group on the icon step
  ///
  /// In en, this message translates to:
  /// **'{group, select, food{Food and drink} habits{Treats and habits} around{Getting around} home{Home and family} care{Care and giving} other{Things and fun}}'**
  String categoryIconGroup(String group);

  /// A name chip on the new-category name step
  ///
  /// In en, this message translates to:
  /// **'{key, select, groceries{Groceries} kids{Kids} family{Family} pets{Pets} petrol{Petrol} other{Salon}}'**
  String newCategorySuggestion(String key);

  /// Settings group heading, row and page title (FR-SE-2)
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// Beside the Your own heading: how many of the user's own are shown
  ///
  /// In en, this message translates to:
  /// **'{count} of {max}'**
  String categoriesOwnCount(int count, int max);

  /// Row under the user's own categories in Settings
  ///
  /// In en, this message translates to:
  /// **'Add a category'**
  String get addCategory;

  /// Heading over the 8 built-in Spent categories in Settings
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get categoriesSpending;

  /// Hint under the Spending heading
  ///
  /// In en, this message translates to:
  /// **'These 8 keep their places. Rename one or change its icon.'**
  String get categoriesSpendingHint;

  /// Heading over the Got categories in Settings
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get categoriesMoneyIn;

  /// Eyebrow on a built-in category's sheet
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get categoryBuiltIn;

  /// Row on the category sheet
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryNameRow;

  /// Row on the category sheet
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIconRow;

  /// Key on the sheet of one of the user's own categories
  ///
  /// In en, this message translates to:
  /// **'Hide {name}'**
  String hideCategory(String name);

  /// Under the Hide key
  ///
  /// In en, this message translates to:
  /// **'Its entries stay in Spends. It leaves the Add tray.'**
  String get hideCategoryNote;

  /// On a renamed built-in category's sheet
  ///
  /// In en, this message translates to:
  /// **'Built in as {name}. The new name shows on its past entries too.'**
  String builtInRenamedNote(String name);

  /// On a built-in category's sheet
  ///
  /// In en, this message translates to:
  /// **'Built in. You can rename it or change its icon. It always keeps its place.'**
  String get builtInNote;

  /// Snackbar after hiding a category, with Undo
  ///
  /// In en, this message translates to:
  /// **'{name} hidden'**
  String categoryHidden(String name);

  /// Question when renaming a category
  ///
  /// In en, this message translates to:
  /// **'What should it be called?'**
  String get renameCategoryQuestion;

  /// Key when adding a category in Settings
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String addCategoryKey(String name);

  /// Key when the typed name is a hidden category
  ///
  /// In en, this message translates to:
  /// **'Bring back {name}'**
  String bringBackCategory(String name);

  /// Under the name field when the name is taken
  ///
  /// In en, this message translates to:
  /// **'Another category is already called that.'**
  String get categoryNameTaken;

  /// Under the name field when the name can't be used
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 16 letters, and not Savings or Card bill.'**
  String get categoryNameInvalid;

  /// Second line of a renamed built-in category in Settings
  ///
  /// In en, this message translates to:
  /// **'Built in as {name}'**
  String builtInAs(String name);

  /// Ends the Add tray's pill after the separator, e.g. "Chai ₹20 · your usual" (FR-AD-10)
  ///
  /// In en, this message translates to:
  /// **'your usual'**
  String get usualTag;

  /// Screen-reader label of the your usual pill; amount is the spoken form, e.g. 20 rupees
  ///
  /// In en, this message translates to:
  /// **'Add {category}, {amount}, your usual'**
  String usualSuggestionSpoken(String category, String amount);

  /// Snackbar after a one-tap add from the your usual pill, with Undo, e.g. "Added ₹20 to Chai"
  ///
  /// In en, this message translates to:
  /// **'Added {amount} to {category}'**
  String usualAdded(String amount, String category);

  /// Title of the row in a category's sheet that says what habit was worked out (FR-SE-2 AC-6)
  ///
  /// In en, this message translates to:
  /// **'Your usual'**
  String get usualRowTitle;

  /// Second line of the Your usual row, e.g. "₹20, weekdays around 10 am"; days is weekdays, weekends or all, time is the hour as the locale writes it
  ///
  /// In en, this message translates to:
  /// **'{amount}, {days, select, weekdays{weekdays around} weekends{weekends around} other{around}} {time}'**
  String usualRowDetail(String amount, String days, String time);

  /// Text button on the Your usual row; clears the habit and rests it for 30 days (FR-SE-2 AC-6)
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get usualForget;

  /// Screen-reader label of the Forget button
  ///
  /// In en, this message translates to:
  /// **'Forget your usual {category}'**
  String usualForgetSpoken(String category);

  /// Snackbar inside the category sheet after Forget, with Undo
  ///
  /// In en, this message translates to:
  /// **'Forgotten'**
  String get usualForgotten;

  /// Note under the Your usual row: the habit never leaves the device
  ///
  /// In en, this message translates to:
  /// **'Worked out on this phone from what you add.'**
  String get usualHow;

  /// Home-screen widget, 2×1: under the amount, where the title doesn't fit (FR-WG-1)
  ///
  /// In en, this message translates to:
  /// **'left today'**
  String get widgetLeftToday;

  /// Screen-reader label of the widget's marigold Add key (FR-WG-8)
  ///
  /// In en, this message translates to:
  /// **'Add a spend'**
  String get widgetAddSpoken;

  /// Key on the widget when hisaab has no income yet; opens hisaab (FR-WG-3)
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get widgetSetUp;

  /// Widget text when hisaab has no income yet (FR-WG-3)
  ///
  /// In en, this message translates to:
  /// **'Set up hisaab to see what\'s safe to spend today.'**
  String get widgetSetUpBody;

  /// Widget text when the app hasn't been opened for longer than the widget's days reach (E53). Mirrored in android res/values/strings.xml as widget_stale
  ///
  /// In en, this message translates to:
  /// **'Open hisaab to update'**
  String get widgetStale;

  /// Widget, 2×2: days left in the cycle, today included (FR-WG-1)
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}}'**
  String widgetDaysLeft(int days);

  /// Widget, 4×2: days left, next to the range line (FR-WG-1)
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String widgetDays(int days);

  /// The widget's name in the launcher's widget list. Mirrored in android strings.xml as widget_name
  ///
  /// In en, this message translates to:
  /// **'hisaab'**
  String get widgetName;

  /// The widget's description in the launcher's widget list. Mirrored in android strings.xml as widget_description
  ///
  /// In en, this message translates to:
  /// **'What\'s safe to spend today, and an Add key'**
  String get widgetDescription;

  /// Quick Settings tile label; it opens the Add tray at the keypad (FR-WG-6). Mirrored in android strings.xml as tile_add_spend
  ///
  /// In en, this message translates to:
  /// **'Add a spend'**
  String get tileAddSpend;

  /// Launcher-icon shortcut; it opens the Add tray at the keypad (FR-WG-7). Mirrored in android strings.xml as shortcut_add_spend
  ///
  /// In en, this message translates to:
  /// **'Add a spend'**
  String get shortcutAddSpend;

  /// Settings group heading for the widget and the tile (FR-SE-6)
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get settingsShortcuts;

  /// Settings row; opens the launcher's own add-widget dialog (FR-SE-6 AC-1)
  ///
  /// In en, this message translates to:
  /// **'Add a widget'**
  String get settingsAddWidget;

  /// Second line of the Add a widget row
  ///
  /// In en, this message translates to:
  /// **'See what\'s safe to spend from your home screen'**
  String get settingsAddWidgetHint;

  /// Settings row; opens Android's own add-tile dialog (FR-SE-6 AC-2)
  ///
  /// In en, this message translates to:
  /// **'Add to quick settings'**
  String get settingsAddTile;

  /// Second line of the Add to quick settings row
  ///
  /// In en, this message translates to:
  /// **'Add a spend from the pull-down'**
  String get settingsAddTileHint;

  /// Third line of a saving's row in the Savings list, and under the amount on its sheet: money put in and not yet used (BR-19). Only above zero. Never 'balance' or 'worth'.
  ///
  /// In en, this message translates to:
  /// **'{amount} set aside'**
  String savingSetAside(String amount);

  /// Second line of the Savings list footer: what is set aside across the active savings, or the zero form after a full use (AC-Y4). left is whole rupees, amount its text.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =0{Nothing is set aside now.} other{{amount} still set aside}}'**
  String savingsStillSetAside(int left, String amount);

  /// Outlined key on a saving's sheet; opens the keypad that says how much of the set-aside money was used (AC-Y5)
  ///
  /// In en, this message translates to:
  /// **'Used some of it'**
  String get savingUsedAction;

  /// Line above the Used some of it key, on the three yearly-cost savings only (AC-Y5)
  ///
  /// In en, this message translates to:
  /// **'Paid the cost from this? Tap Used some of it.'**
  String get savingUsedHint;

  /// Title of the Used keypad (AC-Y6)
  ///
  /// In en, this message translates to:
  /// **'How much did you use from {saving}?'**
  String savingUsedQuestion(String saving);

  /// Chip beside the amount on the Used keypad: fills everything that is set aside; a second tap clears it (AC-Y6)
  ///
  /// In en, this message translates to:
  /// **'All of it'**
  String get savingUsedAll;

  /// Line 1 of the Used keypad's slot before a digit is typed (AC-Y7)
  ///
  /// In en, this message translates to:
  /// **'{amount} is set aside.'**
  String savingUsedSetAside(String amount);

  /// Line 1 of the Used keypad's slot while digits are typed: what stays set aside (AC-Y7). left is whole rupees, amount its text.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =0{Nothing will be set aside.} other{{amount} will still be set aside.}}'**
  String savingUsedLeft(int left, String amount);

  /// Line 2 of the Used keypad's slot, always: using money you set aside moves no number (AC-Y7)
  ///
  /// In en, this message translates to:
  /// **'Your daily number doesn\'t change.'**
  String get savingUsedSame;

  /// Replaces line 1 of the Used slot when a digit past what is set aside is refused (AC-Y8)
  ///
  /// In en, this message translates to:
  /// **'That\'s all you have set aside. Add the rest as a spend.'**
  String get savingUsedCap;

  /// The Used slot when what was set aside fell to zero behind the sheet; Save is off (AC-Y8)
  ///
  /// In en, this message translates to:
  /// **'Nothing is set aside to use.'**
  String get savingUsedNothing;

  /// Screen-reader hint on a disabled Save key of the Used keypad; spoken only, never shown
  ///
  /// In en, this message translates to:
  /// **'Type an amount first.'**
  String get typeAmountFirst;

  /// Under the amount question for the Insurance, School fees and Festival savings only (AC-Y2)
  ///
  /// In en, this message translates to:
  /// **'Paid once a year? Each month, put in the cost divided by 12.'**
  String get savingYearlyCaption;

  /// Second sentence under the yearly-cost caption (AC-Y2)
  ///
  /// In en, this message translates to:
  /// **'When you pay it, tap Used some of it.'**
  String get savingYearlyUsedHint;

  /// Snackbar after Used some of it is saved, with Undo; the saving's name first (AC-Y9)
  ///
  /// In en, this message translates to:
  /// **'{saving}: {amount} used'**
  String savingUsedDone(String saving, String amount);

  /// Snackbar after deleting a saving that has had a put-in (AC-Y10)
  ///
  /// In en, this message translates to:
  /// **'{saving} deleted. What you put in stays in your history.'**
  String savingDeletedKeeps(String saving);

  /// Second line of a Used row: a cost paid from a saving (BR-19, D187)
  ///
  /// In en, this message translates to:
  /// **'Used from savings'**
  String get entryUsed;

  /// Screen-reader label of a Used row; amount is spoken, e.g. 4,000 rupees
  ///
  /// In en, this message translates to:
  /// **'{saving}. Used from savings {amount}.'**
  String entryUsedSpoken(String saving, String amount);

  /// Extra line under a Used row in Every entry (FR-SP-6)
  ///
  /// In en, this message translates to:
  /// **'Paid from what you set aside.'**
  String get entryUsedDetail;

  /// Line 1 of Home's missed-log line, asked once a day after a habit's usual time (FR-HO-3, D171)
  ///
  /// In en, this message translates to:
  /// **'Spent on {category} today?'**
  String missedLogTitle(String category);

  /// Line 2 of Home's missed-log line; time is the hour as the locale writes it, e.g. 1 pm
  ///
  /// In en, this message translates to:
  /// **'Usually around {time}.'**
  String missedLogBody(String time);

  /// A door's label everywhere: Home's foot row, Settings' row title and the install line's second line (FR-FX-1)
  ///
  /// In en, this message translates to:
  /// **'Fix my number'**
  String get fixMyNumber;

  /// Settings row second line, under Fix my number: says when to use it
  ///
  /// In en, this message translates to:
  /// **'When the number on Home looks wrong.'**
  String get fixSettingsDetail;

  /// First line of the one-time Home line for a mid-cycle install; the second line is Fix my number (FR-HO-3)
  ///
  /// In en, this message translates to:
  /// **'Already spent some {period, select, week{this week} other{this month}}?'**
  String fixInstallTitle(String period);

  /// Fix my number sheet title: the one question, scoped to this cycle's money (FR-FX-2)
  ///
  /// In en, this message translates to:
  /// **'How much of {period, select, week{this week\'s} other{this month\'s}} money is left?'**
  String fixTitle(String period);

  /// The sheet's helper line before the first digit: what to count and what to leave out (FR-FX-2)
  ///
  /// In en, this message translates to:
  /// **'Bank and cash together. Leave out money from before {period, select, week{this week} other{this month}}.'**
  String fixHelper(String period);

  /// Line 1 of the preview after the first key: what hisaab expected, shown after typing so the user is not anchored
  ///
  /// In en, this message translates to:
  /// **'hisaab thought {amount}.'**
  String fixPreviewBase(String amount);

  /// Line 1 of the preview when hisaab's figure is exactly zero (D181)
  ///
  /// In en, this message translates to:
  /// **'hisaab thought nothing was left.'**
  String get fixPreviewBaseNothing;

  /// Line 1 of the preview when hisaab's figure is below zero: the month was already overspent; amount is how much below (D181)
  ///
  /// In en, this message translates to:
  /// **'hisaab thought you were {amount} short.'**
  String fixPreviewBaseShort(String amount);

  /// Line 2 of the preview when money is missing: the gap and the per-day effect
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} less. {perDay, plural, =0{Each day stays about the same.} other{Each day gets about {perDayAmount} less.}}'**
  String fixPreviewLess(String gap, int perDay, String perDayAmount);

  /// Line 2 of the preview when hisaab under-counted: the gap and the per-day effect
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} more. {perDay, plural, =0{Each day stays about the same.} other{Each day gets about {perDayAmount} more.}}'**
  String fixPreviewMore(String gap, int perDay, String perDayAmount);

  /// Line 2 when the answer leaves less than the bills and savings still to come; informs, never blocks
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} less, and {short} short of what\'s still due.'**
  String fixPreviewLessShort(String gap, String short);

  /// Line 2 on the cycle's last day: the whole gap comes off today
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} less. Today takes all of it.'**
  String fixPreviewLessLastDay(String gap);

  /// Line 2 on the cycle's last day: the whole gap goes to today
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} more. Today gets all of it.'**
  String fixPreviewMoreLastDay(String gap);

  /// Line 2 when the lower share falls below what was already spent today (D190); informs, never blocks
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} less. Today is {over} over its share.'**
  String fixPreviewLessOverToday(String gap, String over);

  /// Line 2 when the typed figure equals hisaab's; Fix it is off
  ///
  /// In en, this message translates to:
  /// **'That matches. Nothing to fix.'**
  String get fixPreviewEqual;

  /// Line 2 when a rounded answer is within 50 rupees of hisaab's figure; Fix it is off
  ///
  /// In en, this message translates to:
  /// **'That\'s close enough. Nothing to fix.'**
  String get fixPreviewClose;

  /// Line 2 when a large higher gap will ask a question first; the keypad is still on screen
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} more. One question first.'**
  String fixPreviewBig(String gap);

  /// Short text a screen reader speaks for a lower, short or over-today preview; the full sentence stays the focusable text
  ///
  /// In en, this message translates to:
  /// **'{gap} less.'**
  String fixLiveLess(String gap);

  /// Short text a screen reader speaks for a higher preview
  ///
  /// In en, this message translates to:
  /// **'{gap} more.'**
  String fixLiveMore(String gap);

  /// The full-width key under the keypad that posts one Not logged entry for the gap
  ///
  /// In en, this message translates to:
  /// **'Fix it'**
  String get fixAction;

  /// Screen-reader hint on a disabled Fix it when the figures match or are close; spoken only, never shown
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix.'**
  String get fixActionHintNothing;

  /// Announced only if the write takes over a second; never shown
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get fixSavingSpoken;

  /// Shown in the preview slot when hisaab's figure could not be read, with Try again
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check your number.'**
  String get fixLoadFailed;

  /// Replaces line 1 when the save was refused because the ledger moved behind the sheet
  ///
  /// In en, this message translates to:
  /// **'Things changed. Check the new amount.'**
  String get fixNoticeChanged;

  /// Slot line 2 once the guard panel replaces the keypad: asks before a large Got is posted
  ///
  /// In en, this message translates to:
  /// **'That\'s {gap} more. Is all of it from {period, select, week{this week} other{this month}}?'**
  String fixGuardQuestion(String gap, String period);

  /// First guard key: back to the keypad with the digits cleared
  ///
  /// In en, this message translates to:
  /// **'No, some is older'**
  String get fixGuardNo;

  /// Second guard key: posts a Got entry for the gap
  ///
  /// In en, this message translates to:
  /// **'Yes, add {gap}'**
  String fixGuardYes(String gap);

  /// Notice over the cleared amount after the guard's No, until the first key
  ///
  /// In en, this message translates to:
  /// **'Count only {period, select, week{this week\'s} other{this month\'s}} money.'**
  String fixNoticeCountOnly(String period);

  /// Snackbar after Fix it, with Undo: repeats the hero's own title so the user links it to the number that just changed
  ///
  /// In en, this message translates to:
  /// **'Fixed. Safe to spend today: {amount}.'**
  String fixDone(String amount);

  /// Announced politely after Undo of a fix; never shown
  ///
  /// In en, this message translates to:
  /// **'Undone.'**
  String get undone;

  /// Title of a Fix my number entry's row, both directions (BR-18)
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get entryNotLogged;

  /// Second line of a Not logged row: its direction as a word, never a colour or sign
  ///
  /// In en, this message translates to:
  /// **'{direction, select, got{Got} other{Spent}}'**
  String notLoggedRow(String direction);

  /// Screen-reader sentence for a Not logged row
  ///
  /// In en, this message translates to:
  /// **'Not logged. {direction, select, got{Got} other{Spent}} {amount}.'**
  String notLoggedRowSpoken(String direction, String amount);

  /// Extra line on a Not logged row in Every entry; answers who put it there
  ///
  /// In en, this message translates to:
  /// **'Added when you fixed your number.'**
  String get notLoggedDetail;

  /// First part of the Spends line: what was spent, leaving out Not logged and Saved
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String spendsPartSpent(String amount);

  /// Second part of the Spends line: money put into savings
  ///
  /// In en, this message translates to:
  /// **'Saved {amount}'**
  String spendsPartSaved(String amount);

  /// Third part of the Spends line: the Spent side of Fix my number entries
  ///
  /// In en, this message translates to:
  /// **'Not logged {amount}'**
  String spendsPartNotLogged(String amount);

  /// Screen-reader form of the Not logged part of the Spends line
  ///
  /// In en, this message translates to:
  /// **'Not logged, spent {amount}'**
  String spendsPartNotLoggedSpoken(String amount);

  /// Month story card and page 1 eyebrow (FR-SP-7, BR-20)
  ///
  /// In en, this message translates to:
  /// **'Your month'**
  String get storyCardEyebrow;

  /// Month story headline when money was left after spending and saving (BR-20 page 2)
  ///
  /// In en, this message translates to:
  /// **'{amount} left over'**
  String storyLeftOver(String amount);

  /// Month story headline when spending and saving went past the money that came in (BR-20). Never say income or earned.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than came in'**
  String storyMoreThanCameIn(String amount);

  /// Month story card headline when nothing came in that cycle (E118)
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String storySpentOnly(String amount);

  /// Month story card action (FR-SP-7 AC-1)
  ///
  /// In en, this message translates to:
  /// **'See the story'**
  String get storyCardAction;

  /// Screen-reader label of the month story card; headline uses spoken amounts
  ///
  /// In en, this message translates to:
  /// **'Your {cycle} story. {headline}.'**
  String storyCardSpoken(String cycle, String headline);

  /// Bold first part of the slim row on days 1 to 7 of a new cycle (FR-SP-7 AC-2)
  ///
  /// In en, this message translates to:
  /// **'{cycle} is done.'**
  String storyRowDone(String cycle);

  /// Second part of the slim row; opens the month story
  ///
  /// In en, this message translates to:
  /// **'See your month'**
  String get storyRowAction;

  /// Top of each month story page: the cycle and which page this is
  ///
  /// In en, this message translates to:
  /// **'{cycle} · {page} of {total}'**
  String storyProgress(String cycle, int page, int total);

  /// Month story: the right tap zone, a button for screen readers and switch access (AC-3)
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get storyNextPage;

  /// Month story: the left tap zone, a button for screen readers and switch access (AC-3)
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get storyPreviousPage;

  /// Page 1: the cycle's first and last days and how many days it had
  ///
  /// In en, this message translates to:
  /// **'{first} – {last} · {days} days'**
  String storyMonthSpan(String first, String last, int days);

  /// Page 1: how many entries the cycle holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String storyMonthEntries(int count);

  /// Page 1 hint under the preview; hidden from screen readers
  ///
  /// In en, this message translates to:
  /// **'Tap to go on'**
  String get storyTapHint;

  /// Page 2 eyebrow above the spent amount
  ///
  /// In en, this message translates to:
  /// **'You spent'**
  String get storyKeptEyebrow;

  /// Page 2 line under the spent amount
  ///
  /// In en, this message translates to:
  /// **'of {amount} that came in'**
  String storyKeptOf(String amount);

  /// Page 2 and card line under the headline when something was saved
  ///
  /// In en, this message translates to:
  /// **'and {amount} saved'**
  String storySavedLine(String amount);

  /// Split bar key: spending posted by a bill rule
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get storyKeyBills;

  /// Split bar key: all spending except bills
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get storyKeyEveryday;

  /// Split bar key: money added by Fix my number
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get storyKeyNotLogged;

  /// Split bar key and page 6 row: money put into savings
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get storyKeySaved;

  /// Split bar key and page 6 row: money left after the cycle
  ///
  /// In en, this message translates to:
  /// **'Left over'**
  String get storyKeyLeftOver;

  /// Split bar key and page 6 row when spending went past what came in
  ///
  /// In en, this message translates to:
  /// **'More than came in'**
  String get storyKeyMoreThanCameIn;

  /// Page 3 eyebrow
  ///
  /// In en, this message translates to:
  /// **'Where it went'**
  String get storyWhereEyebrow;

  /// Page 3 headline naming the biggest category
  ///
  /// In en, this message translates to:
  /// **'The most went on {category}'**
  String storyMostWent(String category);

  /// Page 4 eyebrow
  ///
  /// In en, this message translates to:
  /// **'Your days'**
  String get storyDaysEyebrow;

  /// Page 4 headline; date like Sat 12 Sep
  ///
  /// In en, this message translates to:
  /// **'Biggest day: {date}'**
  String storyBiggestDay(String date);

  /// Page 4 line under the headline: the day's amount and its biggest entry's note or category
  ///
  /// In en, this message translates to:
  /// **'{amount} · {what}'**
  String storyBiggestDayDetail(String amount, String what);

  /// Page 4: days with no everyday spending
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No day went without spending.} =1{1 day with nothing spent.} other{{count} days with nothing spent.}}'**
  String storyQuietDays(int count);

  /// Page 4: the weekday that holds at least 35% of everyday spending. A count, never a label.
  ///
  /// In en, this message translates to:
  /// **'Your {count} {weekday, select, monday{Mondays} tuesday{Tuesdays} wednesday{Wednesdays} thursday{Thursdays} friday{Fridays} saturday{Saturdays} other{Sundays}} came to {amount}.'**
  String storyWeekday(int count, String weekday, String amount);

  /// Page 4 key when there is a daily share
  ///
  /// In en, this message translates to:
  /// **'Bills aren\'t in the days. The dotted line is a day\'s share ({amount}); dark bars went past it.'**
  String storyDaysKeyShare(String amount);

  /// Page 4 key when nothing came in, so there is no share
  ///
  /// In en, this message translates to:
  /// **'Bills aren\'t in the days.'**
  String get storyDaysKeyNoShare;

  /// Page 5 eyebrow naming the cycle before, as the switcher names it
  ///
  /// In en, this message translates to:
  /// **'Against {cycle}'**
  String storyAgainstEyebrow(String cycle);

  /// Page 5 headline when less was spent than the cycle before
  ///
  /// In en, this message translates to:
  /// **'{amount} less than {cycle}'**
  String storyChangeLess(String amount, String cycle);

  /// Page 5 headline when more was spent than the cycle before
  ///
  /// In en, this message translates to:
  /// **'{amount} more than {cycle}'**
  String storyChangeMore(String amount, String cycle);

  /// Page 5 headline when spending matched the cycle before
  ///
  /// In en, this message translates to:
  /// **'The same as {cycle}'**
  String storyChangeSame(String cycle);

  /// Page 5 line under the headline
  ///
  /// In en, this message translates to:
  /// **'{cycle} spent {amount}'**
  String storyPreviousSpent(String cycle, String amount);

  /// Page 5 row: a category fell
  ///
  /// In en, this message translates to:
  /// **'{amount} less'**
  String storyMoveLess(String amount);

  /// Page 5 row: a category rose
  ///
  /// In en, this message translates to:
  /// **'{amount} more'**
  String storyMoveMore(String amount);

  /// Page 6 eyebrow
  ///
  /// In en, this message translates to:
  /// **'That was {cycle}'**
  String storyEndEyebrow(String cycle);

  /// Page 6 row: what was spent, leaving out Not logged
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get storyKeySpent;

  /// Names the cycle before in a comparison, as the switcher does: 'in September' (FR-SP-3a)
  ///
  /// In en, this message translates to:
  /// **'in {cycle}'**
  String spendsCompareInCycle(String cycle);

  /// Names the cycle before in a comparison when cycles are weekly (D196)
  ///
  /// In en, this message translates to:
  /// **'the week before'**
  String get spendsCompareWeekBefore;

  /// Pace card line on the running cycle: spending so far against the same day of the cycle before. previous is spendsCompareInCycle or spendsCompareWeekBefore. Neutral, no good or bad word (FR-SP-3a)
  ///
  /// In en, this message translates to:
  /// **'{dir, select, less{{amount} less than by this day {previous}.} more{{amount} more than by this day {previous}.} other{Same as by this day {previous}.}}'**
  String spendsCompareNow(String dir, String amount, String previous);

  /// Pace card line on a finished cycle: the whole cycle against the whole cycle before (FR-SP-3a)
  ///
  /// In en, this message translates to:
  /// **'{dir, select, less{{amount} less than {previous}.} more{{amount} more than {previous}.} other{Same as {previous}.}}'**
  String spendsCompareDone(String dir, String amount, String previous);

  /// Split card title: the money that came in for the cycle shown. Never 'income' (D196)
  ///
  /// In en, this message translates to:
  /// **'Money in {amount}'**
  String spendsSplitTitle(String amount);

  /// Split card answer while the cycle runs: money in less bills, everyday spending, fixes and saving (FR-SP-4b)
  ///
  /// In en, this message translates to:
  /// **'{amount} not spent yet'**
  String spendsSplitNotSpentYet(String amount);

  /// Split card answer while the cycle runs when exactly nothing is left
  ///
  /// In en, this message translates to:
  /// **'All of it is spent or saved.'**
  String get spendsSplitNoneNow;

  /// Split card answer on a finished cycle when exactly nothing was left
  ///
  /// In en, this message translates to:
  /// **'Nothing left over.'**
  String get spendsSplitNoneDone;

  /// Line under the split card's answer when something was saved
  ///
  /// In en, this message translates to:
  /// **'And {amount} saved.'**
  String spendsSplitSaved(String amount);

  /// Line under the split card's answer past the money in, when something was saved
  ///
  /// In en, this message translates to:
  /// **'That includes {amount} saved.'**
  String spendsSplitIncludesSaved(String amount);

  /// One line under the split card's key, defining Everyday
  ///
  /// In en, this message translates to:
  /// **'Everyday is all spending except bills.'**
  String get spendsSplitNote;

  /// The same line when Fix my number added a Not logged amount
  ///
  /// In en, this message translates to:
  /// **'Everyday is all spending except bills, including {amount} not logged.'**
  String spendsSplitNoteNotLogged(String amount);

  /// Split card title when no money came in this cycle
  ///
  /// In en, this message translates to:
  /// **'{when, select, now{Spending this {unit, select, week{week} other{month}}} other{Spending in {cycle}}}'**
  String spendsSplitNoIncomeTitle(String when, String unit, String cycle);

  /// Split card body when no money came in this cycle
  ///
  /// In en, this message translates to:
  /// **'Add the money coming in to see how it splits.'**
  String get spendsSplitNoIncomeBody;

  /// Split card chip that opens Settings at Money coming in
  ///
  /// In en, this message translates to:
  /// **'Add money coming in'**
  String get spendsSplitNoIncomeAction;

  /// Screen-reader opening of the split card: the answer, then the money in
  ///
  /// In en, this message translates to:
  /// **'{answer} of {amount}.'**
  String spendsSplitSpokenOf(String answer, String amount);

  /// Screen reader: one labelled amount, such as 'Bills 8,200 rupees.'
  ///
  /// In en, this message translates to:
  /// **'{label} {amount}.'**
  String spendsSpokenPart(String label, String amount);

  /// Line above Where it went's rows naming the biggest category (FR-SP-4 AC-R1)
  ///
  /// In en, this message translates to:
  /// **'The most went on {category}.'**
  String spendsWhereHeadline(String category);

  /// The same line when one category holds all the spending
  ///
  /// In en, this message translates to:
  /// **'All of it went on {category}.'**
  String spendsWhereHeadlineAll(String category);

  /// First line of an opened category row: its change against the cycle before by the same day. previous is a short month ('Sep') or 'the week before'
  ///
  /// In en, this message translates to:
  /// **'{dir, select, less{{amount} less than {previous}} more{{amount} more than {previous}} other{Same as {previous}}}'**
  String spendsRowChange(String dir, String amount, String previous);

  /// Caption over an opened row's entries
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Only entry} =2{Both entries} other{Biggest 3 of {count}}}'**
  String spendsTopCaption(int count);

  /// Caption over an opened row that has exactly 3 entries
  ///
  /// In en, this message translates to:
  /// **'All 3 entries'**
  String get spendsTopCaptionAllThree;

  /// An entry's label when it has no note
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get spendsTopNoNote;

  /// Screen reader: one of an opened row's entries
  ///
  /// In en, this message translates to:
  /// **'{label}, {date}, {amount}'**
  String spendsTopEntrySpoken(String label, String date, String amount);

  /// Screen-reader hint on a closed category row
  ///
  /// In en, this message translates to:
  /// **'Show biggest entries'**
  String get spendsRowOpenHint;

  /// Screen-reader hint on an open category row
  ///
  /// In en, this message translates to:
  /// **'Hide biggest entries'**
  String get spendsRowCloseHint;

  /// Months strip title (FR-SP-8)
  ///
  /// In en, this message translates to:
  /// **'{unit, select, week{Last {count} weeks} other{Last {count} months}}'**
  String spendsStripTitle(String unit, int count);

  /// Strip count: some finished cycles had money left over. A count, never a grade
  ///
  /// In en, this message translates to:
  /// **'{unit, select, week{Money was left over in {left} of the last {count} weeks.} other{Money was left over in {left} of the last {count} months.}}'**
  String spendsStripLeftSome(String unit, int left, int count);

  /// Strip count: no finished cycle had money left over
  ///
  /// In en, this message translates to:
  /// **'{unit, select, week{Nothing was left over in the last {count} weeks.} other{Nothing was left over in the last {count} months.}}'**
  String spendsStripLeftNone(String unit, int count);

  /// Strip count: every finished cycle had money left over
  ///
  /// In en, this message translates to:
  /// **'{unit, select, week{Money was left over in all {count} weeks.} other{Money was left over in all {count} months.}}'**
  String spendsStripLeftAll(String unit, int count);

  /// Strip count: both of two finished cycles had money left over
  ///
  /// In en, this message translates to:
  /// **'{unit, select, week{Money was left over in both weeks.} other{Money was left over in both months.}}'**
  String spendsStripLeftBoth(String unit);

  /// Line under the months strip
  ///
  /// In en, this message translates to:
  /// **'Dark is spent. Outline is saved.'**
  String get spendsStripKey;

  /// Strip caption naming the dotted line, with the cycle shown's money in
  ///
  /// In en, this message translates to:
  /// **'Money in {amount}'**
  String spendsStripMoneyIn(String amount);

  /// Names the running cycle in the strip's read-out
  ///
  /// In en, this message translates to:
  /// **'{cycle} so far'**
  String spendsStripSoFar(String cycle);

  /// Strip read-out for the picked cycle
  ///
  /// In en, this message translates to:
  /// **'{cycle}: spent {spent}, saved {saved}.'**
  String spendsStripReadSpentSaved(String cycle, String spent, String saved);

  /// Strip read-out for the picked cycle when nothing was saved
  ///
  /// In en, this message translates to:
  /// **'{cycle}: spent {spent}.'**
  String spendsStripReadSpent(String cycle, String spent);

  /// Strip read-out for a cycle with no entries
  ///
  /// In en, this message translates to:
  /// **'{cycle}: nothing spent or saved.'**
  String spendsStripReadNone(String cycle);

  /// Strip read-out tail for the running cycle
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Last day.} =1{1 day to go.} other{{count} days to go.}}'**
  String spendsStripDaysToGo(int count);

  /// Strip action that shows the picked cycle on Spends
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get spendsStripOpen;
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
