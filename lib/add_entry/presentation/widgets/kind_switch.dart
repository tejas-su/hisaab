import '../../../core/design/hisaab_type.dart';
import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The Spent | Got segmented control; Spent is the default (SPEC FR-AD-1).
class KindSwitch extends StatelessWidget {
  const KindSwitch({super.key, required this.kind, required this.onChanged});

  final EntryKind kind;
  final ValueChanged<EntryKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      label: strings.moneyOutOrIn,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.xs),
        decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.key)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _segment(context, EntryKind.spent, strings.spent),
            const SizedBox(width: HisaabSpacing.xs),
            _segment(context, EntryKind.got, strings.got),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, EntryKind value, String label) {
    final bool selected = value == kind;
    // why: light layers alternate (D47), so the pick rises out of the sunk track as a light
    // pill; in dark, where surface is darker than sunk, it stays an ink pill.
    final bool light = Theme.of(context).brightness == Brightness.light;
    final Color selectedFill = light ? context.colors.surface : context.colors.ink;
    final Color selectedText = light ? context.colors.ink : context.colors.background;
    return Pressable(
      key: ValueKey<String>('kind-${value.name}'),
      semanticLabel: label,
      selected: selected,
      onPressed: () => onChanged(value),
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minWidth: 112, minHeight: HisaabSizes.minTouchTarget),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: selected ? selectedFill : null,
          shape: HisaabShapes.squircle(HisaabRadii.chip),
        ),
        child: Text(
          label,
          // why: the pick is one weight step up and the other steps back by colour (D68).
          style: (selected
                  ? HisaabType.emphasized(Theme.of(context).textTheme.titleMedium)
                  : HisaabType.regular(Theme.of(context).textTheme.titleMedium))
              ?.copyWith(color: selected ? selectedText : context.colors.ink2),
        ),
      ),
    );
  }
}
