import '../../../core/design/hisaab_type.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../hero_copy.dart';

/// The forecast sentence under the blocks, with a check or alert glyph (SPEC BR-7).
class RangeLine extends StatelessWidget {
  const RangeLine({super.key, required this.words, required this.calm});

  final RangeWords words;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final TextStyle? base = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk);
    final String? detail = words.detail;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 1),
          child: AppIcon(calm ? AppIcons.onTrack : AppIcons.alert, size: 18, color: context.colors.displayInk),
        ),
        const SizedBox(width: HisaabSpacing.s),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: words.lead, style: HisaabType.emphasized(base)),
                if (detail != null) ...<InlineSpan>[
                  TextSpan(text: AppLocalizations.of(context).separator),
                  TextSpan(text: detail),
                ],
              ],
            ),
            style: base?.copyWith(color: context.colors.displayInk2),
          ),
        ),
      ],
    );
  }
}
