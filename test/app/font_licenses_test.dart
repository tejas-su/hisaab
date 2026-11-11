import 'package:hisaab/app/font_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registers the OFL text for both bundled fonts', (WidgetTester tester) async {
    registerFontLicenses();
    final List<LicenseEntry> entries = await tester.runAsync(() => LicenseRegistry.licenses.toList()) ?? <LicenseEntry>[];
    final Map<String, String> byPackage = <String, String>{
      for (final LicenseEntry entry in entries)
        for (final String package in entry.packages)
          package: entry.paragraphs.map((LicenseParagraph paragraph) => paragraph.text).join('\n'),
    };
    expect(byPackage['Anek Latin'], contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(byPackage['Mukta'], contains('SIL OPEN FONT LICENSE Version 1.1'));
  });
}
