import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';

/// Drift guards (widget spec §13): the widget's colours and the words Android shows before the app
/// runs live in Android resources, and must stay equal to `HisaabColors` and the ARB.
void main() {
  const String res = 'android/app/src/main/res';

  Map<String, String> entries(String file, String tag) => <String, String>{
        for (final RegExpMatch m in RegExp('<$tag name="([a-z0-9_]+)">([^<]*)</$tag>').allMatches(File('$res/$file').readAsStringSync()))
          m.group(1)!: m.group(2)!,
      };

  String hex(Color color) => '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  // why: Android writes an opaque colour as #RRGGBB; widen it to #AARRGGBB to compare.
  String argb(String value) => value.length == 7 ? '#FF${value.substring(1)}' : value.toUpperCase();

  group('widget_colors.xml', () {
    final Map<String, String> colors = entries('values/widget_colors.xml', 'color');
    final Map<String, Color Function(HisaabColors)> tokens = <String, Color Function(HisaabColors)>{
      'display': (HisaabColors c) => c.display,
      'display_ink': (HisaabColors c) => c.displayInk,
      'display_ink2': (HisaabColors c) => c.displayInk2,
      'block_idle': (HisaabColors c) => c.blockIdle,
      'display_etch': (HisaabColors c) => c.displayEtch,
      'hairline': (HisaabColors c) => c.hairline,
      'signal': (HisaabColors c) => c.signal,
      'display_edge': (HisaabColors c) => c.displayEdge,
    };
    final Map<String, HisaabColors> looks = <String, HisaabColors>{'light': HisaabColors.light, 'dark': HisaabColors.dark};

    for (final MapEntry<String, HisaabColors> look in looks.entries) {
      for (final MapEntry<String, Color Function(HisaabColors)> token in tokens.entries) {
        final String name = 'widget_${look.key}_${token.key}';
        test('$name equals HisaabColors.${look.key}', () {
          expect(argb(colors[name]!), hex(token.value(look.value)));
        });
      }
    }

    test('widget_on_signal equals onSignal in both looks', () {
      expect(argb(colors['widget_on_signal']!), hex(HisaabColors.light.onSignal));
      expect(HisaabColors.dark.onSignal, HisaabColors.light.onSignal);
    });
  });

  group('strings.xml', () {
    final Map<String, Object?> arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, Object?>;
    final Map<String, String> strings = entries('values/strings.xml', 'string');
    const Map<String, String> mirrors = <String, String>{
      'widget_name': 'widgetName',
      'widget_description': 'widgetDescription',
      'widget_stale': 'widgetStale',
      'tile_add_spend': 'tileAddSpend',
      'shortcut_add_spend': 'shortcutAddSpend',
    };

    for (final MapEntry<String, String> mirror in mirrors.entries) {
      test('${mirror.key} equals the ARB\'s ${mirror.value}', () {
        expect(strings[mirror.key]!.replaceAll(r"\'", "'"), arb[mirror.value]);
      });
    }

    test('mirrors every string it holds', () => expect(strings.keys.toSet(), mirrors.keys.toSet()));
  });
}
