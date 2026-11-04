import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_icon_tile.dart';
import 'bill_question_frame.dart';
import 'bill_sheet_copy.dart';

/// The icon question: the 16 icons in a 4-column grid; a tap saves (SPEC FR-SE-1 AC-3, BR-9).
class BillIconQuestion extends StatelessWidget {
  const BillIconQuestion({super.key, required this.state});

  final BillSheetReady state;

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillIcon suggested = BillIcon.forName(state.rule.label);
    return BillQuestionFrame(
      question: strings.billIconQuestion(state.rule.label),
      name: state.rule.label,
      icon: state.rule.shownIcon,
      figure: AmountText(state.rule.amount, roll: false, style: Theme.of(context).textTheme.displaySmall),
      caption: suggested == BillIcon.bill ? strings.billIconNoMatch : strings.billIconFromName(context.iconName(suggested)),
      saveFailed: state.saveFailed,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int row = 0; row * _columns < BillIcon.values.length; row++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.s),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int column = 0; column < _columns; column++) ...<Widget>[
                      if (column > 0) const SizedBox(width: HisaabSpacing.s),
                      Expanded(child: _tile(context, BillIcon.values[row * _columns + column])),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, BillIcon icon) => BillIconTile(
        key: ValueKey<String>('bill-icon-${icon.value}'),
        icon: icon,
        picked: icon == state.rule.shownIcon,
        onPressed: () => context.read<BillSheetBloc>().add(BillSheetIconChosen(icon)),
      );
}
