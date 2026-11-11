import 'package:material_ui/material_ui.dart';

import '../extensions/build_context_extensions.dart';
import '../../l10n/gen/app_localizations.dart';

/// The "hisaab•" wordmark: lowercase name and a marigold dot ringed in ink (DECISIONS D16).
///
/// The ink ring keeps the dot visible on the light background, where bare marigold fails contrast.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    final String name = AppLocalizations.of(context).appTitle;
    return Semantics(
      header: true,
      label: name,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 2, bottom: 7),
            child: Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: context.colors.signal,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.onSignal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
