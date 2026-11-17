import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card_header.dart';
import 'entry_card_note_field.dart';
import 'entry_card_part.dart';

/// An entry opened in place of its row (SPEC FR-AD-8, UI_DESIGN §5.3a): the amount, category and
/// day as buttons, the open part when [partsInline], the note, Delete and *Done*.
///
/// [state] is the card's open or saving state; a tap outside it (outside [tapGroup] too) closes it.
class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.state, this.partsInline = true});

  final EntryCardState state;
  final bool partsInline;

  /// The tap-region group the card shares with a board, so a tap on the board isn't "outside".
  static const Object tapGroup = EntryCard;

  static const double _edge = 2;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final EntryCardBloc bloc = context.read<EntryCardBloc>();
    final EntryCardState current = state;
    final EntryCardForm form = switch (current) {
      EntryCardOpen(:final EntryCardForm form) || EntryCardSaving(:final EntryCardForm form) => form,
      // why: a slot builds the card only for an open or saving state.
      EntryCardClosed() => throw StateError('EntryCard needs an open card'),
    };
    final bool busy = current is EntryCardSaving;
    final Option<CardPart> part = form.part;
    return TapRegion(
      groupId: tapGroup,
      onTapOutside: (PointerDownEvent _) => bloc.add(const EntryCardDone()),
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.s, vertical: HisaabSpacing.xs),
        padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.m, HisaabSpacing.m, HisaabSpacing.m, HisaabSpacing.m),
        decoration: ShapeDecoration(
          color: context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.tile, side: BorderSide(color: context.colors.ink, width: _edge)),
        ),
        child: IgnorePointer(
          ignoring: busy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              EntryCardHeader(form: form, rejections: current is EntryCardOpen ? current.rejections : 0),
              if (partsInline && part.isSome()) EntryCardPart(form: form),
              const SizedBox(height: HisaabSpacing.s),
              EntryCardNoteField(key: ValueKey<int>(form.original.id), note: form.note, onChanged: (String note) => bloc.add(EntryCardNoteChanged(note))),
              const SizedBox(height: HisaabSpacing.s),
              Text(
                current is EntryCardOpen && current.failed ? strings.couldntSave : (form.changes.isEmpty ? strings.entryCardHint : ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2),
              ),
              const SizedBox(height: HisaabSpacing.s),
              _foot(context, strings, bloc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foot(BuildContext context, AppLocalizations strings, EntryCardBloc bloc) => Row(
        children: <Widget>[
          Pressable(
            key: const ValueKey<String>('entry-card-delete'),
            semanticLabel: strings.delete,
            onPressed: () => bloc.add(const EntryCardDeleteRequested()),
            focusRadius: HisaabRadii.key,
            builder: (BuildContext context, bool pressed) => Container(
              width: HisaabSizes.minTouchTarget + HisaabSpacing.xs,
              height: HisaabSizes.minTouchTarget,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: pressed ? context.colors.hairline : context.colors.surface,
                shape: HisaabShapes.squircle(HisaabRadii.key, side: BorderSide(color: context.colors.hairline, width: 1.5)),
              ),
              child: const AppIcon(AppIcons.delete),
            ),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(
            child: Pressable(
              key: const ValueKey<String>('entry-card-done'),
              semanticLabel: strings.done,
              onPressed: () => bloc.add(const EntryCardDone()),
              focusRadius: HisaabRadii.key,
              builder: (BuildContext context, bool pressed) => Container(
                height: HisaabSizes.minTouchTarget,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.ink, shape: HisaabShapes.squircle(HisaabRadii.key)),
                child: Text(strings.done, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.colors.background)),
              ),
            ),
          ),
        ],
      );
}
