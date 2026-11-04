import 'package:flutter/material.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/app_icons.dart';
import 'bill_icon_well.dart';

/// The [glyph] in its well and the [name], the head of the slip.
class BillHead extends StatelessWidget {
  const BillHead({super.key, required this.name, required this.glyph});

  final String name;
  final AppIconData glyph;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          BillIconWell(glyph: glyph),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleLarge)),
        ],
      );
}
