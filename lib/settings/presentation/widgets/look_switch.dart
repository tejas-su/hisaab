import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../domain/entities/theme_choice.dart';
import 'look_choice.dart';

/// Match phone | Light | Dark as three 48dp icon buttons on a `sunk` track (SPEC FR-SE-3, D130).
/// The pick fills `ink` with its glyph in `bg`; each button is labelled for TalkBack, and the
/// tile beside it names the current look in words.
class LookSwitch extends StatelessWidget {
  const LookSwitch({super.key, required this.picked, required this.onPicked});

  final ThemeChoice picked;
  final ValueChanged<ThemeChoice> onPicked;

  /// The toggle's fixed width: three buttons, two gaps and the track's inset.
  static const double width = HisaabSizes.minTouchTarget * 3 + HisaabSpacing.xs * 4;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey<String>('look-track'),
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.xs),
        decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.key)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: HisaabSpacing.xs,
          children: <Widget>[for (final ThemeChoice choice in ThemeChoice.values) _button(context, choice)],
        ),
      );

  Widget _button(BuildContext context, ThemeChoice choice) {
    final bool selected = choice == picked;
    final LookChoice look = LookChoice.of(context, choice);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        semanticLabel: look.spoken ?? look.label,
        selected: selected,
        focusRadius: HisaabRadii.chip,
        onPressed: () => onPicked(choice),
        builder: (BuildContext context, bool pressed) => Container(
          key: ValueKey<String>('look-${choice.name}'),
          width: HisaabSizes.minTouchTarget,
          height: HisaabSizes.minTouchTarget,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? context.colors.ink : (pressed ? context.colors.hairline : null),
            shape: HisaabShapes.squircle(HisaabRadii.chip),
          ),
          child: AppIcon(look.icon, color: selected ? context.colors.background : context.colors.ink),
        ),
      ),
    );
  }
}
