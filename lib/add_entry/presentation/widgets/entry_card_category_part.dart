import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/category_tile.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';
import 'new_category_tile.dart';
import 'own_categories_full_line.dart';
import 'own_categories_rule.dart';

/// The entry card's category grid: step 2's tiles in their places, the user's own under "Your own",
/// then *New* (SPEC FR-AD-8 AC-4). The entry's category is outlined with a check; a tap moves it.
class EntryCardCategoryPart extends StatelessWidget {
  const EntryCardCategoryPart({super.key, required this.form});

  final EntryCardForm form;

  static const int _columns = 4;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final List<Category> tiles = form.tiles;
    final List<Category> builtIn = tiles.where((Category c) => !c.isOwn).toList();
    final List<Category> own = tiles.where((Category c) => c.isOwn).toList();
    final bool spent = form.original.kind == EntryKind.spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _rows(context, builtIn.map((Category c) => _tile(context, c)).toList()),
        if (spent && (own.isNotEmpty || form.canAddOwn)) ...<Widget>[
          const OwnCategoriesRule(),
          _rows(context, <Widget>[
            ...own.map((Category c) => _tile(context, c)),
            if (form.canAddOwn)
              NewCategoryTile(onPressed: () => context.read<EntryCardBloc>().add(const EntryCardPartTapped(CardPart.naming))),
          ]),
        ],
        if (spent && !form.canAddOwn) ...<Widget>[const SizedBox(height: HisaabSpacing.m), const OwnCategoriesFullLine()],
      ],
    );
  }

  Widget _rows(BuildContext context, List<Widget> cells) => Column(
        children: <Widget>[
          for (int start = 0; start < cells.length; start += _columns) ...<Widget>[
            if (start > 0) const SizedBox(height: _gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int column = 0; column < _columns; column++) ...<Widget>[
                  if (column > 0) const SizedBox(width: _gap),
                  Expanded(child: start + column < cells.length ? cells[start + column] : const SizedBox.shrink()),
                ],
              ],
            ),
          ],
        ],
      );

  Widget _tile(BuildContext context, Category category) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String label = category.labelIn(strings);
    final bool current = category.id == form.categoryId;
    return CategoryTile(
      key: ValueKey<String>('card-tile-${category.id}'),
      icon: AppIcons.forKey(category.iconKey),
      label: label,
      current: current,
      semanticLabel: current ? strings.entryCardNow(label) : label,
      onPressed: () => context.read<EntryCardBloc>().add(EntryCardCategoryPicked(category.id)),
    );
  }

  /// Whether [form]'s grid is the open part; the board uses it to ring its column.
  static bool isOpen(EntryCardForm form) => form.part == const Option<CardPart>.of(CardPart.category);
}
