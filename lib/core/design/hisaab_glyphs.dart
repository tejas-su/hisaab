import 'app_icons.dart';

/// Glyphs Hugeicons' free set lacks, drawn in its stroke-rounded format so they render
/// through `AppIcon` exactly like the rest (D48).
///
/// Each one follows Hugeicons' 24-unit grid: a 1.5 stroke with round caps and joins, and
/// corner curves copied from a Hugeicons original rather than drawn by eye.
abstract final class HisaabGlyphs {
  /// ⌫: the delete-left key. The body is `Keyboard`'s 15-unit height with its squircle
  /// corners unchanged, the tip is rounded like `Tag01`'s, and the × matches
  /// `CancelSquare`'s inner cross in proportion.
  static const AppIconData backspace = <List<dynamic>>[
    <dynamic>[
      'path',
      <String, String>{
        'key': '0',
        'd': 'M3.4408 10.3375L7.4521 5.7091C8.0285 5.0441 9.22 4.5 10.1 4.5H14.5C17.7875 4.5 19.4312 4.5 '
            '20.5376 5.408C20.7401 5.5742 20.9258 5.7599 21.092 5.9624C22 7.0688 22 8.7125 22 12C22 15.2875 22 '
            '16.9312 21.092 18.0376C20.9258 18.2401 20.7401 18.4258 20.5376 18.592C19.4312 19.5 17.7875 19.5 14.5 '
            '19.5H10.1C9.22 19.5 8.0285 18.9559 7.4521 18.2909L3.4408 13.6625C2.6484 12.7481 2.6484 11.2519 3.4408 '
            '10.3375Z',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '1',
        'd': 'M17.5 9.5L12.5 14.5M17.5 14.5L12.5 9.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
  ];
}
