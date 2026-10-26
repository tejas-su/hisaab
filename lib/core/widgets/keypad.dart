import 'package:flutter/material.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../money/amount_input.dart';
import '../../l10n/gen/app_localizations.dart';
import 'keypad_key.dart';

/// The phone-layout amount keypad: 1-2-3 on top, then `00 · 0 · ⌫` (UI_DESIGN §5.3).
///
/// No decimal key, by design (DECISIONS D12). Keys never move (D13). Long-press ⌫ clears.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    this.keyHeight = HisaabSizes.keypadKeyHeight,
  });

  /// Called with `0`–`9` or `00`.
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// Minimum key height; 64dp normally, less in short windows.
  final double keyHeight;

  static const double _gap = HisaabSpacing.s;

  @override
  Widget build(BuildContext context) {
    final List<Widget> keys = <Widget>[
      for (final String key in AmountInput.digitKeys) _digit(context, key),
      KeypadKey(
        semanticLabel: AppLocalizations.of(context).deleteLastDigit,
        height: keyHeight,
        onPressed: onBackspace,
        onLongPress: onClear,
        child: const AppIcon(AppIcons.backspace),
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < 4; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: _gap),
          Row(
            children: <Widget>[
              for (int column = 0; column < 3; column++) ...<Widget>[
                if (column > 0) const SizedBox(width: _gap),
                Expanded(child: keys[row * 3 + column]),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _digit(BuildContext context, String key) => KeypadKey(
        key: ValueKey<String>('keypad-$key'),
        semanticLabel: key,
        height: keyHeight,
        onPressed: () => onKey(key),
        child: Text(
          key,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: key.length > 1 ? 23 : 27, fontWeight: FontWeight.w500),
        ),
      );
}
