import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Takes the *New* tile's place when 4 of the user's own are shown, saying how to make room
/// (FR-AD-9 AC-1); never a dead button.
class OwnCategoriesFullLine extends StatelessWidget {
  const OwnCategoriesFullLine({super.key});

  @override
  Widget build(BuildContext context) => Row(
        key: const ValueKey<String>('own-categories-full'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(AppIcons.info, size: 18, color: context.colors.ink2),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(
            child: Text(
              AppLocalizations.of(context).ownCategoriesFull,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
            ),
          ),
        ],
      );
}
