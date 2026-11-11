import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/focus_ring.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/bill_icon.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_kind.dart';
import '../bill_icon_extensions.dart';
import '../category_extensions.dart';

/// One entry in a list (Home's Today, Every entry): icon well, category, note and amount (SPEC FR-HO-4, FR-SP-6).
///
/// Tap edits it; swiping left deletes it at once (Undo comes from the page). TalkBack gets a
/// Delete action, since swiping is gesture-only.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
    this.billName,
  });

  final Entry entry;
  final Category? category;

  /// The name of the bill that posted [entry], when known; it says which bill a row is.
  final String? billName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// The swipe crossed the delete threshold (for the haptic).
  final VoidCallback onThresholdReached;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String delete = strings.delete;
    return Dismissible(
      key: ValueKey<int>(entry.id),
      direction: DismissDirection.endToStart,
      onUpdate: (DismissUpdateDetails details) {
        if (details.reached && !details.previousReached) {
          onThresholdReached();
        }
      },
      onDismissed: (DismissDirection _) => onDelete(),
      background: Container(
        color: context.colors.sunk,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: HisaabSpacing.gutter),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppIcon(AppIcons.delete),
            const SizedBox(width: HisaabSpacing.s),
            Text(delete, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
      child: Semantics(
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{CustomSemanticsAction(label: delete): onDelete},
        child: FocusRing(
          // why: rows fill a clipping card, so the ring is drawn inside the row; its outer corner
          // matches the card's (D99).
          radius: HisaabRadii.card - FocusRing.outset,
          inset: const EdgeInsets.all(FocusRing.outset),
          // why: the Add tray knows only Spent and Got; editing a saving or a card bill there would
          // turn it into spending (D120, D123). Either is swiped away instead.
          child: InkWell(onTap: _isSaved || _isCardPaid ? null : onEdit, focusColor: context.colors.clear, child: _content(context, strings)),
        ),
      ),
    );
  }

  bool get _isSaved => entry.kind == EntryKind.saved;

  bool get _isCardPaid => entry.kind == EntryKind.cardPaid;

  AppIconData _glyph(Category? kind) => switch (entry.kind) {
        EntryKind.saved => AppIcons.saving,
        EntryKind.cardPaid => BillIcon.card.glyph,
        EntryKind.spent || EntryKind.got => AppIcons.forKey(kind?.iconKey ?? ''),
      };

  // why: a bill the app posted would otherwise look like typed spending that the Today total leaves out (D119).
  // Its name says that and which bill; "Bill" stands in when the rule is gone.
  String? _billTag(AppLocalizations strings) =>
      entry.recurringId != null && entry.kind == EntryKind.spent ? billName ?? strings.entryFixedBill : null;

  Widget _content(BuildContext context, AppLocalizations strings) {
    final TextTheme text = Theme.of(context).textTheme;
    // why: a saving is named by its rule (the note), or "Put in extra"; its line says *Saved* (D120).
    // why: a card bill is named by its card (the note); its line says it isn't counted (D123).
    final String title = switch (entry.kind) {
      EntryKind.saved => entry.note ?? strings.entryPutInExtra,
      EntryKind.cardPaid => entry.note ?? strings.billName('creditCard'),
      EntryKind.spent || EntryKind.got => category?.labelIn(strings) ?? strings.categoryName('other'),
    };
    final String? note = switch (entry.kind) {
      EntryKind.saved => strings.entrySaved,
      EntryKind.cardPaid => strings.entryCardPaid,
      EntryKind.spent || EntryKind.got => entry.note ?? _billTag(strings),
    };
    final String amount = context.money.format(entry.amount);
    final Category? kind = category;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: 9),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
            child: AppIcon(_glyph(kind)),
          ),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.bodyLarge),
                if (note != null) Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Text(
            entry.kind == EntryKind.got ? strings.gotAmount(amount) : amount,
            style: HisaabType.rowAmount(context.colors.ink),
          ),
        ],
      ),
    );
  }
}
