import 'dart:ui' show PathMetric;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The dashed *New* tile after the categories: a place for a category, not one (FR-AD-9 AC-1).
///
/// It has a 1.5dp dashed `ink2` edge and no fill, so it never reads as a tile that saves.
class NewCategoryTile extends StatelessWidget {
  const NewCategoryTile({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Pressable(
      key: const ValueKey<String>('new-category'),
      semanticLabel: strings.newCategory,
      onPressed: onPressed,
      focusRadius: HisaabRadii.tile,
      builder: (BuildContext context, bool pressed) => CustomPaint(
        painter: _DashedEdge(color: context.colors.ink2),
        child: Container(
          constraints: const BoxConstraints(minHeight: HisaabSizes.tileHeight),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.xs, vertical: HisaabSpacing.s),
          decoration: BoxDecoration(
            color: pressed ? context.colors.sunk : null,
            borderRadius: BorderRadius.circular(HisaabRadii.tile),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const AppIcon(AppIcons.add),
              const SizedBox(height: 6),
              Text(strings.newCategoryTile, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle edge just inside the tile's bounds.
class _DashedEdge extends CustomPainter {
  const _DashedEdge({required this.color});

  final Color color;

  static const double _stroke = 1.5;
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final Rect rect = (Offset.zero & size).deflate(_stroke / 2);
    final Path edge = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(HisaabRadii.tile)));
    for (final PathMetric metric in edge.computeMetrics()) {
      for (double start = 0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedEdge oldDelegate) => oldDelegate.color != color;
}
