import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/afford_answer.dart';
import '../../afford_copy.dart';
import '../../bloc/afford_bloc.dart';
import '../../bloc/afford_event.dart';
import '../../bloc/afford_state.dart';
import '../story_outlined_button.dart';
import 'afford_day_bar.dart';
import 'afford_other_ways.dart';
import 'afford_rise_in.dart';
import 'afford_verdict_block.dart';

/// The answer: the verdict and its sentences, the day-amount bars with the breathing-space line,
/// *Other ways*, and one pinned action: the marigold *Start saving* for *Not yet* with something
/// spare, a quiet *Okay* otherwise (SPEC FR-SP-9 AC-4 to AC-6). The answer rises in as it
/// appears (UI_DESIGN 5.4a); the action stays pinned.
class AffordAnswerView extends StatelessWidget {
  const AffordAnswerView({super.key, required this.state});

  final AffordAnswered state;

  // why: the bars stretch to a little past the biggest amount, so none fills its track.
  static const int _headroomPercent = 115;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final double bottom = HisaabSpacing.gutter + MediaQuery.paddingOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
            child: AffordRiseIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AffordVerdictBlock(state: state),
                  const SizedBox(height: HisaabSpacing.l),
                  ..._bars(context, strings),
                  AffordOtherWays(state: state),
                  if (state.saveFailed) Text(strings.couldntSave, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, bottom),
          child: _action(context, strings),
        ),
      ],
    );
  }

  List<Widget> _bars(BuildContext context, AppLocalizations strings) {
    final List<AffordBar> bars = AffordCopy.bars(state, strings);
    if (bars.isEmpty) {
      return const <Widget>[];
    }
    final Money floor = state.answer.floor;
    final Money biggest = bars.map((AffordBar bar) => bar.perDay).fold(floor, (Money most, Money each) => each > most ? each : most);
    final Money scale = Money(biggest.amountMinor * _headroomPercent ~/ 100);
    final Money usual = state.usual.getOrElse(() => Money.zero);
    return <Widget>[
      for (final AffordBar bar in bars) AffordDayBar(bar: bar, floor: floor, scale: scale),
      const SizedBox(height: HisaabSpacing.xs),
      Text(
        strings.affordBreathingSpace(context.money.format(usual)),
        semanticsLabel: strings.affordBreathingSpace(strings.spokenAmount(context.money.digits(usual))),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2),
      ),
      const SizedBox(height: HisaabSpacing.m),
    ];
  }

  Widget _action(BuildContext context, AppLocalizations strings) {
    if (state.answer.verdict == AffordVerdict.saveUp) {
      final AffordBloc bloc = context.read<AffordBloc>();
      return SignalKey(
        key: const ValueKey<String>('afford-start-saving'),
        label: strings.affordStartSaving(context.money.format(state.answer.spare)),
        onPressed: state.saving ? null : () => bloc.add(const AffordStartSavingPressed()),
      );
    }
    return StoryOutlinedButton(
      key: const ValueKey<String>('afford-okay'),
      label: strings.affordOkay,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
