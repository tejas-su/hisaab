import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

void main() {
  group('LaunchAction.parse', () {
    const Map<String, LaunchAction> known = <String, LaunchAction>{
      'hisaab://add': LaunchAction.add,
      'hisaab://home': LaunchAction.home,
      'hisaab://setup': LaunchAction.setUp,
    };
    for (final MapEntry<String, LaunchAction> uri in known.entries) {
      test('reads "${uri.key}" as ${uri.value.name}', () {
        expect(LaunchAction.parse(uri.key), Option<LaunchAction>.of(uri.value));
      });
    }

    const List<String?> unknown = <String?>[
      null,
      '',
      ' ',
      'hisaab://',
      'hisaab://pay',
      'hisaab://add/extra',
      'hisaab://add?amount=500',
      'https://add',
      'add',
      'HISAAB-x://add',
      '::not a uri::',
    ];
    for (final String? uri in unknown) {
      test('gives none for ${uri == null ? 'no URI' : '"$uri"'}', () {
        expect(LaunchAction.parse(uri), const Option<LaunchAction>.none());
      });
    }
  });
}
