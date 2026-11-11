import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The name chips under the new-category field: the common names the typed name could still
/// become, leaving out names already shown, in three columns (FR-AD-9 AC-2).
class NewCategoryNameChips extends StatelessWidget {
  const NewCategoryNameChips({super.key, required this.typed, required this.shown, required this.onPicked});

  /// The name chips, by `newCategorySuggestion` key, in order.
  static const List<String> suggestions = <String>['groceries', 'kids', 'family', 'pets', 'petrol', 'salon'];

  static const int _columns = 3;

  /// What is typed, trimmed.
  final String typed;

  /// The shown names of the categories already in the tray, lower-cased.
  final Set<String> shown;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String lower = typed.toLowerCase();
    final List<String> names = <String>[
      for (final String key in suggestions)
        if (!shown.contains(strings.newCategorySuggestion(key).toLowerCase()) && strings.newCategorySuggestion(key).toLowerCase().startsWith(lower))
          strings.newCategorySuggestion(key),
    ];
    if (names.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = (constraints.maxWidth - HisaabSpacing.s * (_columns - 1)) / _columns;
          return Wrap(
            spacing: HisaabSpacing.s,
            runSpacing: HisaabSpacing.s,
            children: <Widget>[
              for (final String name in names)
                SizedBox(
                  width: width,
                  child: HisaabChip(
                    key: ValueKey<String>('suggest-$name'),
                    label: name,
                    expand: true,
                    onSurface: true,
                    selected: name.toLowerCase() == lower,
                    onPressed: () => onPicked(name),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
