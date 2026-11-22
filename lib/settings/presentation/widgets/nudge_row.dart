import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/focus_ring.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/nudge_row_bloc.dart';
import '../bloc/nudge_row_event.dart';
import '../bloc/nudge_row_state.dart';

/// Settings' *Reminders* group (SPEC FR-SE-7): a heading over the *Daily nudge* switch row with its title and hint, a switch at the end, and
/// under it the "Allow notifications" line after a refusal. [onChanged] runs after each answer is
/// written, so the route can re-arm the nudges.
///
/// Needs a [NudgeRowBloc] above it.
class NudgeRow extends StatelessWidget {
  const NudgeRow({super.key, required this.onChanged});

  final VoidCallback onChanged;

  /// The row's least height (AC-5).
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) => BlocConsumer<NudgeRowBloc, NudgeRowState>(
        listenWhen: (NudgeRowState before, NudgeRowState now) =>
            before is NudgeRowReady && now is NudgeRowReady && now.changes != before.changes,
        listener: (BuildContext context, NudgeRowState state) => onChanged(),
        builder: (BuildContext context, NudgeRowState state) => switch (state) {
          NudgeRowReady() => _card(context, state),
          NudgeRowLoading() => const SizedBox.shrink(),
        },
      );

  Widget _card(BuildContext context, NudgeRowReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.xl, bottom: HisaabSpacing.s),
          child: Semantics(header: true, child: Text(strings.settingsReminders, style: text.titleLarge)),
        ),
        Material(
          color: context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.card),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _row(context, state, strings, text),
              if (state.refused)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.m),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      strings.nudgeRefused,
                      key: const ValueKey<String>('nudge-refused'),
                      style: text.bodySmall?.copyWith(color: context.colors.ink2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, NudgeRowReady state, AppLocalizations strings, TextTheme text) {
    void flip() => context.read<NudgeRowBloc>().add(NudgeRowToggled(on: !state.on));
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: strings.settingsNudgeSwitchLabel,
      toggled: state.on,
      onTap: flip,
      // why: the row fills a clipping card, so the ring is drawn inside it, as SettingsRow does (D99).
      child: FocusRing(
        radius: HisaabRadii.card - FocusRing.outset,
        inset: const EdgeInsets.all(FocusRing.outset),
        child: InkWell(
          key: const ValueKey<String>('nudge-row'),
          onTap: flip,
          focusColor: context.colors.clear,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.m),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
                    child: const AppIcon(AppIcons.nudge),
                  ),
                  const SizedBox(width: HisaabSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(strings.settingsNudge, style: text.bodyLarge),
                        Text(strings.settingsNudgeHint, style: text.bodySmall?.copyWith(color: context.colors.ink2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: HisaabSpacing.s),
                  Switch(key: const ValueKey<String>('nudge-switch'), value: state.on, onChanged: (bool _) => flip()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
