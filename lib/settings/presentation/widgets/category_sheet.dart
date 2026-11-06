import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/widgets/category_icon_grid.dart';
import '../bloc/categories_bloc.dart';
import '../bloc/categories_event.dart';
import '../bloc/categories_state.dart';
import 'category_name_question.dart';
import 'category_sheet_summary.dart';
import 'category_sheet_title.dart';

enum _Mode { summary, name, icon }

/// One category's sheet (FR-SE-2 AC-2 to AC-5, D138): the summary, then the name or icon
/// question in place. With no id it is *Add a category*, opening on the name question.
///
/// Reads [CategoriesBloc] from above, so a saved change shows at once.
class CategorySheet extends StatefulWidget {
  const CategorySheet({super.key, this.id});

  /// The category shown; null to add a new one of the user's own.
  final int? id;

  /// Opens the sheet over [context] for category [id], or to add one when [id] is null.
  static Future<void> show(BuildContext context, CategoriesBloc bloc, {int? id}) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: context.colors.background,
        builder: (BuildContext _) => BlocProvider<CategoriesBloc>.value(value: bloc, child: CategorySheet(id: id)),
      );

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  late _Mode _mode = widget.id == null ? _Mode.name : _Mode.summary;
  late final TextEditingController _name = TextEditingController();
  String? _draftIcon;
  bool _waiting = false;
  String? _flashed;

  bool get _adding => widget.id == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _send(CategoriesEvent event) {
    setState(() => _waiting = true);
    context.read<CategoriesBloc>().add(event);
  }

  // why: the sheet reacts only to the outcome of its own request, not to other changes on the page.
  void _onOutcome(BuildContext context, CategoriesState state) {
    if (!_waiting || state is! CategoriesReady) {
      return;
    }
    if (state.problem.isNone() && _adding) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _waiting = false;
      if (state.problem.isNone()) {
        _flashed = _mode == _Mode.icon ? 'icon' : 'name';
        _mode = _Mode.summary;
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CategoriesBloc, CategoriesState>(
        listener: _onOutcome,
        builder: (BuildContext context, CategoriesState state) {
          final List<Category> all = state is CategoriesReady ? state.categories : const <Category>[];
          final Category? category = all.where((Category c) => c.id == widget.id).firstOrNull;
          if (!_adding && category == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.xl),
              child: _body(context, state, all, category),
            ),
          );
        },
      );

  Widget _body(BuildContext context, CategoriesState state, List<Category> all, Category? category) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Map<int, String> labels = <int, String>{for (final Category c in all) c.id: c.labelIn(strings)};
    return switch (_mode) {
      _Mode.summary => CategorySheetSummary(
          category: category!,
          flashed: _flashed,
          onRename: () {
            _name.text = labels[category.id] ?? '';
            setState(() => _mode = _Mode.name);
          },
          onChangeIcon: () => setState(() => _mode = _Mode.icon),
        ),
      _Mode.name => CategoryNameQuestion(
          controller: _name,
          categories: all,
          labels: labels,
          category: category,
          draftIcon: _draftIcon,
          waiting: _waiting,
          problem: state is CategoriesReady ? state.problem.toNullable() : null,
          onChanged: () => setState(() {}),
          onSave: _send,
          onOpenIcons: () => setState(() => _mode = _Mode.icon),
          onBack: _adding ? null : () => setState(() => _mode = _Mode.summary),
        ),
      _Mode.icon => _icons(strings, category),
    };
  }

  Widget _icons(AppLocalizations strings, Category? category) {
    final String name = category == null ? _name.text.trim() : category.labelIn(strings);
    final String fromName = CategoryIcon.forName(name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CategorySheetTitle(
          question: strings.pickIconFor(name.isEmpty ? strings.newCategory : name),
          onBack: () => setState(() => _mode = _adding ? _Mode.name : _Mode.summary),
        ),
        CategoryIconGrid(
          picked: category?.iconKey ?? _draftIcon ?? fromName,
          onPicked: (String key) => category == null
              ? setState(() {
                  _draftIcon = key == fromName ? null : key;
                  _mode = _Mode.name;
                })
              : _send(CategoryIconChangeRequested(id: category.id, iconKey: key)),
        ),
      ],
    );
  }
}
