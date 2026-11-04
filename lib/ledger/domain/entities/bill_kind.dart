import 'bill_icon.dart';
import 'category.dart';

/// The common fixed bills offered as chips in onboarding and Settings, in display order
/// (SPEC FR-ON-4, FR-SE-1).
enum BillKind {
  rent,
  emi,
  phone,
  internet,
  schoolFees,
  subscriptions;

  /// The seed category its entries go to: Home for rent, Bills for the rest.
  String get categoryKey => this == BillKind.rent ? CategoryKeys.home : CategoryKeys.bills;

  /// The icon its bill shows (SPEC BR-9).
  BillIcon get icon => switch (this) {
        BillKind.rent => BillIcon.home,
        BillKind.emi => BillIcon.loan,
        BillKind.phone => BillIcon.phone,
        BillKind.internet => BillIcon.internet,
        BillKind.schoolFees => BillIcon.school,
        BillKind.subscriptions => BillIcon.tv,
      };
}
