import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card.dart';
import 'entry_card_amount_part.dart';
import 'entry_card_category_part.dart';
import 'entry_card_day_part.dart';
import 'entry_card_naming_part.dart';

/// Every part of the open card at once, for the pane beside it in a wide window (SPEC FR-AD-8
/// AC-12): the days, the keypad, the grid (or naming) and a live line with today's share.
///
/// Shows nothing while no card is open. The part tapped in the card is ringed here.
class EntryBoard extends StatelessWidget {
  const EntryBoard({super.key, required this.bloc});

  final EntryCardBloc bloc;

  static const double _keypadWidth = 220;
  static const double _ring = 3;

  @override
  Widget build(BuildContext context) => BlocProvider<EntryCardBloc>.value(
        value: bloc,
        child: BlocBuilder<EntryCardBloc, EntryCardState>(
          builder: (BuildContext context, EntryCardState state) => switch (state) {
            EntryCardOpen(:final EntryCardForm form) || EntryCardSaving(:final EntryCardForm form) => TapRegion(
                groupId: EntryCard.tapGroup,
                child: IgnorePointer(ignoring: state is EntryCardSaving, child: _board(context, form)),
              ),
            EntryCardClosed() => const SizedBox.shrink(),
          },
        ),
      );

  Widget _board(BuildContext context, EntryCardForm form) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final bool naming = form.part == const Option<CardPart>.of(CardPart.naming);
    return ColoredBox(
      color: context.colors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(strings.entryBoardTitle, style: text.titleMedium),
            Semantics(liveRegion: true, child: Text(_preview(context, form), style: text.bodyMedium)),
            const SizedBox(height: HisaabSpacing.m),
            _ringed(context, form.part == const Option<CardPart>.of(CardPart.day), EntryCardDayPart(form: form)),
            const SizedBox(height: HisaabSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: _keypadWidth,
                  child: _labelled(context, strings.entryBoardAmount, form.part == const Option<CardPart>.of(CardPart.amount),
                      EntryCardAmountPart(form: form, withKeepKey: false)),
                ),
                const SizedBox(width: HisaabSpacing.l),
                Expanded(
                  child: _labelled(
                    context,
                    strings.entryBoardFor,
                    EntryCardCategoryPart.isOpen(form) || naming,
                    naming ? EntryCardNamingPart(form: form) : EntryCardCategoryPart(form: form),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _preview(BuildContext context, EntryCardForm form) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Option<Money> safe = form.safeToday;
    return form.preview.match(
      () => strings.entryBoardNoPreview,
      (Money next) => strings.entryBoardPreview(
        context.money.format(safe.getOrElse(() => next)),
        context.money.format(next),
      ),
    );
  }

  Widget _labelled(BuildContext context, String label, bool ringed, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.ink2)),
          const SizedBox(height: HisaabSpacing.xs),
          _ringed(context, ringed, child),
        ],
      );

  Widget _ringed(BuildContext context, bool ringed, Widget child) => AnimatedContainer(
        duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.resize,
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.xs),
        decoration: ShapeDecoration(
          shape: HisaabShapes.squircle(
            HisaabRadii.chip,
            side: ringed ? BorderSide(color: context.colors.ink, width: _ring) : BorderSide.none,
          ),
        ),
        child: child,
      );
}
