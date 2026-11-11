import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/focus_ring.dart';

/// One Settings entry: an icon well, its [label] (with an optional [detail] line under it) and an
/// arrow; tapping it opens [onTap]'s page, and a null [onTap] disables it. A [busy] row shows the
/// loading glyph in place of the arrow (D139).
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.label, required this.onTap, this.detail, this.busy = false});

  final AppIconData icon;
  final String label;
  final VoidCallback? onTap;

  /// A second, quieter line, e.g. "₹45,000 · on day 4".
  final String? detail;

  /// Whether the row's request is running, such as a backup being written.
  final bool busy;

  @override
  Widget build(BuildContext context) => FocusRing(
        // why: the row fills a clipping card, so the ring is drawn inside it; its outer corner
        // matches the card's (D99).
        radius: HisaabRadii.card - FocusRing.outset,
        inset: const EdgeInsets.all(FocusRing.outset),
        child: _row(context),
      );

  Widget _row(BuildContext context) => InkWell(
        onTap: onTap,
        focusColor: context.colors.clear,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.m),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
                child: AppIcon(icon),
              ),
              const SizedBox(width: HisaabSpacing.m),
              Expanded(child: _texts(context)),
              AppIcon(busy ? AppIcons.busy : AppIcons.next, color: context.colors.ink2),
            ],
          ),
        ),
      );

  Widget _texts(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? second = detail;
    if (second == null) {
      return Text(label, style: text.bodyLarge);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.bodyLarge),
        Text(second, style: text.bodySmall?.copyWith(color: context.colors.ink2)),
      ],
    );
  }
}
