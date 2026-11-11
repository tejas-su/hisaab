import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/categories_bloc.dart';
import '../bloc/categories_event.dart';

/// The category sheet at rest (FR-SE-2 AC-2 to AC-4): icon and name, *Name* and *Icon* rows,
/// then *Hide* for the user's own or a note for a built-in one.
///
/// [flashed] is the row (`name` or `icon`) whose answer was just saved; it flashes `sunk` once.
class CategorySheetSummary extends StatelessWidget {
  const CategorySheetSummary({super.key, required this.category, required this.onRename, required this.onChangeIcon, this.flashed});

  final Category category;
  final VoidCallback onRename;
  final VoidCallback onChangeIcon;
  final String? flashed;

  static const double _wellSize = 56;
  static const double _rowHeight = 56;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String name = category.labelIn(strings);
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? quiet = text.bodyMedium?.copyWith(color: context.colors.ink2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MergeSemantics(
          child: Row(
            children: <Widget>[
              Container(
                width: _wellSize,
                height: _wellSize,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.tile)),
                child: AppIcon(AppIcons.forKey(category.iconKey), size: 28),
              ),
              const SizedBox(width: HisaabSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(category.isOwn ? strings.ownCategoriesRule : strings.categoryBuiltIn, style: quiet),
                    Text(name, style: text.headlineSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HisaabSpacing.l),
        Material(
          color: context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.card),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              _row(context, 'name', strings.categoryNameRow, Text(name), onRename),
              Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline),
              _row(context, 'icon', strings.categoryIconRow, AppIcon(AppIcons.forKey(category.iconKey), size: 20), onChangeIcon),
            ],
          ),
        ),
        const SizedBox(height: HisaabSpacing.l),
        if (category.isOwn) ...<Widget>[
          HisaabChip(
            key: const ValueKey<String>('hide-category'),
            label: strings.hideCategory(name),
            icon: AppIcons.hide,
            expand: true,
            onPressed: () {
              context.read<CategoriesBloc>().add(CategoryHideRequested(category.id));
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: HisaabSpacing.s),
          Text(strings.hideCategoryNote, style: quiet),
        ] else
          Text(category.customName == null ? strings.builtInNote : strings.builtInRenamedNote(strings.categoryName(category.key)), style: quiet),
      ],
    );
  }

  Widget _row(BuildContext context, String which, String label, Widget value, VoidCallback onTap) => Pressable(
        key: ValueKey<String>('category-$which-row'),
        semanticLabel: label,
        onPressed: onTap,
        builder: (BuildContext context, bool pressed) => TweenAnimationBuilder<double>(
          key: ValueKey<bool>(flashed == which),
          tween: Tween<double>(begin: flashed == which ? 1 : 0, end: 0),
          duration: HisaabMotion.reduceMotion(context) ? HisaabMotion.reducedCrossfade : HisaabMotion.numberRoll,
          builder: (BuildContext context, double flash, Widget? child) => Container(
            color: pressed ? context.colors.sunk : Color.lerp(context.colors.surface, context.colors.sunk, flash),
            constraints: const BoxConstraints(minHeight: _rowHeight),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
            child: child,
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
              DefaultTextStyle.merge(style: Theme.of(context).textTheme.labelLarge, child: value),
              const SizedBox(width: HisaabSpacing.s),
              AppIcon(AppIcons.next, size: 18, color: context.colors.ink2),
            ],
          ),
        ),
      );
}
