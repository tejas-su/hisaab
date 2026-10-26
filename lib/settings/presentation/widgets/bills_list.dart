import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../ledger/ledger.dart';
import 'bill_row.dart';

/// The fixed bills on one card, divided by hairlines (SPEC FR-SE-1).
class BillsList extends StatelessWidget {
  const BillsList({
    super.key,
    required this.bills,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
  });

  final List<RecurringRule> bills;
  final ValueChanged<RecurringRule> onEdit;
  final ValueChanged<RecurringRule> onDelete;
  final VoidCallback onThresholdReached;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.surface,
        shape: HisaabShapes.squircle(HisaabRadii.card),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (int index, RecurringRule bill) in bills.indexed) ...<Widget>[
                if (index > 0) Divider(indent: 74, endIndent: HisaabSpacing.gutter, color: context.colors.hairline),
                BillRow(
                  key: ValueKey<int>(bill.id),
                  bill: bill,
                  onEdit: () => onEdit(bill),
                  onDelete: () => onDelete(bill),
                  onThresholdReached: onThresholdReached,
                ),
              ],
            ],
          ),
        ),
      );
}
