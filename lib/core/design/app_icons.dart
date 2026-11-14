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
  static const AppIconData privacy = HugeIcons.strokeRoundedLock;
  static const AppIconData back = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIconData next = HugeIcons.strokeRoundedArrowRight02;
  static const AppIconData backspace = HisaabGlyphs.backspace;
  static const AppIconData note = HugeIcons.strokeRoundedNote01;
  static const AppIconData copy = HugeIcons.strokeRoundedCopy01;
  static const AppIconData share = HugeIcons.strokeRoundedShare08;
  static const AppIconData askAi = HugeIcons.strokeRoundedAiChat02;
  static const AppIconData delete = HugeIcons.strokeRoundedDelete02;

  /// Hides one of the user's own categories (FR-SE-2, D138); hiding is not deleting.
  static const AppIconData hide = HugeIcons.strokeRoundedViewOffSlash;
  static const AppIconData limit = HugeIcons.strokeRoundedTarget01;
  static const AppIconData recurring = HugeIcons.strokeRoundedRepeat;
  static const AppIconData themeMatchPhone = HugeIcons.strokeRoundedSmartPhone01;
  static const AppIconData themeLight = HugeIcons.strokeRoundedSun03;
  static const AppIconData themeDark = HugeIcons.strokeRoundedMoon02;

  /// A saving such as an RD (D120).
  static const AppIconData saving = HugeIcons.strokeRoundedPiggyBank;

  /// Settings › Shortcuts: *Add a widget* (FR-SE-6).
  static const AppIconData addWidget = HugeIcons.strokeRoundedDashboardSquareAdd;

  /// Settings › Shortcuts: *Add to quick settings*; the same glyph as the tile (FR-SE-6, FR-WG-6).
  static const AppIconData addSpendTile = HugeIcons.strokeRoundedWalletAdd01;
  static const AppIconData dropdown = HugeIcons.strokeRoundedArrowDown01;
  static const AppIconData check = HugeIcons.strokeRoundedTick02;
  static const AppIconData askReview = HugeIcons.strokeRoundedAnalytics01;
  static const AppIconData askSave = HugeIcons.strokeRoundedPiggyBank;
  static const AppIconData askBudget = HugeIcons.strokeRoundedTarget02;
  static const AppIconData askOnTrack = HugeIcons.strokeRoundedRoute01;
  static const AppIconData askOwn = HugeIcons.strokeRoundedPencilEdit02;

  /// A neutral question mark for the missed-log line, so it never reads as a logged entry (FR-HO-3).
  static const AppIconData questionLine = HugeIcons.strokeRoundedHelpCircle;

  /// *Back up* and *Back up first* (D139).
  static const AppIconData backUp = HugeIcons.strokeRoundedFileExport;

  /// *Restore* and onboarding's *Restore a backup* (D139).
  static const AppIconData restore = HugeIcons.strokeRoundedFileImport;

  /// *Undo restore* (D139).
  static const AppIconData undoRestore = HugeIcons.strokeRoundedUndo02;

  /// *Undo* on the *Delete everything* key during its countdown (D149).
  static const AppIconData undoDelete = HugeIcons.strokeRoundedUndo02;

  /// A row or key that is working (D139).
  static const AppIconData busy = HugeIcons.strokeRoundedLoading03;

  /// *Fix my number*'s Settings row (P14): a calculator, so it is not read as the sliders of Settings.
  static const AppIconData fixMyNumber = HugeIcons.strokeRoundedCalculator01;

  /// A *Not logged* entry's row (BR-18): a balance, for money made to match.
  static const AppIconData notLogged = HugeIcons.strokeRoundedBalanceScale;

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
    // why: the curated keys a category of the user's own can carry (D138), in the icon step's
    // order; each is permanent once shipped, and only its glyph may ever change.
    'groceries': HugeIcons.strokeRoundedShoppingBasket03,
    'vegetables': HugeIcons.strokeRoundedLeafyGreen,
    'fruit': HugeIcons.strokeRoundedApple,
    'milk': HugeIcons.strokeRoundedMilkBottle,
    'chai': HisaabGlyphs.cuttingChai,
    'coffee': HugeIcons.strokeRoundedCoffee02,
    'snacks': HugeIcons.strokeRoundedFrenchFries01,
    'eating_out': HugeIcons.strokeRoundedHamburger01,
    'cigarettes': HugeIcons.strokeRoundedCigarette,
    'beer': HugeIcons.strokeRoundedBeer,
    'cold_drink': HugeIcons.strokeRoundedSodaCan,
    'drinks': HugeIcons.strokeRoundedDrink,
    'sweets': HugeIcons.strokeRoundedCandy,
    'gaming': HugeIcons.strokeRoundedGameController01,
    'cards': HugeIcons.strokeRoundedCards01,
    'lottery': HugeIcons.strokeRoundedTicket01,
    'paan': HisaabGlyphs.paan,
    'hookah': HisaabGlyphs.hookah,
    'fuel': HugeIcons.strokeRoundedPetrolPump,
    'auto': HisaabGlyphs.autoRickshaw,
    'cab': HugeIcons.strokeRoundedTaxi,
    'bike': HugeIcons.strokeRoundedMotorbike01,
    'car': HugeIcons.strokeRoundedCar01,
    'metro': HugeIcons.strokeRoundedMetro,
    'train': HugeIcons.strokeRoundedTrain01,
    'parking': HugeIcons.strokeRoundedCircleParking,
    'trip': HugeIcons.strokeRoundedPlane,
    'kids': HugeIcons.strokeRoundedBaby01,
    'school': HugeIcons.strokeRoundedSchool,
    'family': HugeIcons.strokeRoundedUserGroup,
    'pet': HugeIcons.strokeRoundedPawPrint,
    'cleaning': HugeIcons.strokeRoundedClean,
    'laundry': HugeIcons.strokeRoundedWashingMachine,
    'repair': HugeIcons.strokeRoundedWrench01,
    'plants': HugeIcons.strokeRoundedPlant02,
    'medicine': HugeIcons.strokeRoundedMedicine02,
    'gym': HugeIcons.strokeRoundedDumbbell01,
    'yoga': HugeIcons.strokeRoundedYoga01,
    'salon': HugeIcons.strokeRoundedScissor,
    'prayer': HugeIcons.strokeRoundedHandPrayer,
    'giving': HugeIcons.strokeRoundedHandHeart,
    'gift': HugeIcons.strokeRoundedGift,
    'wedding': HugeIcons.strokeRoundedWedding,
    'clothes': HugeIcons.strokeRoundedTShirt,
    'shoes': HugeIcons.strokeRoundedSneaker,
    'jewellery': HugeIcons.strokeRoundedEarRings01,
    'phone': HugeIcons.strokeRoundedSmartphone,
    'recharge': HugeIcons.strokeRoundedSimcard01,
    'movies': HugeIcons.strokeRoundedFilm01,
    'books': HugeIcons.strokeRoundedBook03,
    'tag': HugeIcons.strokeRoundedTag01,
  };

  /// The icon for a stored [key], falling back to "other" for unknown keys.
  static AppIconData forKey(String key) => byKey[key] ?? HugeIcons.strokeRoundedPackageOpen;
}
