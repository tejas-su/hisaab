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
}
