import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/category_tile.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'date_chip.dart';
import 'new_category_tile.dart';
import 'own_categories_full_line.dart';
import 'own_categories_rule.dart';
import 'note_chip.dart';
import 'tray_step_title.dart';

/// Step 2 of the tray: "What was it for?" as a fixed grid of tiles; tapping one saves (FR-AD-5).
///
/// On *Spent*, the user's own categories follow the 8 on row 3, then a *New* tile while fewer
/// than 4 are shown (FR-AD-9, D138).
///
/// Date and note are optional chips. In edit mode a Delete chip appears (FR-AD-8).
class CategoryStep extends StatelessWidget {
  const CategoryStep({super.key, required this.state});

  final AddEntryState state;

  static const int _columns = 4;

  /// Rows the 8 built-in *Spent* tiles fill.
  static const int _builtInRows = 2;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AddEntryBloc bloc = context.read<AddEntryBloc>();
    final EntryForm form = state.form;
    final AddEntryState current = state;
    final int? flashed = switch (current) {
      AddEntrySaving(:final int? categoryId) => categoryId,
      AddEntryFinished(:final int? categoryId) => categoryId,
      AddEntryEditing() => null,
    };
    final bool saving = current is! AddEntryEditing;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TrayStepTitle(
            amount: form.amount,
            question: form.kind == EntryKind.spent ? strings.whatWasItFor : strings.whereFrom,
            backLabel: strings.backToAmount,
            onBack: () => bloc.add(const AddEntryBackPressed()),
          ),
          const SizedBox(height: 18),
          _grid(
            context,
            strings,
            _cells(form),
            flashed,
            saving ? null : (int categoryId) => bloc.add(AddEntryCategoryPicked(categoryId)),
            saving ? null : () => bloc.add(const AddEntryNewCategoryOpened()),
          ),
          if (form.kind == EntryKind.spent && !form.canAddOwn) ...<Widget>[
            const SizedBox(height: HisaabSpacing.m),
            const OwnCategoriesFullLine(),
          ],
          const SizedBox(height: 18),
          // why: the chips span exactly the tile grid's width; the note takes what the date
          // leaves, so the row's right edge meets the tiles'. Delete gets its own line, so
          // three chips never crowd one row at large text sizes.
          Row(
            children: <Widget>[
              DateChip(date: form.date, today: form.today, earliest: form.earliestDate, onChanged: (CalendarDate date) => bloc.add(AddEntryDateChanged(date))),
              const SizedBox(width: HisaabSpacing.s),
              Expanded(child: NoteChip(note: form.note, onChanged: (String note) => bloc.add(AddEntryNoteChanged(note)))),
            ],
          ),
          if (form.editing.isSome()) ...<Widget>[
            const SizedBox(height: HisaabSpacing.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: HisaabChip(key: const ValueKey<String>('delete-entry'), label: strings.delete, icon: AppIcons.delete, onSurface: true, onPressed: () => bloc.add(const AddEntryDeleteRequested())),
            ),
          ],
          if (current is AddEntryEditing && current.failed) ...<Widget>[
            const SizedBox(height: HisaabSpacing.m),
            Text(strings.couldntSave, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ],
        ],
      ),
    );
  }

  /// The tiles in order, with `null` standing for the *New* tile after the last one (D138).
  static List<Category?> _cells(EntryForm form) => <Category?>[...form.tiles, if (form.canAddOwn) null];

  Widget _grid(
    BuildContext context,
    AppLocalizations strings,
    List<Category?> cells,
    int? flashed,
    ValueChanged<int>? onPick,
    VoidCallback? onNew,
  ) =>
      Column(
        children: <Widget>[
          for (int row = 0; row * _columns < cells.length; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: 10),
            // why: the user's own start on row 3, under a quiet label, so the 8 built-in tiles
            // keep their places and the eye knows where the user's own begin (D138).
            if (row == _builtInRows && cells.length > _builtInRows * _columns) const OwnCategoriesRule(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int column = 0; column < _columns; column++) ...<Widget>[
                  if (column > 0) const SizedBox(width: 10),
                  Expanded(child: _cell(strings, cells, row * _columns + column, flashed, onPick, onNew)),
                ],
              ],
            ),
          ],
        ],
      );

  Widget _cell(AppLocalizations strings, List<Category?> cells, int index, int? flashed, ValueChanged<int>? onPick, VoidCallback? onNew) {
    if (index >= cells.length) {
      return const SizedBox.shrink();
    }
    final Category? category = cells[index];
    return category == null ? NewCategoryTile(onPressed: onNew) : _tile(strings, category, flashed, onPick);
  }

  Widget _tile(AppLocalizations strings, Category category, int? flashed, ValueChanged<int>? onPick) {
    final String label = category.labelIn(strings);
    return CategoryTile(
      key: ValueKey<String>('tile-${category.key}'),
      icon: AppIcons.forKey(category.iconKey),
      label: label,
      semanticLabel: strings.saveToCategory(label),
      flashed: category.id == flashed,
      onPressed: onPick == null ? null : () => onPick(category.id),
    );
  }
}
