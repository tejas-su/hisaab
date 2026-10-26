import 'package:flutter/material.dart';

import '../money/money.dart';
import 'amount_text.dart';
import 'shake.dart';

/// The big amount being typed, which shakes when a key is refused.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.amount, required this.rejections});

  final Money amount;
  final int rejections;

  @override
  Widget build(BuildContext context) => Shake(
        trigger: rejections,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: AmountText(amount, roll: false, style: Theme.of(context).textTheme.displayMedium),
        ),
      );
}
