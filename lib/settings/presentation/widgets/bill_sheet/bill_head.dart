import 'package:flutter/material.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../ledger/ledger.dart';
import 'bill_icon_well.dart';

/// The bill's icon well and its [name], the head of the slip.
class BillHead extends StatelessWidget {
  const BillHead({super.key, required this.name, required this.icon});

  final String name;
  final BillIcon icon;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          BillIconWell(icon: icon),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleLarge)),
        ],
      );
}
