import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The Ask AI title row with Back, whose 40dp well sits flush with the content edge (D57).
class AskAiHeader extends StatelessWidget {
  const AskAiHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const HisaabBackButton(key: ValueKey<String>('ask-ai-back')),
      const SizedBox(width: HisaabSpacing.s),
      Expanded(
        child: Semantics(
          container: true,
          header: true,
          child: Text(AppLocalizations.of(context).askAiTitle, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    ],
  );
}
