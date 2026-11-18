import 'package:material_ui/material_ui.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'bill_sheet.dart';

/// "Remind you about this each day?", asked once after the first missed-log tap, once the Add tray
/// has closed (SPEC BR-22.8, FR-SE-7 AC-4): *Remind me* or *Not now*. Open it with [show].
class NudgeAskSheet extends StatelessWidget {
  const NudgeAskSheet({super.key, required this.onAnswer});

  /// Called with true for *Remind me*, false for *Not now*.
  final ValueChanged<bool> onAnswer;

  /// Opens [NudgeRefusedSheet] over [context], after Android refused the permission (E122).
  /// Completes once it has closed.
  static Future<void> showRefused(BuildContext context) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(context, builder: (BuildContext _) => const NudgeRefusedSheet());
    await Navigator.of(context).push(route);
    await route.completed;
  }

  /// Opens the sheet over [context]. Completes after the exit animation with the answer, or
  /// [None] when it was closed with Back, so it can be asked again later.
  static Future<Option<bool>> show(BuildContext context) async {
    Option<bool> answer = const Option<bool>.none();
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext sheet) => NudgeAskSheet(
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
          Semantics(header: true, child: Text(strings.nudgeAskTitle, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: HisaabSpacing.l),
          SignalKey(key: const ValueKey<String>('nudge-yes'), label: strings.nudgeAskYes, onPressed: () => onAnswer(true)),
          const SizedBox(height: HisaabSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: HisaabChip(
              key: const ValueKey<String>('nudge-no'),
              label: strings.nudgeAskNo,
              onSurface: true,
              onPressed: () => onAnswer(false),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Allow notifications in your phone's settings to turn this on.", shown once after *Remind me*
/// when Android refused the permission (E122), so the refusal isn't silent. *Done* closes it.
class NudgeRefusedSheet extends StatelessWidget {
  const NudgeRefusedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(liveRegion: true, child: Text(strings.nudgeRefused, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: HisaabSpacing.l),
          SignalKey(key: const ValueKey<String>('nudge-refused-done'), label: strings.done, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
