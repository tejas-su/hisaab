import 'package:flutter/material.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'hisaab_snackbar.dart';
import 'pressable.dart';

/// The snackbar pill: [snackbar]'s message on `inverse`, and its action as words in the page colour.
///
/// Drawn by `HisaabSnackbarHost`; [onAction] gets the action when it is tapped.
class HisaabSnackbarBar extends StatelessWidget {
  const HisaabSnackbarBar({super.key, required this.snackbar, required this.onAction});

  final HisaabSnackbar snackbar;
  final ValueChanged<HisaabSnackbarAction> onAction;

  @override
  Widget build(BuildContext context) {
    final HisaabSnackbarAction? action = snackbar.action;
    final TextTheme text = Theme.of(context).textTheme;
    final Color onBar = context.colors.background;
    return Container(
      constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget + HisaabSpacing.s),
      padding: EdgeInsetsDirectional.fromSTEB(
        HisaabSpacing.gutter,
        HisaabSpacing.s,
        action == null ? HisaabSpacing.gutter : HisaabSpacing.s,
        HisaabSpacing.s,
      ),
      decoration: ShapeDecoration(color: context.colors.inverse, shape: HisaabShapes.squircle(HisaabRadii.card)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              snackbar.message,
              semanticsLabel: snackbar.semanticsLabel,
              style: text.bodyMedium?.copyWith(color: onBar),
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(width: HisaabSpacing.m),
            // why: its own node, or the button merges into the live region and the message reads as Undo.
            Semantics(
              container: true,
              child: Pressable(
                semanticLabel: action.label,
                onPressed: () => onAction(action),
                builder: (BuildContext _, bool _) => ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: HisaabSizes.minTouchTarget,
                    minHeight: HisaabSizes.minTouchTarget,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.m),
                      child: Text(action.label, style: text.labelLarge?.copyWith(color: onBar)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
