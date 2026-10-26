import 'package:flutter/material.dart';

import '../design/hisaab_dimensions.dart';
import '../extensions/build_context_extensions.dart';
import '../../l10n/gen/app_localizations.dart';

/// Temporary body for screens whose milestone hasn't landed: the screen [title] and a note.
///
/// Delete once Home (M1) and Spends (M4) are built.
class ScreenInProgress extends StatelessWidget {
  const ScreenInProgress({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HisaabSpacing.s),
            Text(
              AppLocalizations.of(context).screenInProgress,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2),
            ),
          ],
        ),
      );
}
