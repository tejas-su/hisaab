import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/widgets/category_icon_grid.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';
import 'new_category_name_chips.dart';

/// Names a new category inside the card, in the grid's place (SPEC FR-AD-8 AC-5): *‹ Categories*,
/// the name field and chips, the icon line with *Change*, and "Move to {name}".
class EntryCardNamingPart extends StatefulWidget {
  const EntryCardNamingPart({super.key, required this.form});

  final EntryCardForm form;

  @override
  State<EntryCardNamingPart> createState() => _EntryCardNamingPartState();
}

class _EntryCardNamingPartState extends State<EntryCardNamingPart> {
  late final TextEditingController _controller = TextEditingController(text: widget.form.draftName);
  bool _icons = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fill(String name) {
    _controller.text = name;
    context.read<EntryCardBloc>().add(EntryCardNameChanged(name));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final EntryCardBloc bloc = context.read<EntryCardBloc>();
    final EntryCardForm form = widget.form;
    final List<Category> spent = form.categories.where((Category c) => c.kind == EntryKind.spent).toList();
    final Map<int, String> labels = <int, String>{for (final Category c in spent) c.id: c.labelIn(strings)};
    final String name = form.draftName.trim();
    final Category? match = name.isEmpty ? null : CategoryName.match(name, spent, labels).toNullable();
    final String target = match == null ? name : labels[match.id] ?? name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey<String>('entry-card-back-to-grid'),
            onPressed: () => bloc.add(const EntryCardPartTapped(CardPart.category)),
            icon: const AppIcon(AppIcons.back, size: 18),
            label: Text(strings.entryCardCategories),
          ),
        ),
        Text(strings.newCategoryQuestion, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HisaabSpacing.s),
        TextField(
          key: const ValueKey<String>('entry-card-name'),
          controller: _controller,
          autofocus: true,
          maxLength: OwnCategories.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (String typed) => bloc.add(EntryCardNameChanged(typed)),
          onSubmitted: (String _) => name.isEmpty ? null : bloc.add(EntryCardNewCategorySaved(labels)),
          decoration: InputDecoration(labelText: strings.newCategoryFieldLabel, hintText: strings.newCategoryHint),
        ),
        _iconLine(context, strings, form, match),
        if (_icons && match == null)
          CategoryIconGrid(
            picked: form.draftIconKey,
            suggested: CategoryIcon.forName(name),
            onPicked: (String key) {
              setState(() => _icons = false);
              bloc.add(EntryCardIconPicked(key));
            },
          ),
        NewCategoryNameChips(
          typed: name,
          shown: <String>{for (final Category c in spent) if (!c.hidden) (labels[c.id] ?? '').toLowerCase()},
          onPicked: _fill,
        ),
        const SizedBox(height: HisaabSpacing.m),
        SignalKey(
          key: const ValueKey<String>('entry-card-move'),
          label: name.isEmpty ? strings.entryCardTypeName : strings.entryCardMoveTo(target),
          onPressed: name.isEmpty ? null : () => bloc.add(EntryCardNewCategorySaved(labels)),
        ),
      ],
    );
  }

  Widget _iconLine(BuildContext context, AppLocalizations strings, EntryCardForm form, Category? match) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    if (match != null) {
      return Text(strings.entryCardCategoryExists(match.labelIn(strings)), style: style);
    }
    final String word = strings.categoryIconName(form.draftIconKey);
    final String line = form.draftName.trim().isEmpty
        ? strings.categoryIconWaiting
        : form.draftIcon.isSome()
            ? strings.categoryIconPicked(word)
            : strings.categoryIconFromName(word);
    return Row(
      children: <Widget>[
        AppIcon(AppIcons.forKey(form.draftIconKey)),
        const SizedBox(width: HisaabSpacing.s),
        Expanded(child: Text(line, style: style)),
        TextButton(
          key: const ValueKey<String>('entry-card-change-icon'),
          onPressed: () => setState(() => _icons = !_icons),
          child: Semantics(label: strings.categoryIconSemantics(word), excludeSemantics: true, child: Text(strings.changeIcon)),
        ),
      ],
    );
  }
}
