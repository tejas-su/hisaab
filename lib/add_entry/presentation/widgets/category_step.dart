import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_tile.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'date_chip.dart';
import 'note_chip.dart';

/// Step 2 of the tray: "What was it for?" as a fixed grid of tiles; tapping one saves (FR-AD-5).
///
/// Date and note are optional chips. In edit mode a Delete chip appears (FR-AD-8).
class CategoryStep extends StatelessWidget {
  const CategoryStep({super.key, required this.state});

  final AddEntryState state;

  static const int _columns = 4;
  static const double _wellMargin = (HisaabSizes.minTouchTarget - HisaabSizes.iconWell) / 2;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AddEntryBloc bloc = context.read<AddEntryBloc>();
    final EntryForm form = state.form;
    final AddEntryState current = state;
    final int? flashed = switch (current) {
      AddEntrySaving(:final int categoryId) => categoryId,
      AddEntryFinished(:final int? categoryId) => categoryId,
      AddEntryEditing() => null,
    };
    final bool saving = current is! AddEntryEditing;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _title(context, strings, bloc, form),
          const SizedBox(height: 18),
          _grid(context, strings, form.tiles, flashed, saving ? null : (int categoryId) => bloc.add(AddEntryCategoryPicked(categoryId))),
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

  Widget _title(BuildContext context, AppLocalizations strings, AddEntryBloc bloc, EntryForm form) => Row(
        children: <Widget>[
          Pressable(
            key: const ValueKey<String>('back-to-amount'),
            semanticLabel: strings.backToAmount,
            onPressed: () => bloc.add(const AddEntryBackPressed()),
            focusInset: const EdgeInsetsDirectional.only(top: _wellMargin, end: 2 * _wellMargin, bottom: _wellMargin),
            // why: same well as Home's Settings button, at the start so it lines up with the tiles.
            builder: (BuildContext context, bool pressed) => Container(
              width: HisaabSizes.minTouchTarget,
              height: HisaabSizes.minTouchTarget,
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                key: const ValueKey<String>('back-to-amount-well'),
                width: HisaabSizes.iconWell,
                height: HisaabSizes.iconWell,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.chip)),
                child: const AppIcon(AppIcons.back),
              ),
            ),
          ),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AmountText(form.amount, roll: false, style: Theme.of(context).textTheme.displaySmall),
                Text(
                  form.kind == EntryKind.spent ? strings.whatWasItFor : strings.whereFrom,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.colors.ink2),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _grid(
    BuildContext context,
    AppLocalizations strings,
    List<Category> tiles,
    int? flashed,
    ValueChanged<int>? onPick,
  ) =>
      Column(
        children: <Widget>[
          for (int row = 0; row * _columns < tiles.length; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int column = 0; column < _columns; column++) ...<Widget>[
                  if (column > 0) const SizedBox(width: 10),
                  Expanded(child: _tile(strings, tiles, row * _columns + column, flashed, onPick)),
                ],
              ],
            ),
          ],
        ],
      );

  Widget _tile(AppLocalizations strings, List<Category> tiles, int index, int? flashed, ValueChanged<int>? onPick) {
    if (index >= tiles.length) {
      return const SizedBox.shrink();
    }
    final Category category = tiles[index];
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
