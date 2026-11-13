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
/// Delete action, since swiping is gesture-only. A *Used* entry (BR-19) reads the saving's name over
/// "Used from savings", has no tap, and with [showUsedDetail] adds "Paid from what you set aside."
/// in the same screen-reader node.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
    this.billName,
    this.showUsedDetail = false,
  });

  final Entry entry;
  final Category? category;

  /// The name of the bill that posted [entry], when known; it says which bill a row is.
  final String? billName;

  /// Whether a *Used* row adds its extra line, as in Every entry (FR-SP-6).
  final bool showUsedDetail;
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
          child: InkWell(onTap: _isSaved || _isCardPaid || _isUsed ? null : onEdit, focusColor: context.colors.clear, child: _content(context, strings)),
        ),
      ),
    );
  }

  bool get _isSaved => entry.kind == EntryKind.saved;

  bool get _isCardPaid => entry.kind == EntryKind.cardPaid;

  bool get _isUsed => entry.kind == EntryKind.used;

  AppIconData _glyph(Category? kind) => switch (entry.kind) {
        EntryKind.saved || EntryKind.used => AppIcons.saving,
        EntryKind.cardPaid => BillIcon.card.glyph,
        EntryKind.spent || EntryKind.got => AppIcons.forKey(kind?.iconKey ?? ''),
      };

  // why: a bill the app posted would otherwise look like typed spending that the Today total leaves out (D119).
  // Its name says that and which bill; "Bill" stands in when the rule is gone.
  String? _billTag(AppLocalizations strings) =>
      entry.recurringId != null && entry.kind == EntryKind.spent ? billName ?? strings.entryFixedBill : null;

  // why: a Used row has no kind sign or colour, so it is read as one sentence naming what it is (D187).
  Widget _content(BuildContext context, AppLocalizations strings) {
    final Widget row = _row(context, strings);
    if (!_isUsed) {
      return row;
    }
    final String spoken = strings.entryUsedSpoken(entry.note ?? strings.savingName('other'), strings.spokenAmount(context.money.digits(entry.amount)));
    return Semantics(
      label: showUsedDetail ? strings.spokenPair(spoken, strings.entryUsedDetail) : spoken,
      excludeSemantics: true,
      child: row,
    );
  }

  Widget _row(BuildContext context, AppLocalizations strings) {
    final TextTheme text = Theme.of(context).textTheme;
    // why: a saving is named by its rule (the note), or "Put in extra"; its line says *Saved* (D120).
    // why: a card bill is named by its card (the note); its line says it isn't counted (D123).
    final String title = switch (entry.kind) {
      EntryKind.saved => entry.note ?? strings.entryPutInExtra,
      EntryKind.used => entry.note ?? strings.savingName('other'),
      EntryKind.cardPaid => entry.note ?? strings.billName('creditCard'),
      EntryKind.spent || EntryKind.got => category?.labelIn(strings) ?? strings.categoryName('other'),
    };
    final String? note = switch (entry.kind) {
      EntryKind.saved => strings.entrySaved,
      EntryKind.used => strings.entryUsed,
      EntryKind.cardPaid => strings.entryCardPaid,
      EntryKind.spent || EntryKind.got => entry.note ?? _billTag(strings),
    };
    final String amount = context.money.format(entry.amount);
    final Category? kind = category;
    final bool detailed = _isUsed && showUsedDetail;
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
                if (detailed) Text(strings.entryUsedDetail, style: text.bodySmall?.copyWith(fontSize: 14)),
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
