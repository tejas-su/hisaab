import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'tray_step_title.dart';

/// The new-category name step inside the tray: a name field, a line naming the icon the name
/// picks, name chips, and *Save in {name}*, which files the entry there (FR-AD-9 AC-2 to AC-4).
///
/// The text field's controller is this widget's own leaf state.
class NewCategoryNameStep extends StatefulWidget {
  const NewCategoryNameStep({super.key, required this.state});

  final AddEntryState state;

  /// The name chips, by `newCategorySuggestion` key, in order.
  static const List<String> suggestions = <String>['groceries', 'kids', 'family', 'pets', 'petrol', 'salon'];

  @override
  State<NewCategoryNameStep> createState() => _NewCategoryNameStepState();
}

class _NewCategoryNameStepState extends State<NewCategoryNameStep> {
  static const int _chipColumns = 3;

  late final TextEditingController _controller = TextEditingController(text: widget.state.form.draftName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fill(String name) {
    _controller.text = name;
    context.read<AddEntryBloc>().add(AddEntryNewCategoryNameChanged(name));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AddEntryBloc bloc = context.read<AddEntryBloc>();
    final EntryForm form = widget.state.form;
    final Map<int, String> labels = <int, String>{for (final Category c in bloc.categories) c.id: c.labelIn(strings)};
    final String name = form.draftName.trim();
    final Category? match = name.isEmpty
        ? null
        : CategoryName.match(name, bloc.categories.where((Category c) => c.kind == EntryKind.spent).toList(), labels).toNullable();
    final bool saving = widget.state is AddEntrySaving;
    final VoidCallback? save = name.isEmpty || saving ? null : () => bloc.add(AddEntryNewCategorySaved(labels));
    final AddEntryState current = widget.state;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TrayStepTitle(
            amount: form.amount,
            question: strings.newCategoryQuestion,
            backLabel: strings.back,
            onBack: () => bloc.add(const AddEntryBackPressed()),
          ),
          const SizedBox(height: HisaabSpacing.l),
          TextField(
            key: const ValueKey<String>('new-category-name'),
            controller: _controller,
            autofocus: true,
            maxLength: OwnCategories.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (String typed) => bloc.add(AddEntryNewCategoryNameChanged(typed)),
            onSubmitted: (String _) => save?.call(),
            decoration: InputDecoration(labelText: strings.newCategoryFieldLabel, hintText: strings.newCategoryHint),
          ),
          const SizedBox(height: HisaabSpacing.xs),
          _iconLine(context, strings, form, match, labels),
          ..._chips(strings, form, labels),
          const SizedBox(height: HisaabSpacing.l),
          SignalKey(
            key: const ValueKey<String>('save-new-category'),
            label: name.isEmpty ? strings.save : strings.saveInCategory(match == null ? name : labels[match.id] ?? name),
            onPressed: save,
          ),
          if (current is AddEntryEditing && current.failed) ...<Widget>[
            const SizedBox(height: HisaabSpacing.m),
            Text(strings.couldntSave, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ],
        ],
      ),
    );
  }

  /// Says what saving will do: the existing category it goes to, or the icon the new one gets.
  Widget _iconLine(BuildContext context, AppLocalizations strings, EntryForm form, Category? match, Map<int, String> labels) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    if (match != null) {
      final String label = labels[match.id] ?? '';
      return _line(
        context,
        AppIcons.forKey(match.iconKey),
        Text(match.hidden ? strings.categoryComesBack(label) : strings.categoryExists(label), style: style),
      );
    }
    final String key = form.draftIconKey;
    final String word = strings.categoryIconName(key);
    final String text = form.draftIcon.isSome()
        ? strings.categoryIconPicked(word)
        : form.draftName.trim().isEmpty
            ? strings.categoryIconWaiting
            : key == CategoryIcon.fallback
                ? strings.categoryIconNoMatch
                : strings.categoryIconFromName(word);
    return Pressable(
      key: const ValueKey<String>('category-icon-line'),
      semanticLabel: strings.categoryIconSemantics(word),
      onPressed: () => context.read<AddEntryBloc>().add(const AddEntryIconStepOpened()),
      builder: (BuildContext context, bool pressed) => _line(
        context,
        AppIcons.forKey(key),
        Text(text, style: style),
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

  /// The name chips the typed name could still become, leaving out names already shown.
  List<Widget> _chips(AppLocalizations strings, EntryForm form, Map<int, String> labels) {
    final String typed = form.draftName.trim().toLowerCase();
    final Set<String> shown = <String>{
      for (final Category c in context.read<AddEntryBloc>().categories)
        if (!c.hidden && c.kind == EntryKind.spent) (labels[c.id] ?? '').toLowerCase(),
    };
    final List<String> names = <String>[
      for (final String key in NewCategoryNameStep.suggestions)
        if (!shown.contains(strings.newCategorySuggestion(key).toLowerCase()) && strings.newCategorySuggestion(key).toLowerCase().startsWith(typed))
          strings.newCategorySuggestion(key),
    ];
    if (names.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      const SizedBox(height: HisaabSpacing.m),
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = (constraints.maxWidth - HisaabSpacing.s * (_chipColumns - 1)) / _chipColumns;
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
                    selected: name.toLowerCase() == typed,
                    onPressed: () => _fill(name),
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }
}
