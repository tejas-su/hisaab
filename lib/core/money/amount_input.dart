import 'package:fpdart/fpdart.dart';

/// The keypad's rules for building a whole-rupee amount, shared by onboarding and the Add tray
/// (SPEC FR-AD-2, BR-10).
///
/// Amounts are whole major units (rupees). There is no decimal key, leading zeros are ignored
/// because the value is a number, and anything past [maxDigits] digits is rejected.
abstract final class AmountInput {
  /// The most digits an amount may have (₹99,99,99,999).
  static const int maxDigits = 9;

  /// The largest amount that can be typed.
  static const int maxRupees = 999999999;

  /// The keys that type digits; `00` appends two zeros at once.
  static const List<String> digitKeys = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0'];

  /// Appends [key] (`0`–`9` or `00`) to [rupees].
  ///
  /// Returns [Some] with the new amount, or [None] when the result would have more than
  /// [maxDigits] digits, so the caller can shake and play the reject haptic.
  static Option<int> append(int rupees, String key) {
    final int shift = key == '00' ? 100 : 10;
    final int digit = key == '00' ? 0 : int.parse(key);
    return _withinCap(rupees * shift + digit);
  }

  /// Removes the last digit of [rupees]; 0 stays 0.
  static int backspace(int rupees) => rupees ~/ 10;

  /// Adds a quick-chip [amount] to [rupees] (SPEC FR-AD-1: chips add, never replace).
  ///
  /// Returns [Some] with the sum, or [None] when it would pass [maxRupees].
  static Option<int> add(int rupees, int amount) => _withinCap(rupees + amount);

  static Option<int> _withinCap(int rupees) => rupees <= maxRupees ? Option<int>.of(rupees) : const Option<int>.none();
}
