import 'package:hisaab/core/design/hisaab_colors.dart';
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
  // why: every contrast floor lives in one list, contrast_pairs_test.dart (principle 26, D98). These
  // two are not floors: one says an edge is absent, the other caps a ratio.
  group('HisaabColors signal guards (UI_DESIGN §3.2)', () {
    test('dark: no edge is drawn around today’s block', () {
      expect(HisaabColors.dark.displayEdge.a, 0);
    });

    test('signal is never usable bare on the light background (guards the UI_DESIGN rule)', () {
      expect(_contrast(HisaabColors.light.signal, HisaabColors.light.background), lessThan(3));
    });
  });

  group('HisaabColors light layers alternate (UI_DESIGN §3.5)', () {
    const HisaabColors light = HisaabColors.light;

    test('cards are lighter than the page and clearly apart from it', () {
      expect(light.surface.computeLuminance(), greaterThan(light.background.computeLuminance()));
      expect(_contrast(light.surface, light.background), greaterThanOrEqualTo(1.15));
    });

    test('the hero card sits on the same light layer as other cards', () {
      expect(light.display, light.surface);
    });

    test('the hero card’s text and today’s edge are ink, and its secondary text is ink2 (D145)', () {
      expect(light.displayInk, light.ink);
      expect(light.displayEdge, light.ink);
      expect(light.displayInk2, light.ink2);
    });

    test('idle day blocks are the hairline step', () {
      expect(light.blockIdle, light.hairline);
    });

    test('sunk wells are darker than both the card and the page', () {
      expect(light.sunk.computeLuminance(), lessThan(light.background.computeLuminance()));
      expect(_contrast(light.sunk, light.surface), greaterThanOrEqualTo(1.25));
    });
  });

  group('HisaabColors dark layers step lighter and stay apart (UI_DESIGN §3.5)', () {
    const HisaabColors dark = HisaabColors.dark;

    test('cards are lighter than the page and clearly apart from it', () {
      expect(dark.surface.computeLuminance(), greaterThan(dark.background.computeLuminance()));
      expect(_contrast(dark.surface, dark.background), greaterThanOrEqualTo(1.12));
    });

    test('keys and wells are lighter than the card they sit in and clearly apart from it', () {
      expect(dark.sunk.computeLuminance(), greaterThan(dark.surface.computeLuminance()));
      expect(_contrast(dark.sunk, dark.surface), greaterThanOrEqualTo(1.15));
    });

    test('a divider inside a card reads as a line', () {
      expect(_contrast(dark.hairline, dark.surface), greaterThanOrEqualTo(1.35));
    });

    test('the hero card is the card layer and its text is the card text', () {
      expect(dark.display, dark.surface);
      expect(dark.displayInk, dark.ink);
      expect(dark.displayInk2, dark.ink2);
    });
  });

  group('HisaabColors states in both themes (UI_DESIGN §3.3, §3.5)', () {
    for (final (String name, HisaabColors colors) in <(String, HisaabColors)>[
      ('light', HisaabColors.light),
      ('dark', HisaabColors.dark),
    ]) {
      test('$name: the scrim dims the page, and a tray over it stays the lighter layer', () {
        final Color dimmed = Color.alphaBlend(colors.scrim, colors.background);
        expect(dimmed.computeLuminance(), lessThan(colors.background.computeLuminance()));
        expect(colors.surface.computeLuminance(), greaterThan(dimmed.computeLuminance()));
      });
    }
  });

  group('HisaabColors clear (principle 29)', () {
    for (final (String name, HisaabColors colors) in <(String, HisaabColors)>[
      ('light', HisaabColors.light),
      ('dark', HisaabColors.dark),
    ]) {
      test('$name: clear is the page colour at alpha 0, so a fade to it never passes through black', () {
        expect(colors.clear, colors.background.withAlpha(0));
      });
    }
  });

  group('HisaabColors focus (principle 24, D99)', () {
    for (final (String name, HisaabColors colors) in <(String, HisaabColors)>[
      ('light', HisaabColors.light),
      ('dark', HisaabColors.dark),
    ]) {
      test('$name: the focus ring is ink and its gap is the page, so focus is never marigold', () {
        expect(colors.focus, colors.ink);
        expect(colors.focusGap, colors.background);
        expect(colors.focus, isNot(colors.signal));
      });
    }
  });

  group('HisaabColors control (D100)', () {
    test('light: controls on the page are the card layer, one step up from the page', () {
      expect(HisaabColors.light.control, HisaabColors.light.surface);
      expect(HisaabColors.light.control.computeLuminance(), greaterThan(HisaabColors.light.background.computeLuminance()));
    });

    test('dark: controls on the page are the hairline step, lighter than the page', () {
      expect(HisaabColors.dark.control, HisaabColors.dark.hairline);
      expect(HisaabColors.dark.control.computeLuminance(), greaterThan(HisaabColors.dark.background.computeLuminance()));
    });

    test('copyWith replaces control, and keeps it when not given', () {
      expect(HisaabColors.light.copyWith(control: HisaabColors.dark.control).control, HisaabColors.dark.control);
      expect(HisaabColors.light.copyWith().control, HisaabColors.light.control);
    });

    test('lerp interpolates control', () {
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).control, HisaabColors.dark.control);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 0).control, HisaabColors.light.control);
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
      expect(same.clear, HisaabColors.light.clear);
    });

    test('copyWith and lerp carry inverse', () {
      expect(HisaabColors.light.copyWith(inverse: HisaabColors.dark.inverse).inverse, HisaabColors.dark.inverse);
      expect(HisaabColors.light.copyWith().inverse, HisaabColors.light.inverse);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).inverse, HisaabColors.dark.inverse);
    });

    test('copyWith and lerp carry danger', () {
      expect(HisaabColors.light.copyWith(danger: HisaabColors.dark.danger).danger, HisaabColors.dark.danger);
      expect(HisaabColors.light.copyWith().danger, HisaabColors.light.danger);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).danger, HisaabColors.dark.danger);
    });

    test('inverse is a charcoal between ink2 and ink in light, and ink in dark (D105)', () {
      final double light = HisaabColors.light.inverse.computeLuminance();
      expect(light, lessThan(HisaabColors.light.ink2.computeLuminance()));
      expect(light, greaterThan(HisaabColors.light.ink.computeLuminance()));
      expect(HisaabColors.dark.inverse, HisaabColors.dark.ink);
    });

    test('copyWith replaces clear', () {
      expect(HisaabColors.light.copyWith(clear: HisaabColors.dark.clear).clear, HisaabColors.dark.clear);
    });

    test('copyWith replaces focus and focusGap, and keeps them when not given', () {
      final HisaabColors changed = HisaabColors.light.copyWith(focus: HisaabColors.dark.focus, focusGap: HisaabColors.dark.focusGap);
      expect(changed.focus, HisaabColors.dark.focus);
      expect(changed.focusGap, HisaabColors.dark.focusGap);
      expect(HisaabColors.light.copyWith().focus, HisaabColors.light.focus);
      expect(HisaabColors.light.copyWith().focusGap, HisaabColors.light.focusGap);
    });

    test('lerp interpolates between themes and handles null', () {
      expect(HisaabColors.light.lerp(null, 0.5), same(HisaabColors.light));
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).background, HisaabColors.dark.background);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 0).surface, HisaabColors.light.surface);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).clear, HisaabColors.dark.clear);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).focus, HisaabColors.dark.focus);
      expect(HisaabColors.light.lerp(HisaabColors.dark, 1).focusGap, HisaabColors.dark.focusGap);
    });
  });

  group('HisaabColors hero material (D106, case study 10)', () {
    test('light: the etch is the page step and the shadow is a faint ink', () {
      expect(HisaabColors.light.displayEtch, HisaabColors.light.background);
      expect(HisaabColors.light.displayShadow.a, greaterThan(0));
      expect(HisaabColors.light.displayShadow.withValues(alpha: 1), HisaabColors.light.ink);
    });

    test('dark: the etch is the sunk step and there is no shadow, the hairline edge stays', () {
      expect(HisaabColors.dark.displayEtch, HisaabColors.dark.sunk);
      expect(HisaabColors.dark.displayShadow.a, 0);
    });

    for (final (String name, HisaabColors colors) in <(String, HisaabColors)>[
      ('light', HisaabColors.light),
      ('dark', HisaabColors.dark),
    ]) {
      test('$name: the etch stays under 1.2:1 on the hero, so it never competes with the amount', () {
        expect(_contrast(colors.displayEtch, colors.display), lessThan(1.2));
      });

      test('$name: the sheen is see-through, so it passes over the card without hiding it', () {
        expect(colors.displaySheen.a, greaterThan(0));
        expect(colors.displaySheen.a, lessThan(1));
      });
    }

    test('light: the sheen is the card colour, a wash of light; dark: a faint ink lift', () {
      expect(HisaabColors.light.displaySheen.withValues(alpha: 1), HisaabColors.light.display);
      expect(HisaabColors.dark.displaySheen.withValues(alpha: 1), HisaabColors.dark.displayInk);
      expect(HisaabColors.dark.displaySheen.a, lessThanOrEqualTo(0.15));
    });

    test('copyWith and lerp carry the hero material tokens', () {
      final HisaabColors changed = HisaabColors.light.copyWith(
        displayEtch: HisaabColors.dark.displayEtch,
        displayShadow: HisaabColors.dark.displayShadow,
        displaySheen: HisaabColors.dark.displaySheen,
      );
      expect(changed.displayEtch, HisaabColors.dark.displayEtch);
      expect(changed.displayShadow, HisaabColors.dark.displayShadow);
      expect(changed.displaySheen, HisaabColors.dark.displaySheen);
      expect(HisaabColors.light.copyWith().displaySheen, HisaabColors.light.displaySheen);
      final HisaabColors lerped = HisaabColors.light.lerp(HisaabColors.dark, 1);
      expect(lerped.displayEtch, HisaabColors.dark.displayEtch);
      expect(lerped.displayShadow, HisaabColors.dark.displayShadow);
      expect(lerped.displaySheen, HisaabColors.dark.displaySheen);
    });
  });
}
