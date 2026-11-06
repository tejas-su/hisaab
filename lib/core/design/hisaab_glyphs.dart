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

  /// A cutting-chai glass: the small ribbed glass of a tea stall. The tapered body follows
  /// `GlassWater` scaled to the lower 13 units, and the steam is `Tea`'s, centred on the glass.
  static const AppIconData cuttingChai = <List<dynamic>>[
    <dynamic>[
      'path',
      <String, String>{
        'key': '0',
        'd': 'M14.6 8.5H9.4C8.1 8.5 7.45 8.5 7.08 8.9C6.72 9.3 6.77 9.95 6.87 11.2L7.47 18.4C7.58 19.9 7.64 20.68 8.13 21.08C8.62 21.5 9.4 21.5 10.95 21.5H13.05C14.6 21.5 15.38 21.5 15.87 21.08C16.36 20.68 16.42 19.9 16.53 18.4L17.13 11.2C17.23 9.95 17.28 9.3 16.92 8.9C16.55 8.5 15.9 8.5 14.6 8.5Z',
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
        'd': 'M7.2 12H16.8',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '2',
        'd': 'M10.2 14.5V18.5M13.8 14.5V18.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '3',
        'd': 'M13.3089 2.5C12.7622 2.83861 12.0012 4 12.0012 5.5M9.53971 4C9.53971 4 9 4.5 9 5.5M16.0012 4C15.7279 4.1693 15.5 5 15.5 5.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
  ];

  /// An auto-rickshaw seen from the side: a tall canopy over an open seat on two visible
  /// wheels. The canopy's corners are `Keyboard`'s squircle and the wheels are `Motorbike01`'s.
  static const AppIconData autoRickshaw = <List<dynamic>>[
    <dynamic>[
      'path',
      <String, String>{
        'key': '0',
        'd': 'M4 16.5V8C4 6.1144 4 5.1716 4.5858 4.5858C5.1716 4 6.1144 4 8 4H13.8C15.35 4 16.12 4 16.75 4.35C17.38 4.7 17.8 5.35 18.62 6.65L20.4 9.5C20.8 10.13 21 10.85 21 11.6V16.5',
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
        'd': 'M9.5 17H16',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '2',
        'd': 'M7.5 7.5C7.5 6.9477 7.9477 6.5 8.5 6.5H13.6C14.08 6.5 14.5 6.78 14.7 7.2L16.5 11H7.5V7.5Z',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '3',
        'd': 'M21 13.5H20',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'circle',
      <String, String>{'key': '4', 'cx': '6.5', 'cy': '18', 'r': '2.5', 'stroke': 'currentColor', 'strokeWidth': '1.5'},
    ],
    <dynamic>[
      'circle',
      <String, String>{'key': '5', 'cx': '18.5', 'cy': '18', 'r': '2.5', 'stroke': 'currentColor', 'strokeWidth': '1.5'},
    ],
  ];

  /// A hookah: the bowl on a stem, a round water base with its water line, and the hose.
  static const AppIconData hookah = <List<dynamic>>[
    <dynamic>[
      'path',
      <String, String>{
        'key': '0',
        'd': 'M10 3.5H14L13.2 6H10.8L10 3.5Z',
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
        'd': 'M8.5 7.5H15.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '2',
        'd': 'M12 6V12.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '3',
        'd': 'M12 12.5C9.2 12.5 7.5 14.6 7.5 17C7.5 19.5 9.3 21 12 21C14.7 21 16.5 19.5 16.5 17C16.5 14.6 14.8 12.5 12 12.5Z',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '4',
        'd': 'M8 17H16',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '5',
        'd': 'M12 10.5H14.5C16.3 10.5 17.3 11.4 17.8 13.2L18.8 17.6C19.1 19 19.9 20 21.5 20',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
  ];

  /// Paan: a betel leaf with its stalk, midrib and veins. The tip is long and pointed so it
  /// reads as a leaf, not `Heart`.
  static const AppIconData paan = <List<dynamic>>[
    <dynamic>[
      'path',
      <String, String>{
        'key': '0',
        'd': 'M12 7C10.8 5.2 8.6 4.3 6.6 5.1C4.1 6.1 3.5 9.4 4.6 12.2C6 15.8 9.1 19 12 21.5C14.9 19 18 15.8 19.4 12.2C20.5 9.4 19.9 6.1 17.4 5.1C15.4 4.3 13.2 5.2 12 7Z',
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
        'd': 'M12 7C12 5.3 12.6 3.6 13.8 2.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '2',
        'd': 'M12 7V17.5',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
    <dynamic>[
      'path',
      <String, String>{
        'key': '3',
        'd': 'M12 10.5C10.5 9.5 8.6 9 7 9.2M12 10.5C13.5 9.5 15.4 9 17 9.2M12 14C10.8 13.2 9.5 12.8 8.3 12.8M12 14C13.2 13.2 14.5 12.8 15.7 12.8',
        'stroke': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
  ];
}
