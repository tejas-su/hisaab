import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/usual_habit.dart';
import '../bloc/usual_row_bloc.dart';
import '../bloc/usual_row_event.dart';
import '../bloc/usual_row_state.dart';
import '../usual_words.dart';

/// The *Your usual* row of a category's sheet in Settings (SPEC FR-SE-2 AC-6): "₹20, weekdays
/// around 10 am" with a *Forget* text button, and "Worked out on this phone from what you add."
/// under it.
///
/// Reads a [UsualRowBloc] from above and builds nothing unless it shows a habit, so a sheet
/// without one is unchanged. *Forget* shows "Forgotten" with *Undo* in the nearest
/// [HisaabSnackbarHost] above. [name] is the category's shown name, for the screen reader.
class YourUsualRow extends StatelessWidget {
  /// Builds the row for the category shown as [name].
  const YourUsualRow({super.key, required this.name});

  /// The category's name as the sheet shows it; *Forget* reads "Forget your usual [name]".
  final String name;

  static const double _minHeight = 56;

  @override
  Widget build(BuildContext context) => BlocConsumer<UsualRowBloc, UsualRowState>(
        listenWhen: (UsualRowState previous, UsualRowState current) => current is UsualRowForgotten,
        listener: (BuildContext context, UsualRowState state) => _offerUndo(context),
        builder: (BuildContext context, UsualRowState state) => switch (state) {
          UsualRowShown(:final UsualHabit habit) => _shown(context, habit),
          UsualRowEmpty() || UsualRowForgotten() => const SizedBox.shrink(),
        },
      );

  Widget _shown(BuildContext context, UsualHabit habit) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            key: const ValueKey<String>('your-usual-row'),
            color: context.colors.surface,
            shape: HisaabShapes.squircle(HisaabRadii.card),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.gutter, end: HisaabSpacing.m),
                child: Row(
                  children: <Widget>[
                    Expanded(child: _words(context, strings, habit)),
                    const SizedBox(width: HisaabSpacing.s),
                    _forget(context, strings),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, top: HisaabSpacing.s, end: HisaabSpacing.xs),
            child: Text(strings.usualHow, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
          ),
        ],
      ),
    );
  }

  Widget _words(BuildContext context, AppLocalizations strings, UsualHabit habit) {
    final TextTheme text = Theme.of(context).textTheme;
    final String locale = context.money.locale;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.usualRowTitle, style: text.bodyLarge),
            Text(
              UsualWords.detail(strings, habit, amount: context.money.format(habit.amount), locale: locale),
              semanticsLabel: UsualWords.detail(
                strings,
                habit,
                amount: strings.spokenAmount(context.money.digits(habit.amount)),
                locale: locale,
              ),
              style: text.bodySmall?.copyWith(color: context.colors.ink2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _forget(BuildContext context, AppLocalizations strings) {
    void forget() => context.read<UsualRowBloc>().add(const UsualRowForgetRequested());
    return Semantics(
        // why: its own node, or the words beside it merge into the button's label. The button's
        // own semantics are replaced, so the tap is handed over here.
        container: true,
        label: strings.usualForgetSpoken(name),
        button: true,
        onTap: forget,
        excludeSemantics: true,
        child: TextButton(
          key: const ValueKey<String>('usual-forget'),
          onPressed: forget,
          style: TextButton.styleFrom(
            foregroundColor: context.colors.ink,
            minimumSize: const Size(HisaabSizes.minTouchTarget, HisaabSizes.minTouchTarget),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.s),
          ),
          child: Text(
            strings.usualForget,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(decoration: TextDecoration.underline),
          ),
        ),
      );
  }

  static void _offerUndo(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final UsualRowBloc bloc = context.read<UsualRowBloc>();
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: strings.usualForgotten,
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(const UsualRowForgetUndone())),
      ),
    );
  }
}
