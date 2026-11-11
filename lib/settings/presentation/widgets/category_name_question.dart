import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/categories_event.dart';
import '../bloc/categories_state.dart';
import 'category_sheet_title.dart';

/// The name question on the category sheet: rename [category], or with no category, add one of
/// the user's own with its icon picked from the name (FR-SE-2 AC-2, AC-5).
///
/// [controller] belongs to the sheet; [onSave] receives the event to send.
class CategoryNameQuestion extends StatelessWidget {
  const CategoryNameQuestion({
    super.key,
    required this.controller,
    required this.categories,
    required this.labels,
    required this.onChanged,
    required this.onSave,
    required this.onOpenIcons,
    this.category,
    this.draftIcon,
    this.waiting = false,
    this.problem,
    this.onBack,
  });

  final TextEditingController controller;

  /// Every category, hidden ones included, for matching a typed name.
  final List<Category> categories;

  /// Each category's shown name by id.
  final Map<int, String> labels;
  final VoidCallback onChanged;
  final ValueChanged<CategoriesEvent> onSave;
  final VoidCallback onOpenIcons;
  final Category? category;

  /// The icon picked while adding; null follows the name.
  final String? draftIcon;
  final bool waiting;
  final CategoryProblem? problem;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Category? renaming = category;
    final String typed = controller.text.trim();
    final Category? match = typed.isEmpty || renaming != null
        ? null
        : CategoryName.match(typed, categories.where((Category c) => c.kind == EntryKind.spent).toList(), labels).toNullable();
    final String icon = draftIcon ?? CategoryIcon.forName(typed);
    final bool blocked = typed.isEmpty || waiting || (match != null && !match.hidden);
    final VoidCallback? save = blocked
        ? null
        : () => onSave(
              renaming == null
                  ? CategoryAddRequested(name: typed, iconKey: icon, labels: labels)
                  : CategoryRenameRequested(id: renaming.id, name: typed, labels: labels),
            );
    final CategoryProblem? shown = waiting ? null : problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CategorySheetTitle(question: renaming == null ? strings.newCategoryQuestion : strings.renameCategoryQuestion, onBack: onBack),
        const SizedBox(height: HisaabSpacing.l),
        TextField(
          key: const ValueKey<String>('category-name-field'),
          controller: controller,
          autofocus: true,
          maxLength: OwnCategories.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (String _) => onChanged(),
          onSubmitted: (String _) => save?.call(),
          onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(labelText: strings.newCategoryFieldLabel, hintText: strings.newCategoryHint),
        ),
        if (renaming == null) _addLine(context, strings, match, icon, typed),
        if (shown != null) ...<Widget>[
          const SizedBox(height: HisaabSpacing.s),
          Text(_problemText(strings, shown), key: const ValueKey<String>('category-problem'), style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: HisaabSpacing.l),
        SignalKey(
          key: const ValueKey<String>('category-name-save'),
          label: renaming != null || typed.isEmpty
              ? strings.save
              : match != null && match.hidden
                  ? strings.bringBackCategory(labels[match.id] ?? typed)
                  : strings.addCategoryKey(typed),
          onPressed: save,
        ),
      ],
    );
  }

  /// While adding: what the typed name already belongs to, or the icon it picks and *Change*.
  Widget _addLine(BuildContext context, AppLocalizations strings, Category? match, String icon, String typed) {
    final TextStyle? quiet = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    if (match != null) {
      final String name = labels[match.id] ?? typed;
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.s),
        child: Text(match.hidden ? strings.categoryComesBack(name) : strings.categoryExists(name), style: quiet),
      );
    }
    final String word = strings.categoryIconName(icon);
    final String line = draftIcon != null
        ? strings.categoryIconPicked(word)
        : typed.isEmpty
            ? strings.categoryIconWaiting
            : icon == CategoryIcon.fallback
                ? strings.categoryIconNoMatch
                : strings.categoryIconFromName(word);
    return Pressable(
      key: const ValueKey<String>('category-add-icon-line'),
      semanticLabel: strings.categoryIconSemantics(word),
      onPressed: onOpenIcons,
      builder: (BuildContext context, bool pressed) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
        child: Row(
          children: <Widget>[
            AppIcon(AppIcons.forKey(icon)),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(child: Text(line, style: quiet)),
            Text(strings.changeIcon, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }

  static String _problemText(AppLocalizations strings, CategoryProblem problem) => switch (problem) {
        CategoryProblem.nameTaken => strings.categoryNameTaken,
        CategoryProblem.full => strings.ownCategoriesFull,
        CategoryProblem.invalidName => strings.categoryNameInvalid,
        CategoryProblem.failed => strings.couldntSave,
      };
}
