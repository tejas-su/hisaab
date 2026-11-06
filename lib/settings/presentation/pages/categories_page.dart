import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/categories_bloc.dart';
import '../bloc/categories_event.dart';
import '../bloc/categories_state.dart';
import '../widgets/category_sheet.dart';
import '../widgets/settings_row.dart';

/// Settings › Categories (FR-SE-2, D138): the user's own with *Add a category*, then the 8
/// built-in *Spent* categories and the *Got* ones. A row opens [CategorySheet].
///
/// Reads [CategoriesBloc] from above; hiding offers *Undo* in a snackbar.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: HisaabBackButton.leadingWidth,
        leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
        titleSpacing: HisaabSpacing.s,
        title: Text(strings.settingsCategories),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: HisaabSnackbarHost(
          child: BlocConsumer<CategoriesBloc, CategoriesState>(
            listenWhen: (CategoriesState previous, CategoriesState current) => current is CategoriesReady && current.undo.isSome(),
            listener: _offerUndo,
            builder: (BuildContext context, CategoriesState state) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: LayoutBreakpoints.singlePaneMaxWidth),
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.xl),
                  children: _content(context, strings, state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, AppLocalizations strings, CategoriesState state) => switch (state) {
        CategoriesLoading() => const <Widget>[],
        CategoriesFailed() => <Widget>[
            Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
            const SizedBox(height: HisaabSpacing.m),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: HisaabChip(label: strings.tryAgain, onPressed: () => context.read<CategoriesBloc>().add(const CategoriesLoadRequested())),
            ),
          ],
        CategoriesReady(:final List<Category> categories) => _groups(context, strings, categories),
      };

  List<Widget> _groups(BuildContext context, AppLocalizations strings, List<Category> categories) {
    final List<Category> own = categories.where((Category c) => c.isOwn && !c.hidden).toList();
    final List<Category> builtIn = categories.where((Category c) => !c.isOwn && c.kind == EntryKind.spent).toList();
    final List<Category> got = categories.where((Category c) => c.kind == EntryKind.got).toList();
    return <Widget>[
      _heading(context, strings.ownCategoriesRule, detail: strings.categoriesOwnCount(own.length, OwnCategories.max), first: true),
      _card(context, <Widget>[
        for (final Category c in own) _row(context, strings, c),
        if (own.length < OwnCategories.max)
          SettingsRow(
            key: const ValueKey<String>('add-category'),
            icon: AppIcons.add,
            label: strings.addCategory,
            onTap: () => CategorySheet.show(context, context.read<CategoriesBloc>()),
          ),
      ]),
      _heading(context, strings.categoriesSpending),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, bottom: HisaabSpacing.s),
        child: Text(strings.categoriesSpendingHint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2)),
      ),
      _card(context, <Widget>[for (final Category c in builtIn) _row(context, strings, c)]),
      _heading(context, strings.categoriesMoneyIn),
      _card(context, <Widget>[for (final Category c in got) _row(context, strings, c)]),
    ];
  }

  Widget _row(BuildContext context, AppLocalizations strings, Category category) => SettingsRow(
        key: ValueKey<String>('category-${category.key}'),
        icon: AppIcons.forKey(category.iconKey),
        label: category.labelIn(strings),
        detail: !category.isOwn && category.customName != null ? strings.builtInAs(strings.categoryName(category.key)) : null,
        onTap: () => CategorySheet.show(context, context.read<CategoriesBloc>(), id: category.id),
      );

  Widget _heading(BuildContext context, String title, {String? detail, bool first = false}) => Padding(
        padding: EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: first ? 0 : HisaabSpacing.xl, bottom: HisaabSpacing.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (detail != null) ...<Widget>[
              const SizedBox(width: HisaabSpacing.s),
              Text(detail, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2)),
            ],
          ],
        ),
      );

  Widget _card(BuildContext context, List<Widget> rows) => Material(
        color: context.colors.surface,
        shape: HisaabShapes.squircle(HisaabRadii.card),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              if (i > 0) Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline),
              rows[i],
            ],
          ],
        ),
      );

  static void _offerUndo(BuildContext context, CategoriesState state) {
    final Category? hidden = state is CategoriesReady ? state.undo.toNullable() : null;
    if (hidden == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final CategoriesBloc bloc = context.read<CategoriesBloc>();
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: strings.categoryHidden(hidden.labelIn(strings)),
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(CategoryHideUndone(hidden.id))),
      ),
    );
  }
}
