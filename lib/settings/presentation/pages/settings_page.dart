import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/income_bloc.dart';
import '../bloc/theme_bloc.dart';
import '../widgets/fix_settings_row.dart';
import '../widgets/income_row.dart';
import '../widgets/look_group.dart';
import '../widgets/settings_row.dart';

/// Settings (SPEC FR-SE), one level deep. Today it holds the Money group (Money coming in, which
/// [incomeBloc] shows and [onOpenIncome] opens; Bills, which [onOpenBills] opens; and Savings) and
/// the Look group, which [themeBloc] drives; the other groups arrive with their milestones.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.incomeBloc,
    required this.onOpenIncome,
    required this.onOpenBills,
    required this.onOpenSavings,
    required this.themeBloc,
    this.onOpenCategories,
    this.shortcuts,
    this.yourHisaab,
    this.onFixMyNumber,
    this.wrapContent,
  });

  /// The income shown on the *Money coming in* row (D137).
  final IncomeBloc incomeBloc;

  /// Opens the income sheet for the loaded income.
  final ValueChanged<Income> onOpenIncome;

  final VoidCallback onOpenBills;

  /// Opens the Savings list (D120).
  final VoidCallback onOpenSavings;

  /// The app-wide look (FR-SE-3), shown and changed by the Look group.
  final ThemeBloc themeBloc;

  /// Opens Settings › Categories (FR-SE-2, D138); none leaves the *Categories* group out.
  final VoidCallback? onOpenCategories;

  /// The *Shortcuts* group, heading included, between Look and *Your hisaab* (FR-SE-6, widget spec
  /// §15 #2), built by the route with its bloc; none leaves it out.
  final Widget? shortcuts;

  /// The *Your hisaab* group under Look (FR-SE-4, D139), built by the route with its bloc; none
  /// leaves the group out.
  final Widget? yourHisaab;

  /// Opens *Fix my number* over Settings from the last row of *Money* (FR-SE-1); none leaves the row
  /// out. The row also stays hidden until an income is set up.
  final VoidCallback? onFixMyNumber;

  /// Wraps the page's content inside its snackbar host, so a listener the route adds can show a
  /// snackbar here, such as the Undo of a fix made from this page (FR-FX-5 AC-5).
  final Widget Function(Widget content)? wrapContent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final Widget? data = yourHisaab;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: HisaabBackButton.leadingWidth,
        leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
        titleSpacing: HisaabSpacing.s,
        title: Text(strings.settings),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        // why: the Your hisaab group shows its messages here (FR-SE-4 AC-2, AC-3).
        child: HisaabSnackbarHost(
          child: _wrapped(ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.xl),
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, bottom: HisaabSpacing.s),
              child: Semantics(header: true, child: Text(strings.settingsMoney, style: text.titleLarge)),
            ),
            Material(
              color: context.colors.surface,
              shape: HisaabShapes.squircle(HisaabRadii.card),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  BlocProvider<IncomeBloc>.value(value: incomeBloc, child: IncomeRow(onOpen: onOpenIncome)),
                  Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline),
                  SettingsRow(
                    key: const ValueKey<String>('open-bills'),
                    icon: AppIcons.recurring,
                    label: strings.fixedBills,
                    onTap: onOpenBills,
                  ),
                  Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline),
                  SettingsRow(
                    key: const ValueKey<String>('open-savings'),
                    icon: AppIcons.saving,
                    label: strings.savings,
                    onTap: onOpenSavings,
                  ),
                  if (onFixMyNumber case final VoidCallback fix)
                    BlocProvider<IncomeBloc>.value(value: incomeBloc, child: FixSettingsRow(onOpen: fix)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
              child: Semantics(header: true, child: Text(strings.settingsLook, style: text.titleLarge)),
            ),
            LookGroup(themeBloc: themeBloc),
            if (onOpenCategories case final VoidCallback openCategories) ...<Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
                child: Semantics(header: true, child: Text(strings.settingsCategories, style: text.titleLarge)),
              ),
              Material(
                color: context.colors.surface,
                shape: HisaabShapes.squircle(HisaabRadii.card),
                clipBehavior: Clip.antiAlias,
                child: SettingsRow(
                  key: const ValueKey<String>('open-categories'),
                  icon: AppIcons.forKey('tag'),
                  label: strings.settingsCategories,
                  onTap: openCategories,
                ),
              ),
            ],
            ?shortcuts,
            if (data != null) ...<Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
                child: Semantics(header: true, child: Text(strings.settingsYourHisaab, style: text.titleLarge)),
              ),
              data,
            ],
          ],
        ))),
      ),
    );
  }

  Widget _wrapped(Widget content) => wrapContent?.call(content) ?? content;
}
