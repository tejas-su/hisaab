import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The *Delete everything* page's "This goes:" card: each kind of data with its glyph, ending in
/// "Once it's deleted, there's no getting it back." (SPEC FR-SE-4 AC-4).
class DeleteEverythingList extends StatelessWidget {
  const DeleteEverythingList({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final List<(AppIconData, String)> items = <(AppIconData, String)>[
      (AppIcons.note, strings.deleteAllItemEntries),
      (AppIcons.forKey('salary'), strings.deleteAllItemIncome),
      (AppIcons.recurring, strings.deleteAllItemBills),
      (AppIcons.saving, strings.deleteAllItemSavings),
      (AppIcons.forKey('tag'), strings.deleteAllItemCategories),
      (AppIcons.settings, strings.deleteAllItemSettings),
    ];
    return DecoratedBox(
      decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
      child: Padding(
        padding: const EdgeInsets.all(HisaabSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(header: true, child: Text(strings.deleteAllListTitle, style: text.titleMedium)),
            const SizedBox(height: HisaabSpacing.s),
            ...items.map(
              ((AppIconData, String) item) => Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.xs),
                child: Row(
                  children: <Widget>[
                    ExcludeSemantics(child: AppIcon(item.$1, size: 20)),
                    const SizedBox(width: HisaabSpacing.m),
                    Expanded(child: Text(item.$2, style: text.bodyLarge)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: HisaabSpacing.s),
            Text(strings.deleteAllNoUndo, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
