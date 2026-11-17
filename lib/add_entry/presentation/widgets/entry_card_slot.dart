import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_motion.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card.dart';
import 'entry_card_scope.dart';

/// One place in a list of entries: [row] for entry [entryId], or its card while that entry is open
/// (SPEC FR-AD-8 AC-1). The row grows into the card where it stands; the list never reorders.
///
/// Without an [EntryCardScope] above it, it is just [row].
class EntryCardSlot extends StatelessWidget {
  const EntryCardSlot({super.key, required this.entryId, required this.row});

  final int entryId;
  final Widget row;

  /// How far other rows fade while a card is open.
  static const double _dimmed = 0.35;

  @override
  Widget build(BuildContext context) {
    final EntryCardScopeData? scope = EntryCardScope.maybeOf(context);
    if (scope == null) {
      return row;
    }
    final bool reduce = HisaabMotion.reduceMotion(context);
    return BlocBuilder<EntryCardBloc, EntryCardState>(
      bloc: scope.bloc,
      builder: (BuildContext context, EntryCardState state) {
        final int? openId = _openId(state);
        final Widget shown = openId == entryId ? EntryCard(key: ValueKey<String>('entry-card-$entryId'), state: state, partsInline: scope.partsInline) : row;
        final Widget swap = AnimatedSwitcher(
          duration: HisaabMotion.reducedCrossfade,
          child: KeyedSubtree(key: ValueKey<bool>(openId == entryId), child: shown),
        );
        return AnimatedOpacity(
          opacity: openId == null || openId == entryId ? 1 : _dimmed,
          duration: reduce ? HisaabMotion.reducedCrossfade : HisaabMotion.resize,
          // why: reduced motion only crossfades; a zero-length AnimatedSize re-dirties its own layout.
          child: reduce
              ? swap
              : AnimatedSize(
                  duration: HisaabMotion.resize,
                  curve: HisaabMotion.easeOut,
                  alignment: AlignmentDirectional.topCenter,
                  child: swap,
                ),
        );
      },
    );
  }

  static int? _openId(EntryCardState state) => switch (state) {
        EntryCardOpen(:final EntryCardForm form) || EntryCardSaving(:final EntryCardForm form) => form.original.id,
        EntryCardClosed() => null,
      };
}
