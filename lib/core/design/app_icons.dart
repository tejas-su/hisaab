import 'package:hugeicons/hugeicons.dart';

import 'hisaab_glyphs.dart';

/// Hugeicons glyph data; the package represents icons as SVG path lists, not `IconData`.
typedef AppIconData = List<List<dynamic>>;

/// Every icon the app uses (UI_DESIGN §3.5). Hugeicons stroke-rounded only, plus the few
/// [HisaabGlyphs] drawn in its format where the free set has none; never `Icons.*`.
abstract final class AppIcons {
  static const AppIconData home = HugeIcons.strokeRoundedHome01;
  static const AppIconData spends = HugeIcons.strokeRoundedChartHistogram;
  static const AppIconData settings = HugeIcons.strokeRoundedSlidersHorizontal;
  static const AppIconData add = HugeIcons.strokeRoundedAdd01;
  static const AppIconData calendar = HugeIcons.strokeRoundedCalendar03;
  static const AppIconData payday = HugeIcons.strokeRoundedFlag02;
  static const AppIconData onTrack = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIconData alert = HugeIcons.strokeRoundedAlertCircle;
  static const AppIconData info = HugeIcons.strokeRoundedInformationCircle;
  static const AppIconData back = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIconData next = HugeIcons.strokeRoundedArrowRight02;
  static const AppIconData backspace = HisaabGlyphs.backspace;
  static const AppIconData note = HugeIcons.strokeRoundedNote01;
  static const AppIconData copy = HugeIcons.strokeRoundedCopy01;
  static const AppIconData share = HugeIcons.strokeRoundedShare08;
  static const AppIconData askAi = HugeIcons.strokeRoundedAiChat02;
  static const AppIconData delete = HugeIcons.strokeRoundedDelete02;
  static const AppIconData limit = HugeIcons.strokeRoundedTarget01;
  static const AppIconData recurring = HugeIcons.strokeRoundedRepeat;
  static const AppIconData dropdown = HugeIcons.strokeRoundedArrowDown01;
  static const AppIconData check = HugeIcons.strokeRoundedTick02;
  static const AppIconData askReview = HugeIcons.strokeRoundedAnalytics01;
  static const AppIconData askSave = HugeIcons.strokeRoundedPiggyBank;
  static const AppIconData askBudget = HugeIcons.strokeRoundedTarget02;
  static const AppIconData askOnTrack = HugeIcons.strokeRoundedRoute01;
  static const AppIconData askOwn = HugeIcons.strokeRoundedPencilEdit02;

  /// Category icons by the `icon_key` stored in the database (SPEC BR-11).
  static const Map<String, AppIconData> byKey = <String, AppIconData>{
    'food': HugeIcons.strokeRoundedRestaurant01,
    'travel': HugeIcons.strokeRoundedBus01,
    'shopping': HugeIcons.strokeRoundedShoppingBag01,
    'bills': HugeIcons.strokeRoundedInvoice01,
    'fun': HugeIcons.strokeRoundedParty,
    'health': HugeIcons.strokeRoundedMedicine01,
    'home': HugeIcons.strokeRoundedHome01,
    'other': HugeIcons.strokeRoundedPackageOpen,
    'salary': HugeIcons.strokeRoundedMoneyReceiveCircle,
    'other_income': HugeIcons.strokeRoundedMoneyAdd02,
  };

  /// The icon for a stored [key], falling back to "other" for unknown keys.
  static AppIconData forKey(String key) => byKey[key] ?? HugeIcons.strokeRoundedPackageOpen;
}
