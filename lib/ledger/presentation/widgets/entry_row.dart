import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/focus_ring.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_kind.dart';
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
  });

  final Entry entry;
  final Category? category;
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
          child: InkWell(onTap: onEdit, focusColor: context.colors.clear, child: _content(context, strings)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations strings) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? note = entry.note;
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
            child: AppIcon(AppIcons.forKey(kind?.iconKey ?? '')),
          ),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(kind?.labelIn(strings) ?? strings.categoryName('other'), style: text.bodyLarge),
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
