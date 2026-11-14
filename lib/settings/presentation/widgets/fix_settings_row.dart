import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/income_bloc.dart';
import '../bloc/income_state.dart';
import 'settings_row.dart';

/// The last row of Settings' *Money* group: *Fix my number*, "When the number on Home looks wrong."
/// (SPEC FR-SE-1, D169). Shown with its divider only once an income is set up, since *No income*
/// has no number to fix; [onOpen] opens the sheet over Settings.
class FixSettingsRow extends StatelessWidget {
  const FixSettingsRow({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => BlocBuilder<IncomeBloc, IncomeState>(
        builder: (BuildContext context, IncomeState state) {
          if (state is! IncomeReady || state.income.rule.isNone()) {
            return const SizedBox.shrink();
          }
          final AppLocalizations strings = AppLocalizations.of(context);
          return Column(
            children: <Widget>[
              Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline),
              SettingsRow(
                key: const ValueKey<String>('open-fix'),
                icon: AppIcons.fixMyNumber,
                label: strings.fixMyNumber,
                detail: strings.fixSettingsDetail,
                onTap: onOpen,
              ),
            ],
          );
        },
      );
}
