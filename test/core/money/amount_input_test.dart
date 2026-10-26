import 'package:expense_tracker/core/money/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('AmountInput.append (FR-AD-2)', () {
    final List<(int, String, Option<int>)> cases = <(int, String, Option<int>)>[
      (0, '4', const Option<int>.of(4)),
      (4, '5', const Option<int>.of(45)),
      (45, '00', const Option<int>.of(4500)),
      (0, '0', const Option<int>.of(0)),
      (0, '00', const Option<int>.of(0)),
      (12345678, '9', const Option<int>.of(123456789)),
      (99999999, '9', const Option<int>.of(999999999)),
      (123456789, '1', const Option<int>.none()),
      (12345678, '00', const Option<int>.none()),
      (999999999, '0', const Option<int>.none()),
    ];
    for (final (int rupees, String key, Option<int> expected) in cases) {
      test('$rupees + "$key" → $expected', () {
        expect(AmountInput.append(rupees, key), expected);
      });
    }

    test('ignores leading zeros', () {
      final int typed = <String>['0', '0', '7'].fold(0, (int value, String key) => AmountInput.append(value, key).getOrElse(() => -1));
      expect(typed, 7);
    });
  });

  group('AmountInput.backspace', () {
    test('drops the last digit', () {
      expect(AmountInput.backspace(4500), 450);
      expect(AmountInput.backspace(7), 0);
      expect(AmountInput.backspace(0), 0);
    });
  });

  group('AmountInput.add (quick chips)', () {
    test('adds to the amount instead of replacing it', () {
      expect(AmountInput.add(40, 10), const Option<int>.of(50));
      expect(AmountInput.add(0, 500), const Option<int>.of(500));
    });

    test('rejects a sum past the 9-digit cap', () {
      expect(AmountInput.add(999999990, 10), const Option<int>.none());
      expect(AmountInput.add(999999500, 500), const Option<int>.none());
      expect(AmountInput.add(999999499, 500), const Option<int>.of(999999999));
    });
  });

  test('digit keys follow the phone layout with 00 and 0 last', () {
    expect(AmountInput.digitKeys.last, '0');
    expect(AmountInput.digitKeys, hasLength(11));
  });
}
