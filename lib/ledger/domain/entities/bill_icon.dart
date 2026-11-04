import 'package:fpdart/fpdart.dart';

/// The icon a fixed bill shows, in the icon grid's display order (SPEC BR-9, D118).
enum BillIcon {
  bill,
  home,
  power,
  phone,
  internet,
  loan,
  card,
  tv,
  school,
  water,
  gas,
  insurance,
  help,
  milk,
  society,
  car;

  /// The stored value: the enum name.
  String get value => name;

  /// The icon stored as [value], or none when [value] is null or unknown (a newer version).
  static Option<BillIcon> fromValue(String? value) =>
      Option<BillIcon>.fromNullable(BillIcon.values.where((BillIcon icon) => icon.value == value).firstOrNull);

  /// The icon [name] suggests: the first group with a whole-word match, else [bill].
  ///
  /// "Car EMI" gives [loan] and "Airtel fibre" gives [internet].
  static BillIcon forName(String name) {
    final String words = ' ${name.toLowerCase().replaceAll(RegExp('[^a-z0-9-]+'), ' ').trim()} ';
    for (final (BillIcon icon, List<String> keys) in _words) {
      if (keys.any((String key) => words.contains(' $key '))) return icon;
    }
    return BillIcon.bill;
  }

  // why: the order settles names that hit two groups ("Car EMI" is a loan, "Airtel fibre"
  // is internet), so it differs from the grid order.
  static const List<(BillIcon, List<String>)> _words = <(BillIcon, List<String>)>[
    (BillIcon.loan, <String>['emi', 'loan', 'mortgage']),
    (BillIcon.card, <String>['credit card', 'card']),
    (BillIcon.power, <String>['electricity', 'electric', 'power', 'light bill', 'bijli', 'bescom', 'msedcl', 'tneb']),
    (BillIcon.internet, <String>['internet', 'wifi', 'wi-fi', 'broadband', 'fibre', 'fiber', 'act', 'hathway']),
    (BillIcon.phone, <String>['phone', 'mobile', 'recharge', 'jio', 'airtel', 'vi', 'vodafone', 'bsnl', 'postpaid']),
    (BillIcon.tv, <String>[
      'subscription', 'subscriptions', 'netflix', 'prime', 'hotstar', 'spotify', 'youtube', 'ott', 'dth', //
      'tata play', 'cable', 'tv',
    ]),
    (BillIcon.school, <String>['school', 'fees', 'tuition', 'college', 'coaching', 'class']),
    (BillIcon.water, <String>['water', 'paani']),
    (BillIcon.gas, <String>['gas', 'cylinder', 'lpg', 'png', 'indane']),
    (BillIcon.insurance, <String>['insurance', 'lic', 'policy', 'premium']),
    (BillIcon.help, <String>['maid', 'bai', 'cook', 'driver', 'nanny', 'didi', 'help']),
    (BillIcon.milk, <String>['milk', 'doodh', 'dairy']),
    (BillIcon.society, <String>['society', 'maintenance', 'apartment']),
    (BillIcon.home, <String>['rent', 'kiraya', 'house', 'pg']),
    (BillIcon.car, <String>['car', 'bike', 'parking']),
  ];
}
