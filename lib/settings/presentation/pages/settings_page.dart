import 'package:flutter/material.dart';
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
    this.yourHisaab,
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

  /// The *Your hisaab* group under Look (FR-SE-4, D139), built by the route with its bloc; none
  /// leaves the group out.
  final Widget? yourHisaab;

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
          child: ListView(
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
              child: Semantics(header: true, child: Text(strings.settingsLook, style: text.titleLarge)),
            ),
            LookGroup(themeBloc: themeBloc),
            if (data != null) ...<Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
                child: Semantics(header: true, child: Text(strings.settingsYourHisaab, style: text.titleLarge)),
              ),
              data,
            ],
          ],
        ),
        ),
      ),
    );
  }
}
