import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lines allowed to name a raw colour outside `lib/core/design/`, each with its reason. A key is
/// the file and the exact trimmed line.
const Map<(String, String), String> _exceptions = <(String, String), String>{
  (
    'lib/core/widgets/day_blocks/day_blocks_painter.dart',
    'const DayBlocksColors({required this.signal, required this.idle, required this.outline, '
        'this.edge = const Color(0x00000000)});',
  ): 'A const default cannot read the theme. Alpha 0 means "draw no edge" (the painter checks '
      '`edge.a`), so its RGB never paints and it is never lerped; DayBlocks always passes displayEdge.',
};

// why: `Colors.` must not match token classes such as `HisaabColors.` or `DayBlocksColors(`.
final RegExp _rawColour = RegExp(r'(?<![A-Za-z0-9_])Colors\.|Color\(0x');

void main() {
  test('no widget names a raw colour; colours come from HisaabColors (CLAUDE.md, principle 29)', () {
    final List<String> found = <String>[];
    final Set<(String, String)> used = <(String, String)>{};
    // why: Windows lists `lib\core\...`; one separator keeps the skips and exception keys working.
    final Iterable<(File, String)> sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => (f, f.path.replaceAll(r'\', '/')))
        .where(((File, String) s) => s.$2.endsWith('.dart'))
        .where(((File, String) s) => !s.$2.startsWith('lib/core/design/') && !s.$2.startsWith('lib/l10n/gen/'));
    for (final (File file, String path) in sources) {
      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i].trim();
        if (line.startsWith('//') || !_rawColour.hasMatch(line)) {
          continue;
        }
        final (String, String) key = (path, line);
        if (_exceptions.containsKey(key)) {
          used.add(key);
        } else {
          found.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(found, isEmpty, reason: 'Use a HisaabColors token (`clear` for see-through).');
    expect(used, _exceptions.keys.toSet(), reason: 'Remove exceptions that no longer match a line.');
  });
}
