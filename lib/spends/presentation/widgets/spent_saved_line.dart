import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';

/// One quiet line above *Where it went*: "Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200" for the
/// cycle shown, so saving and fixes are seen beside spending without ever counting as it (D120, SPEC
/// FR-SP-4a). Show it only when the cycle has saves or a fix.
///
/// Up to three parts in a fixed order, each only above ₹0. [spent] leaves out *Not logged* and *Saved*,
/// which are their own numbers; [notLogged] is the *Spent* side of fixes only; *Used* is not here. The
/// line wraps **between** parts, never inside one, and leaves the middle dot at the end of a line
/// (mockup 42 option B). When every part fits on one line it is one run of text, "Spent ₹27,570 ·
/// Saved ₹1,000"; only when they don't is it a [Wrap]. A screen reader hears one sentence, with the
/// dots hidden.
class SpentSavedLine extends StatelessWidget {
  const SpentSavedLine({super.key, required this.spent, required this.saved, this.notLogged = Money.zero});

  final Money spent;
  final Money saved;
  final Money notLogged;

  static const double _gap = HisaabSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<_Part> parts = <_Part>[
      (amount: spent, shown: strings.spendsPartSpent, heard: strings.spendsPartSpent),
      (amount: saved, shown: strings.spendsPartSaved, heard: strings.spendsPartSaved),
      (amount: notLogged, shown: strings.spendsPartNotLogged, heard: strings.spendsPartNotLoggedSpoken),
    ].where((_Part part) => !part.amount.isZero).toList();
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    final String spoken =
        parts.map((_Part part) => '${part.heard(strings.spokenAmount(context.money.digits(part.amount)))}.').join(' ');
    final List<String> shown = parts.map((_Part part) => part.shown(context.money.format(part.amount))).toList();
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) =>
            _fits(context, shown.join(_separator), style, box.maxWidth) ? Text(shown.join(_separator), style: style) : _wrapped(shown, style),
      ),
    );
  }

  static const String _separator = ' · ';

  // why: one run of text when it fits keeps the line plain; only when it can't does it wrap, and
  // then between parts, never inside one.
  static bool _fits(BuildContext context, String text, TextStyle? style, double width) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: width);
    final bool fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  Widget _wrapped(List<String> shown, TextStyle? style) => Wrap(
        spacing: _gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final (int index, String part) in shown.indexed) ...<Widget>[
            if (index > 0) Text('·', style: style),
            Text(part, style: style),
          ],
        ],
      );
}

/// One part of the line: its amount, how it is written and how it is spoken.
typedef _Part = ({Money amount, String Function(String amount) shown, String Function(String amount) heard});
