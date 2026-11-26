import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../afford_copy.dart';
import '../../bloc/afford_state.dart';

/// The verdict and its one or two sentences, read by TalkBack first as one heading with the
/// amounts spoken (SPEC FR-SP-9 AC-4, AC-9).
class AffordVerdictBlock extends StatelessWidget {
  const AffordVerdictBlock({super.key, required this.state});

  final AffordAnswered state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String verdict = AffordCopy.verdict(state.answer.verdict, strings);
    final List<String> shown = AffordCopy.sentences(state, strings, AffordCopy.words(context.money, strings, spoken: false));
    return Semantics(
      key: const ValueKey<String>('afford-verdict'),
      container: true,
      header: true,
      label: AffordCopy.spokenAnswer(state, strings, context.money),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(verdict, style: text.displayMedium),
          for (final String sentence in shown) ...<Widget>[
            const SizedBox(height: HisaabSpacing.s),
            Text(sentence, style: text.bodyLarge),
          ],
        ],
      ),
    );
  }
}
