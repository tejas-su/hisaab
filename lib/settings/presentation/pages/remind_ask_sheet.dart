import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'bill_sheet.dart';

/// "Remind you on the day it's due?", asked once after the first changing or card bill is saved
/// (spec §5, D126): *Remind me* or *Not now*. Open it with [show].
class RemindAskSheet extends StatelessWidget {
  const RemindAskSheet({super.key, required this.onAnswer});

  /// Called with true for *Remind me*, false for *Not now*.
  final ValueChanged<bool> onAnswer;

  /// Opens the sheet over [context]. Completes after the exit animation with the answer, or
  /// [None] when it was closed with Back, so it can be asked again later.
  static Future<Option<bool>> show(BuildContext context) async {
    Option<bool> answer = const Option<bool>.none();
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext sheet) => RemindAskSheet(
        onAnswer: (bool remind) {
          answer = Option<bool>.of(remind);
          Navigator.of(sheet).pop();
        },
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    return answer;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(header: true, child: Text(strings.remindAskTitle, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: HisaabSpacing.l),
          SignalKey(key: const ValueKey<String>('remind-yes'), label: strings.remindAskYes, onPressed: () => onAnswer(true)),
          const SizedBox(height: HisaabSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: HisaabChip(
              key: const ValueKey<String>('remind-no'),
              label: strings.remindAskNo,
              onSurface: true,
              onPressed: () => onAnswer(false),
            ),
          ),
        ],
      ),
    );
  }
}
