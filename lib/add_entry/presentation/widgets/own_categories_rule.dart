import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The quiet "Your own" label and hairline over the user's own tiles on row 3 (D138).
///
/// Hidden from TalkBack: each tile already says its name.
class OwnCategoriesRule extends StatelessWidget {
  const OwnCategoriesRule({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.xs, bottom: HisaabSpacing.s),
          child: Row(
            children: <Widget>[
              Text(AppLocalizations.of(context).ownCategoriesRule, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: HisaabSpacing.s),
              Expanded(child: Divider(height: 1, thickness: 1, color: context.colors.hairline)),
            ],
          ),
        ),
      );
}
