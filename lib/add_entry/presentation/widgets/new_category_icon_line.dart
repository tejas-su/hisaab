import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';

/// The line under the new-category name: the category the name already belongs to, or the icon
/// the new one will get with *Change* to pick another (FR-AD-9 AC-3, AC-4).
class NewCategoryIconLine extends StatelessWidget {
  const NewCategoryIconLine({super.key, required this.form, required this.labels, this.match});

  final EntryForm form;

  /// Each category's shown name by id.
  final Map<int, String> labels;

  /// The category the typed name already belongs to, if any.
  final Category? match;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    final Category? found = match;
    if (found != null) {
      final String label = labels[found.id] ?? '';
      return _line(
        context,
        AppIcons.forKey(found.iconKey),
        Text(found.hidden ? strings.categoryComesBack(label) : strings.categoryExists(label), style: style),
      );
    }
    final String key = form.draftIconKey;
    final String word = strings.categoryIconName(key);
    return Pressable(
      key: const ValueKey<String>('category-icon-line'),
      semanticLabel: strings.categoryIconSemantics(word),
      onPressed: () => context.read<AddEntryBloc>().add(const AddEntryIconStepOpened()),
      builder: (BuildContext context, bool pressed) => _line(
        context,
        AppIcons.forKey(key),
        Text(_words(strings, key, word), style: style),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strings.changeIcon, style: Theme.of(context).textTheme.labelLarge),
            const AppIcon(AppIcons.next, size: 18),
          ],
        ),
      ),
    );
  }

  String _words(AppLocalizations strings, String key, String word) {
    if (form.draftIcon.isSome()) {
      return strings.categoryIconPicked(word);
    }
    if (form.draftName.trim().isEmpty) {
      return strings.categoryIconWaiting;
    }
    return key == CategoryIcon.fallback ? strings.categoryIconNoMatch : strings.categoryIconFromName(word);
  }

  Widget _line(BuildContext context, AppIconData icon, Widget text, {Widget? trailing}) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
        child: Row(
          children: <Widget>[
            Container(
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.chip)),
              child: AppIcon(icon),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(child: text),
            ?trailing,
          ],
        ),
      );
}
