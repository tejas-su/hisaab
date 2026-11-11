import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// A question's title on the category sheet, with a back well when [onBack] is set.
class CategorySheetTitle extends StatelessWidget {
  const CategorySheetTitle({super.key, required this.question, this.onBack});

  final String question;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? back = onBack;
    return Row(
      children: <Widget>[
        if (back != null)
          Pressable(
            key: const ValueKey<String>('category-sheet-back'),
            semanticLabel: AppLocalizations.of(context).back,
            onPressed: back,
            builder: (BuildContext context, bool pressed) => Container(
              width: HisaabSizes.minTouchTarget,
              height: HisaabSizes.minTouchTarget,
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: HisaabSizes.iconWell,
                height: HisaabSizes.iconWell,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.chip)),
                child: const AppIcon(AppIcons.back),
              ),
            ),
          ),
        Expanded(child: Text(question, style: Theme.of(context).textTheme.titleLarge)),
      ],
    );
  }
}
