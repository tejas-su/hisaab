import 'package:material_ui/material_ui.dart';

import '../money/money.dart';
import 'amount_cap_ring.dart';
import 'amount_text.dart';
import 'shake.dart';

/// The big amount being typed, which shakes, and holds a ring and says why, when a key is refused.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.amount, required this.rejections});

  final Money amount;
  final int rejections;

  @override
  Widget build(BuildContext context) => AmountCapRing(
        rejections: rejections,
        amount: amount,
        child: Shake(
          trigger: rejections,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(amount, roll: false, style: Theme.of(context).textTheme.displayMedium),
          ),
        ),
      );
}
