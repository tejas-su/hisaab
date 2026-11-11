import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  group('BillIconExtensions.glyph', () {
    test('maps each bill icon to its Hugeicons stroke-rounded glyph (D118)', () {
      expect(<AppIconData>[for (final BillIcon icon in BillIcon.values) icon.glyph], <AppIconData>[
        HugeIcons.strokeRoundedRepeat,
        HugeIcons.strokeRoundedHome01,
        HugeIcons.strokeRoundedFlash,
        HugeIcons.strokeRoundedSmartPhone01,
        HugeIcons.strokeRoundedWifi01,
        HugeIcons.strokeRoundedBank,
        HugeIcons.strokeRoundedCreditCard,
        HugeIcons.strokeRoundedTv01,
        HugeIcons.strokeRoundedSchool,
        HugeIcons.strokeRoundedDroplet,
        HugeIcons.strokeRoundedFire,
        HugeIcons.strokeRoundedShield01,
        HugeIcons.strokeRoundedUser,
        HugeIcons.strokeRoundedMilkBottle,
        HugeIcons.strokeRoundedBuilding03,
        HugeIcons.strokeRoundedCar01,
      ]);
    });

    test('the plain bill uses the recurring glyph', () => expect(BillIcon.bill.glyph, AppIcons.recurring));
  });
}
