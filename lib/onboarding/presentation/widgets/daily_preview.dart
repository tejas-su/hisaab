import '../../../core/design/hisaab_type.dart';
import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/day_blocks/day_blocks.dart';
import '../../../core/widgets/day_blocks/day_blocks_data.dart';
import '../../../core/widgets/display_card.dart';
import '../../../l10n/gen/app_localizations.dart';

/// "That's about ₹1,500 a day" with a month of blocks under it: the moment the idea clicks
/// (SPEC FR-ON-2, UI_DESIGN §5.1). The ÷ 30 is for this preview only; the real share is BR-4.
class DailyPreview extends StatelessWidget {
  const DailyPreview({super.key, required this.monthly});

  final Money monthly;

  static const int previewDays = 30;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Money perDay = Money.fromMajor(monthly.floorMajor ~/ previewDays);
    final String sentence = strings.dailyPreview(context.money.format(perDay));
    final TextTheme text = Theme.of(context).textTheme;
    return DisplayCard(
      radius: HisaabRadii.tile,
      padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.l, 14, HisaabSpacing.l, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(sentence, style: HisaabType.emphasized(text.bodyLarge)?.copyWith(color: context.colors.displayInk)),
          const SizedBox(height: 10),
          DayBlocks(
            data: const DayBlocksData(count: previewDays, style: DayBlocksStyle.preview),
            semanticLabel: strings.dailyPreviewCaption,
            height: 28,
            assemble: true,
          ),
          const SizedBox(height: HisaabSpacing.s),
          Text(strings.dailyPreviewCaption, style: text.bodyMedium?.copyWith(color: context.colors.displayInk2)),
        ],
      ),
    );
  }
}
