import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/income_bloc.dart';
import '../bloc/income_state.dart';
import 'income_sheet/income_copy.dart';
import 'settings_row.dart';

/// Settings' *Money coming in* row (SPEC FR-SE-1, D137): the income under its label, opening the
/// income sheet through [onOpen]. Until the income loads it shows the label only and doesn't open.
class IncomeRow extends StatelessWidget {
  const IncomeRow({super.key, required this.onOpen});

  /// Opens the income sheet for the loaded income.
  final ValueChanged<Income> onOpen;

  @override
  Widget build(BuildContext context) => BlocBuilder<IncomeBloc, IncomeState>(
    builder: (BuildContext context, IncomeState state) {
      final Income? income = state is IncomeReady ? state.income : null;
      return SettingsRow(
        key: const ValueKey<String>('open-income'),
        icon: AppIcons.forKey(CategoryKeys.salary),
        label: AppLocalizations.of(context).moneyComingIn,
        detail: income == null ? null : context.incomeRowValue(income),
        onTap: income == null ? null : () => onOpen(income),
      );
    },
  );
}
