import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'new_category_icon_line.dart';
import 'new_category_name_chips.dart';
import 'tray_step_title.dart';

/// The new-category name step inside the tray: a name field, a line naming the icon the name
/// picks, name chips, and *Save in {name}*, which files the entry there (FR-AD-9 AC-2 to AC-4).
///
/// The text field's controller is this widget's own leaf state.
class NewCategoryNameStep extends StatefulWidget {
  const NewCategoryNameStep({super.key, required this.state});

  final AddEntryState state;

  @override
  State<NewCategoryNameStep> createState() => _NewCategoryNameStepState();
}

class _NewCategoryNameStepState extends State<NewCategoryNameStep> {
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
          NewCategoryIconLine(form: form, labels: labels, match: match),
          NewCategoryNameChips(
            typed: name,
            shown: <String>{
              for (final Category c in bloc.categories)
                if (!c.hidden && c.kind == EntryKind.spent) (labels[c.id] ?? '').toLowerCase(),
            },
            onPicked: _fill,
          ),
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
}
