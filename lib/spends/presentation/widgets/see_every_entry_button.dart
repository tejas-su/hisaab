import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The text link that opens every entry of a cycle (SPEC FR-SP-6), ending on its card's content edge.
///
/// Shows [label] ("See all", "See every entry"); TalkBack reads "Every entry in [cycleLabel]".
class SeeEveryEntryButton extends StatelessWidget {
  const SeeEveryEntryButton({super.key, required this.label, required this.cycleLabel, required this.onPressed});

  final String label;

  /// The cycle as the switcher names it ("October").
  final String cycleLabel;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        // why: without its own node, a plain sentence beside it is merged into the button's label.
        container: true,
        label: AppLocalizations.of(context).everyEntryIn(cycleLabel),
        button: true,
        excludeSemantics: true,
        child: TextButton(
          key: const ValueKey<String>('see-every-entry'),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: context.colors.ink,
            minimumSize: const Size(HisaabSizes.minTouchTarget, HisaabSizes.minTouchTarget),
            // why: no inset, so the label ends on the card's content edge, as Home's See all does.
            padding: EdgeInsetsDirectional.zero,
            // why: the label can be narrower than the 48dp target; centred, it would end short of the edge.
            alignment: AlignmentDirectional.centerEnd,
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15)),
        ),
      );
}
