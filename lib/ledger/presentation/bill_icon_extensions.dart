import 'package:hugeicons/hugeicons.dart';

import '../../core/design/app_icons.dart';
import '../domain/entities/bill_icon.dart';

/// Display helpers for [BillIcon].
extension BillIconExtensions on BillIcon {
  /// The Hugeicons stroke-rounded glyph drawn for this bill icon (D118).
  AppIconData get glyph => switch (this) {
        BillIcon.bill => AppIcons.recurring,
        BillIcon.home => HugeIcons.strokeRoundedHome01,
        BillIcon.power => HugeIcons.strokeRoundedFlash,
        BillIcon.phone => HugeIcons.strokeRoundedSmartPhone01,
        BillIcon.internet => HugeIcons.strokeRoundedWifi01,
        BillIcon.loan => HugeIcons.strokeRoundedBank,
        BillIcon.card => HugeIcons.strokeRoundedCreditCard,
        BillIcon.tv => HugeIcons.strokeRoundedTv01,
        BillIcon.school => HugeIcons.strokeRoundedSchool,
        BillIcon.water => HugeIcons.strokeRoundedDroplet,
        BillIcon.gas => HugeIcons.strokeRoundedFire,
        BillIcon.insurance => HugeIcons.strokeRoundedShield01,
        BillIcon.help => HugeIcons.strokeRoundedUser,
        BillIcon.milk => HugeIcons.strokeRoundedMilkBottle,
        BillIcon.society => HugeIcons.strokeRoundedBuilding03,
        BillIcon.car => HugeIcons.strokeRoundedCar01,
      };
}
