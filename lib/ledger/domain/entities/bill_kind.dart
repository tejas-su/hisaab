import 'amount_mode.dart';
import 'bill_icon.dart';
import 'category.dart';

/// The common bills offered as chips in Settings, in display order; onboarding offers only the
/// fixed ones (SPEC FR-ON-4, FR-SE-1, D125).
enum BillKind {
  rent,
  emi,
  phone,
  internet,
  schoolFees,
  subscriptions,
  creditCard,
  electricity;

  /// The seed category its entries go to: Home for rent, the hidden card category for a credit
  /// card, Bills for the rest.
  String get categoryKey => switch (this) {
        BillKind.rent => CategoryKeys.home,
        BillKind.creditCard => CategoryKeys.cardPaid,
        _ => CategoryKeys.bills,
      };

  /// How its amount behaves: a credit card is a card bill, electricity changes, the rest are fixed (D123).
  AmountMode get amountMode => switch (this) {
        BillKind.creditCard => AmountMode.card,
        BillKind.electricity => AmountMode.varies,
        _ => AmountMode.fixed,
      };

  /// The icon its bill shows (SPEC BR-9).
  BillIcon get icon => switch (this) {
        BillKind.rent => BillIcon.home,
        BillKind.emi => BillIcon.loan,
        BillKind.phone => BillIcon.phone,
        BillKind.internet => BillIcon.internet,
        BillKind.schoolFees => BillIcon.school,
        BillKind.subscriptions => BillIcon.tv,
        BillKind.creditCard => BillIcon.card,
        BillKind.electricity => BillIcon.power,
      };
}
