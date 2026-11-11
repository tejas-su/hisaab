import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/widgets/category_icon_grid.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'tray_step_title.dart';

/// The new category's icon step: the curated icons in their groups; a tap picks one and returns
/// to the name step without saving (FR-AD-9 AC-3).
class NewCategoryIconStep extends StatelessWidget {
  const NewCategoryIconStep({super.key, required this.form});

  final EntryForm form;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AddEntryBloc bloc = context.read<AddEntryBloc>();
    final String name = form.draftName.trim();
    final String suggested = CategoryIcon.forName(name);
    final bool hasSuggestion = name.isNotEmpty && suggested != CategoryIcon.fallback;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TrayStepTitle(
            amount: form.amount,
            question: strings.pickIconFor(name.isEmpty ? strings.newCategory : name),
            backLabel: strings.back,
            onBack: () => bloc.add(const AddEntryBackPressed()),
          ),
          if (hasSuggestion) ...<Widget>[
            const SizedBox(height: HisaabSpacing.m),
            Text(
              strings.categoryIconFromNameShort(strings.categoryIconName(suggested)),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
            ),
          ],
          CategoryIconGrid(
            picked: form.draftIconKey,
            suggested: hasSuggestion ? suggested : null,
            onPicked: (String key) => bloc.add(AddEntryIconPicked(key)),
          ),
        ],
      ),
    );
  }
}
