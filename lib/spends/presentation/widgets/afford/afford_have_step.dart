import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../core/widgets/pinned_keypad_body.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/afford_bloc.dart';
import '../../bloc/afford_event.dart';
import '../../bloc/afford_state.dart';
import 'afford_keypad_controls.dart';

/// Step 2, "Saved anything for it already?": *Nothing yet* or *Yes* with the keypad for what is
/// put away, then *See the answer* (SPEC FR-SP-9 AC-3).
class AffordHaveStepView extends StatelessWidget {
  const AffordHaveStepView({super.key, required this.draft});

  final AffordDraft draft;

  static const ValueKey<String> _seeAnswerKey = ValueKey<String>('afford-see-answer');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AffordBloc bloc = context.read<AffordBloc>();
    void seeAnswer() => bloc.add(const AffordAnswerRequested());
    if (!draft.saidYes) {
      return SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          HisaabSpacing.gutter,
          0,
          HisaabSpacing.gutter,
          HisaabSpacing.gutter + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _lead(context),
            const SizedBox(height: HisaabSpacing.l),
            SignalKey(key: _seeAnswerKey, label: strings.affordSeeAnswer, onPressed: seeAnswer),
          ],
        ),
      );
    }
    // why: the hint sits at the end of the lead, which stays beside the figure when it scrolls,
    // so a long wrapped hint at large text never pushes the keys off screen.
    return PinnedKeypadBody(
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _lead(context),
          Text(strings.affordHaveHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2)),
        ],
      ),
      figure: AmountDisplay(amount: draft.haveMoney, rejections: draft.rejections),
      controls: (BuildContext context, double keyHeight) => AffordKeypadControls(
        keyHeight: keyHeight,
        label: strings.affordSeeAnswer,
        actionKey: _seeAnswerKey,
        action: seeAnswer,
      ),
    );
  }

  Widget _lead(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AffordBloc bloc = context.read<AffordBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(header: true, child: Text(strings.affordHaveQuestion, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: HisaabSpacing.m),
        Wrap(
          spacing: HisaabSpacing.s,
          runSpacing: HisaabSpacing.s,
          children: <Widget>[
            HisaabChip(
              key: const ValueKey<String>('afford-nothing-yet'),
              label: strings.affordNothingYet,
              selected: !draft.saidYes,
              onPressed: () => bloc.add(const AffordHaveChosen(false)),
            ),
            HisaabChip(
              key: const ValueKey<String>('afford-yes'),
              label: strings.affordHaveYes,
              selected: draft.saidYes,
              onPressed: () => bloc.add(const AffordHaveChosen(true)),
            ),
          ],
        ),
        const SizedBox(height: HisaabSpacing.m),
      ],
    );
  }
}
