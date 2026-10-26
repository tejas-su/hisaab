import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' SIL Open Font Licences to the app's licence page, as the OFL requires.
void registerFontLicenses({AssetBundle? bundle}) {
  final AssetBundle assets = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      <String>['Anek Latin'],
      await assets.loadString('assets/fonts/OFL-AnekLatin.txt'),
    );
    yield LicenseEntryWithLineBreaks(<String>['Mukta'], await assets.loadString('assets/fonts/OFL-Mukta.txt'));
  });
}
