import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';

/// +₹10 +₹20 +₹50 +₹100 +₹500: chips that add to the amount, like counting notes (FR-AD-1).
class QuickAddChips extends StatelessWidget {
  const QuickAddChips({super.key, required this.onAdd});

  final ValueChanged<int> onAdd;

  static const List<int> amounts = <int>[10, 20, 50, 100, 500];
  static const double _gap = 6;
  static const double _wrapBelowWidth = 280;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    Widget chip(int rupees) => HisaabChip(
      key: ValueKey<String>('quick-$rupees'),
      onSurface: true,
      label: strings.quickAdd(context.money.format(Money.fromMajor(rupees))),
      semanticLabel: strings.quickAddSpoken(strings.spokenAmount('$rupees')),
      onPressed: () => onAdd(rupees),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        // why: in a narrow half (split screen) five chips in one row would be too thin to read.
        if (box.maxWidth < _wrapBelowWidth) {
          return Wrap(spacing: _gap, runSpacing: _gap, children: <Widget>[for (final int rupees in amounts) chip(rupees)]);
        }
        return Row(
          children: <Widget>[
            for (final (int index, int rupees) in amounts.indexed) ...<Widget>[
              if (index > 0) const SizedBox(width: _gap),
              Expanded(child: chip(rupees)),
            ],
          ],
        );
      },
    );
  }
}
