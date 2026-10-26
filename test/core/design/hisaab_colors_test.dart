import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('HisaabColors meets WCAG AA (SPEC NFR-4)', () {
    for (final (String name, HisaabColors colors) in <(String, HisaabColors)>[
      ('light', HisaabColors.light),
      ('dark', HisaabColors.dark),
    ]) {
      test('$name: body text on every surface ≥ 4.5:1', () {
        for (final Color surface in <Color>[colors.background, colors.surface, colors.sunk]) {
          expect(_contrast(colors.ink, surface), greaterThanOrEqualTo(4.5));
          expect(_contrast(colors.ink2, surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('$name: text on the signal key ≥ 4.5:1', () {
        expect(_contrast(colors.onSignal, colors.signal), greaterThanOrEqualTo(4.5));
      });

      test('$name: display card text ≥ 4.5:1 and signal on display ≥ 3:1', () {
        expect(_contrast(colors.displayInk, colors.display), greaterThanOrEqualTo(4.5));
        expect(_contrast(colors.displayInk2, colors.display), greaterThanOrEqualTo(4.5));
        expect(_contrast(colors.signal, colors.display), greaterThanOrEqualTo(3));
      });
    }

    test('signal is never usable bare on the light background (guards the UI_DESIGN rule)', () {
      expect(_contrast(HisaabColors.light.signal, HisaabColors.light.background), lessThan(3));
    });
  });

  group('HisaabColors theme extension', () {
    test('copyWith replaces only the given token', () {
      final HisaabColors changed = HisaabColors.light.copyWith(signal: const Color(0xFF000000));
      expect(changed.signal, const Color(0xFF000000));
      expect(changed.ink, HisaabColors.light.ink);
    });

    test('copyWith with no arguments keeps every token', () {
      final HisaabColors same = HisaabColors.light.copyWith();
      expect(same.background, HisaabColors.light.background);
      expect(same.blockIdle, HisaabColors.light.blockIdle);
    });

    test('lerp interpolates between themes and handles null', () {
      expect(HisaabColors.light.lerp(null, 0.5), same(HisaabColors.light));
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).background, HisaabColors.dark.background);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 0).surface, HisaabColors.light.surface);
    });
  });
}
