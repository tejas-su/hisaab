import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../afford_copy.dart';
import '../../bloc/afford_bloc.dart';
import '../../bloc/afford_event.dart';
import '../../bloc/afford_state.dart';
import 'afford_way_row.dart';

/// *Other ways* under the answer: a toggle with a chevron and, open, the three ways to pay with
/// their numbers, the suggested one marked (SPEC FR-SP-9 AC-5).
class AffordOtherWays extends StatelessWidget {
  const AffordOtherWays({super.key, required this.state});

  final AffordAnswered state;

  // why: the wallet, card and piggy bank of mockup 52, in the order of the rows.
  static const List<AppIconData> _glyphs = <AppIconData>[
    AppIcons.wallet,
    AppIcons.card,
    AppIcons.saving,
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<AffordWay> shown = AffordCopy.ways(state, strings, AffordCopy.words(context.money, strings, spoken: false));
    final List<AffordWay> spoken = AffordCopy.ways(state, strings, AffordCopy.words(context.money, strings, spoken: true));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _toggle(context, strings),
        if (state.waysOpen)
          for (final (int index, AffordWay way) in shown.indexed)
            AffordWayRow(key: ValueKey<String>('afford-way-$index'), way: way, spokenLine: spoken[index].line, glyph: _glyphs[index]),
      ],
    );
  }

  Widget _toggle(BuildContext context, AppLocalizations strings) => Semantics(
        expanded: state.waysOpen,
        child: Pressable(
          key: const ValueKey<String>('afford-other-ways'),
          semanticLabel: strings.affordOtherWays,
          onPressed: () => context.read<AffordBloc>().add(const AffordWaysToggled()),
          focusRadius: HisaabRadii.chip,
          builder: (BuildContext context, bool _) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
            child: Row(
              children: <Widget>[
                Text(strings.affordOtherWays, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: HisaabSpacing.xs),
                RotatedBox(quarterTurns: state.waysOpen ? 2 : 0, child: const AppIcon(AppIcons.dropdown)),
              ],
            ),
          ),
        ),
      );
}
