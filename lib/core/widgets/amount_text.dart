import 'package:material_ui/material_ui.dart';

import '../design/hisaab_motion.dart';
import '../extensions/build_context_extensions.dart';
import '../money/money.dart';
import '../../l10n/gen/app_localizations.dart';

/// An amount in whole rupees that rolls to its new value (UI_DESIGN §6) and reads as words.
///
/// Screen readers hear "1,430 rupees", not "₹1,430". With [roll] off (live typing) it changes at
/// once; with reduced motion it crossfades instead of rolling.
class AmountText extends StatelessWidget {
  const AmountText(this.amount, {super.key, this.style, this.roll = true, this.textAlign});

  final Money amount;
  final TextStyle? style;
  final bool roll;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final String spoken = AppLocalizations.of(context).spokenAmount(context.money.digits(amount));
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: _animated(context),
    );
  }

  Widget _animated(BuildContext context) {
    if (!roll) {
      return _text(context, amount.floorMajor);
    }
    if (HisaabMotion.reduceMotion(context)) {
      return AnimatedSwitcher(
        duration: HisaabMotion.reducedCrossfade,
        child: KeyedSubtree(key: ValueKey<int>(amount.floorMajor), child: _text(context, amount.floorMajor)),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: amount.floorMajor.toDouble()),
      duration: HisaabMotion.numberRoll,
      curve: HisaabMotion.easeOut,
      builder: (BuildContext context, double value, Widget? _) => _text(context, value.round()),
    );
  }

  Widget _text(BuildContext context, int rupees) => Text(
        context.money.format(Money.fromMajor(rupees, currency: amount.currency)),
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        softWrap: false,
      );
}
